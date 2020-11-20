%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
classdef SqlBase < handle
    properties
        conn = [];
        connh = [];
    end
    
    methods(Access=protected)
        function this = SqlBase()
        end

        function conn = open(this,varargin)
            cfg = struct('cfg_file',[], ...
                         'server_name',[], ...
                         'name',[], ...
                         'user',[], ...
                         'pass',[]);
            
            cfg = cmp_argparse(cfg,varargin{:});
            
            if ~isempty(cfg.cfg_file)
                if exist(cfg.cfg_file,'file')
                    fid = fopen(cfg.cfg_file);
                    text = textscan(fid,'%s','Delimiter','\n');
                    credentials = text{:};
                    
                    cfg.server_name = credentials{1};
                    cfg.name = credentials{2};
                    cfg.user = credentials{3};
                    cfg.pass = credentials{4};                
                else
                    error('Config file does not exist');
                end
            end
                
            try
                [this.conn,this.connh] = ...
                    SQL.SqlBase.dbconn2(cfg.server_name, ...
                                        cfg.name, ...
                                        cfg.user, ...
                                        cfg.pass);
            catch exception
                warning(['Could not open database connection. SQL database is ' ...
                         'unavailable']);
            end
        end
    end    
    
    methods(Static,Access=private)
        function [conn,connh] = dbconn2(server_name, name, user, pass)
            global DBCONNECTIONS;
            narginchk(3, 4);   
            if (nargin == 3), pass = ''; end

            if ~usejava('jvm')
                error([mfilename ' requires Java to run.']);
            end   

            % Create the database connection object
            jdbcString = sprintf('jdbc:mysql://%s/%s', server_name, name);
            jdbcDriver = 'com.mysql.jdbc.Driver';

            hash = [name user];
            hash_time = [name user 'time'];
            if (~isfield(DBCONNECTIONS, hash) || ~isa(DBCONNECTIONS.(hash), 'database')) %connection did not exist
                DBCONNECTIONS.(hash) = database(name, user, pass, jdbcDriver, jdbcString);
                DBCONNECTIONS.(hash_time) = now;
            elseif (~isopen(DBCONNECTIONS.(hash))) %reconnect
                DBCONNECTIONS.(hash) = database(name, user, pass, jdbcDriver, jdbcString);
                DBCONNECTIONS.(hash_time) = now;
            end

            if (now - DBCONNECTIONS.(hash_time) > 20/24/60) %20 min
                try
                    close(DBCONNECTIONS.(hash));
                catch
                end
                DBCONNECTIONS.(hash) = database(name, user, pass, jdbcDriver, jdbcString);
                DBCONNECTIONS.(hash_time) = now;
                disp('DB connection refreshed.');
            end

            if (~isopen(DBCONNECTIONS.(hash))) %final check
                error(get(DBCONNECTIONS.(hash), 'Message'));
            end

            DBCONNECTIONS.(hash_time) = now;
            conn = DBCONNECTIONS.(hash);
            connh = conn.Handle;
            connh.setAutoReconnect(true);
        end
    end
end
