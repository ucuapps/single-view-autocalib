%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
classdef CidCache < handle
    properties(Access=private)
        G;
        cid;
        imagedb;
        vlist;
        map;
        last_add;
        cfg;
    end

    methods(Access=public)
        function this = CidCache(cid,varargin)
            this.imagedb = KeyValDb.getObj();
            this.cid = cid;
            this.map = containers.Map;
            this.vlist = cell(1,1000);
            this.G = digraph;
            last_add = {};
            
            this.cfg.read_cache = true;
            this.cfg.write_cache = true;

            [this.cfg,~] = cmp_argparse(this.cfg,varargin{:}); 
            
            if isempty(cid) || isempty(this.imagedb)
                this.cfg.read_cache = false;
                this.cfg.write_cache = false;
            end
        end 
        
        function imagedb = get_imagedb(this)
            imagedb = this.imagedb;
        end

        function [xor_key,v] = add_dependency(this,name,key,varargin)
            tcfg.parents = {};
            tcfg.read_cache = this.cfg.read_cache;
            tcfg.write_cache = this.cfg.write_cache;

            tcfg = cmp_argparse(tcfg,varargin);
	        
    	    if ~isempty(tcfg.parents) && ~iscell(tcfg.parents)
                tcfg.parents = {tcfg.parents};
            end
    	    
            if strcmpi([tcfg.parents{:}],'__LAST_ADD__')
                tcfg.parents = last_add;
            end

            v = this.add_vertex(name,key,tcfg);
            xor_key = this.get_xor_key(v);
            last_add = name;
        end

        function key_list = add_chains(this,chains,varargin)
            tcfg.parents = {};
            tcfg.read_cache = this.cfg.read_cache;
            tcfg.write_cache = this.cfg.write_cache;
            tcfg = cmp_argparse(tcfg,varargin);            
            
            key_list = cell(1,numel(chains));
            for k = 1:numel(chains)
                key_list{k} = cell(1,numel(chains{k}));
                parents = tcfg.parents;
                for k1 = 1:numel(chains{k})
                    name = chains{k}{k1}.get_uname();
                    [~,v]=this.add_dependency(name,chains{k}{k1}, ...
                                        'parents',parents, ...
                                        'read_cache',tcfg.read_cache, ...
                                        'write_cache',tcfg.write_cache);
                    [~, name_list] = get_parent_tree(this,v);
                    key_list{k}{k1} = strjoin(name_list,':');
                    parents = key_list{k}{k1};
                end
            end
        end
        
        function [res,is_found,name_list] = get_chains(this,chains,init_parents,fmake,varargin)
            if nargin < 3
                init_parents = '';
            elseif ~isempty(init_parents)
                init_parents = [init_parents ':'];
            end
            is_found = cell(1,numel(chains));
            res = cell(numel(chains),1);
            name_list = cell(numel(chains),1);
            for k = 1:numel(chains)
                name = init_parents;
                res{k} = cell(1,numel(chains{k}));
                is_found{k} = false(1,numel(chains{k}));
                for k1 = 1:numel(chains{k})
                    name_list{k}{k1} = [name chains{k}{k1}.get_uname()];
                    name = [name_list{k}{k1} ':'];
                    [res{k}{k1},is_found{k}(k1)] = ...
                        this.get('dr',name(1:end-1));
                end
            end
            
            if any(~[is_found{:}]) && nargin > 3
                res = feval(fmake,chains,varargin{:},res);
                this.put_chains(chains,res,init_parents,is_found);
            end
        end
        
        function [res,is_found] = put_chains(this,chains,res,init_parents,is_found)
            if nargin < 4
                szs = cellfun(@numel,is_found);
                is_found = mat2cell(false(1,numel([res{:}])),1,szs);
            end
            
            for k = 1:numel(chains)
                name = init_parents;
                for k1 = 1:numel(chains{k})
                    name = [name chains{k}{k1}.get_uname() ':'];
                    if ~is_found{k}(k1)
                        this.put('dr',name(1:end-1),res{k}{k1});
                    end
                end
            end
        end
        
        function img = get_img(this)
            img = this.imagedb.get_img(this.cid);
        end

        function [is_put,xor_key] = put(this,table,name,value,varargin)
            cfg.overwrite = false;
            cfg = cmp_argparse(cfg,varargin);
            is_put = false;
            if this.map.isKey(name)
                item = this.map(name);
                v = item.v;
                xor_key = this.get_xor_key(v);
                if item.write_cache 
                    if (~this.imagedb.check(table,this.cid, [name ':' xor_key]))
                        this.imagedb.put(table,this.cid, ...
                                         [name ':' xor_key], ...
                                         value);
                        is_put = true;
                    else
                        error('key already in database');
