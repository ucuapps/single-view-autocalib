%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
classdef KeyValDb < handle
    properties
        db
    end

    methods (Static)
        function obj = getObj(varargin) 
            persistent localObjKeyValDb;
            if isempty(localObjKeyValDb) || ~isvalid(localObjKeyValDb)
                localObjKeyValDb = KeyValDb(varargin{:});
            end
            obj = localObjKeyValDb;
        end
    end 

    methods (Access = private) 
        function this = KeyValDb(varargin)
            p = inputParser;
            dbfile = fullfile([pwd '/features.db']);
            addOptional(p,'dbfile',dbfile);
            parse(p,varargin{:});
            if ~exist(p.Results.dbfile,'file')
                try 
                    this.db = sqlite(p.Results.dbfile,'create');
                    exec(this.db, ...
                         ['CREATE TABLE `cid_table` (`k`	TEXT NOT NULL, `v` ' ...
                          'BLOB NOT NULL, PRIMARY KEY(`k`))']);
                catch
                    disp('Database does not exist. Could not create the database.');
                end
            else
                this.db = sqlite(p.Results.dbfile,'connect');            
            end
        end
    end

    methods
%        function cid = put_img(this,url)
%            filecontents = get_native_img(url);
%            cid = HASH.hash(filecontents,'MD5');
%            this.put('image',cid,'raw',filecontents);
%        end
%        
%        function img = get_img(this,cid)
%            img = [];
%            has_img = this.check('image',cid,'raw');
%            if has_img
%                filecontent = this.get('image',cid,'raw');
%                try
%                    img = readim(filecontent);
%                catch
%                    if exist('/tmp','dir') == 7
%                        tmpurl = ['/tmp/tmpimpng' cid];
%                    else
%                        tmpurl = ['tmpimpng' cid];
%                    end
%                    fid = fopen(tmpurl,'w');
%                    fwrite(fid,filecontent);
%                    fclose(fid);
%                    img = imread(tmpurl);
%                    delete(tmpurl);                    
%                end
%            end
%        end
        
        function [] =  put(this,table,cid,key,data)
            k = KEY.hash([cid ':' key],'MD5');
            v =  char(hlp_serialize(data));
            row = cell2table({k,v},'VariableNames',{'k','v'});
            insert(this.db,'cid_table', {'k','v'}, row);
        end

        function [data,is_found] = get(this,table,cid,key)
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
        
        function [] = remove(this,table,cid,key)
            k = KEY.hash([cid ':' key],'MD5');
            exec(this.db, ...
                 ['DELETE FROM cid_table WHERE k like ''' k '''']);
        end

        function is_found = check(this,table,cid,key)
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