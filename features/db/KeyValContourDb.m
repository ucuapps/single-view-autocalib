classdef KeyValContourDb < handle
    properties
        db
    end

    methods (Static)
        function obj = getObj(varargin) 
            persistent localObjKeyValContourDb;
            if isempty(localObjKeyValContourDb) || ~isvalid(localObjKeyValContourDb)
                localObjKeyValContourDb = KeyValContourDb(varargin{:});
            end
            obj = localObjKeyValContourDb;
        end
    end 

    methods (Access = private) 
        function this = KeyValContourDb(varargin)
            cfg = struct();
            cfg.dbfile = fullfile([fileparts(mfilename('fullpath')) '/../db_arc.db']);
            cfg = cmp_argparse(cfg, varargin{:});
            dbfile = GetFullPath(cfg.dbfile);
            if ~exist(dbfile, 'file')
                try 
                    this.db = sqlite(dbfile, 'create');
                    exec(this.db, ...
                         ['CREATE TABLE `cid_table` (`k`	TEXT NOT NULL, `v` ' ...
                          'BLOB NOT NULL, PRIMARY KEY(`k`))']);
                catch
                    disp('Database does not exist. Could not create the database.');
                end
            else
                this.db = sqlite(dbfile, 'connect');
            end
        end
    end

    methods
        function [] =  put(this, cid, key, data)
            if this.check(cid,key)
                this.remove(cid,key);
            end
            k = KEY.hash([cid ':' key],'MD5');
            v =  char(hlp_serialize(data));
            row = cell2table({k, v},...
                             'VariableNames',{'k','v'});
            insert(this.db,'cid_table', {'k','v'}, row);
        end

        function [data, is_found] = get(this, cid, key)
            is_found = false;
            data = [];
            k = KEY.hash([cid ':' key],'MD5');
            v = fetch(this.db, ...
                      ['SELECT * FROM cid_table WHERE k like ''' k '''']);
            if ~isempty(v)
                is_found = true;
                data = hlp_deserialize(v{2});
            end
        end
        
        function [] = remove(this, cid, key)
            k = KEY.hash([cid ':' key],'MD5');
            exec(this.db, ...
                 ['DELETE FROM cid_table WHERE k like ''' k '''']);
        end

        function is_found = check(this, cid, key)
            is_found = false;
            k = KEY.hash([cid ':' key],'MD5');
            v = fetch(this.db, ...
                     ['SELECT count(1) FROM cid_table WHERE k like  ''' k '''']);
            if v{1} == 1
                is_found = true;
            end
        end
    end
end