%                        this.imagedb.remove(table,this.cid, ...
%                                            [name ':'  xor_key]);
%                        this.imagedb.put(table,this.cid, ...
%                                         [name ':' xor_key], ...
%                                         value);
                    end
                end
            end
        end

        function [val,is_found,xor_key] = get(this,table,name,fmake,varargin)
            val = [];
            xor_key = [];
            is_found = false;
            if this.map.isKey(name)
                item = this.map(name);
                v = item.v;
                xor_key = this.get_xor_key(v);
                if item.read_cache
                    [val,is_found] = this.imagedb.get(table, ...
                                                      this.cid,[name ':' xor_key]);    
                end    
            end
            
            if ~is_found && nargin > 3
                val = feval(fmake,varargin{:});
                if item.write_cache
                    this.put(table,name,val);
                end
                is_found = true;
            end
        end

        function [val,is_found,xor_key] = add_and_get(this,table,name,key,parents,fmake,varargin)
            if isempty(parents)
                [xor_key,v] = this.add_dependency(name,key);
            else
                [xor_key,v] = this.add_dependency(name,key,'parents',parents);
            end
            
            if nargin > 5
                [val,is_found,xor_key] = this.get(table,name,fmake,varargin{:});
            else
                [val,is_found,xor_key] = this.get(table,name);
            end
        end
    end

    methods(Access=private) 
        function res = get_key(this,name)
            item = this.map(name);
            res = item.key;
        end

        function res = get_xor_key(this,v)
            [key_list, name_list] = this.get_parent_tree(v);
            if numel(key_list) > 1
                res = KEY.xor(key_list{:});
            else
                res = key_list{1};
            end
            if numel(name_list) > 1
                uid = strjoin(name_list,':');
                res = KEY.xor(res,KEY.hash(uid,'MD5'));
            end
        end
        
        function v = add_vertex(this,name,key,tcfg)
            hkey = KEY.make(key);
            [ii,jj] = findedge(this.G);
            this.G = sparse(ii,jj,ones(1,numel(jj)), ...
                           numnodes(this.G)+1, ...
                           numnodes(this.G)+1); 
            if size(this.G,1) > 1            
                for pa = tcfg.parents
                    item = this.map(pa{:});
                    this.G(size(this.G,1),item.v) = 1;
                end
            end
            this.G = digraph(this.G);                

            v = numnodes(this.G);
            item = struct('v',v, ...
                          'key',hkey, ...
                          'name',name, ...
                          'read_cache', tcfg.read_cache, ...
                          'write_cache', tcfg.write_cache);

            uid = name;
            this.map(uid) = item;
            this.vlist{v} = uid;

            [~,name_list] = this.get_parent_tree(v);
            if numel(name_list) > 1
                uid = strjoin(name_list,':');
                
                item.key = KEY.make(key,uid);
                this.map(uid) = item;
                this.vlist{v} = uid;
            end
        end

        function [key_list, name_list] = get_parent_tree(this,v)
            dt = distances(this.G,v)+1;
            dt(~isfinite(dt)) = -1;
            dt = dt';

            tmp = v;
            ia = v;
            [val,order] = sort(dt);
            order = order(val > 0);
            key_list = cellfun(@(x) x.key, ...
                               values(this.map,this.vlist(order)), ...
                               'UniformOutput',false);
            name_list = cellfun(@(x) x.name, ...
                   values(this.map,this.vlist(order(end:-1:1))), ...
                   'UniformOutput',false);
        end

        function [] = remove_vertex(this,v)
            p = dfs(this.G);
            this.G(:,p) = [];
            this.G(p,:) = [];
            remove(this.map,vlist(p));
        end
    end
end