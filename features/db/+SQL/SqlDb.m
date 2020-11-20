%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
classdef SqlDb < SQL.SqlBase
     methods (Static)
        function obj = getObj( renew, varargin ) 
            if nargin == 0
                renew = false;
            end         
            persistent localObjSqlDb;
            if isempty(localObjSqlDb) || ~isvalid(localObjSqlDb) || renew
                localObjSqlDb = SQL.SqlDb;
                localObjSqlDb.open(varargin{:});
            end
            obj = localObjSqlDb;
        end
    end 

    methods (Access = private)
        function this = SqlDb(varargin)
            this@SQL.SqlBase(varargin{:});
        end
    end

    methods(Access=public)
        function [] = create(this)
            stm = this.connh.prepareStatement(['CREATE TABLE IF NOT EXISTS imgs(' ...
                                'cid BINARY(16), ' ...
                                'url TEXT, ' ...
                                'PRIMARY KEY(cid))']);
            stm.execute();

            stm = this.connh.prepareStatement(['CREATE TABLE IF NOT EXISTS img_sets(' ...
                                'id INTEGER AUTO_INCREMENT, ' ...
                                'name VARCHAR(128) NOT NULL, ' ...
                                'cid BINARY(16) NOT NULL, ' ...
                                'PRIMARY KEY(id), ' ...
                                'INDEX(name), ' ...
                                'CONSTRAINT img_set_id UNIQUE (name,cid),' ...
                                'CONSTRAINT FOREIGN KEY(cid) REFERENCES imgs(cid))']);
            stm.execute();
    
            % stm = this.connh.prepareStatement(['CREATE TABLE IF NOT EXISTS stereo_sets(' ...
            %                     'id INTEGER AUTO_INCREMENT, ', ...
            %                     'name VARCHAR(256) NOT NULL, ' ...
            %                     'img1_id BINARY(16) NOT NULL, ' ...
            %                     'img2_id BINARY(16) NOT NULL, ' ...
            %                     'gt_url TEXT, ' ...
            %                     'description TEXT, ' ...
            %                     'acknowledgement TEXT, ' ...
            %                     'refs TEXT, ' ...
            %                     'PRIMARY KEY(id), ' ...
            %                     'INDEX(name), ' ...
            %                     'CONSTRAINT stereo_set_id UNIQUE (name,img1_id,img2_id), ' ...
            %                     'CONSTRAINT FOREIGN KEY(img1_id,img2_id) ' ...
            %                     'REFERENCES img_pairs(img1_id,img2_id))']);
            % stm.execute();
        end

        function [] =  clear(this)
            warning('SqlDb just erased all the cvdb tables in your database');
            stm = this.connh.prepareStatement(['DROP TABLE IF EXISTS img_sets, imgs, img_pairs, ' ...
                                'stereo_sets']);
            stm.execute();
        end
        
        function err = put_img(this, cid, url)
            url = SQL.get_canonical_path(url);
            stm =  this.connh.prepareStatement(['INSERT INTO imgs' ...
                                ' (cid, url)' ...
                                ' VALUES(UNHEX(?),?) ON ' ...
                                'DUPLICATE KEY UPDATE url = ?']);
            
            stm.setString(1, cid);
            stm.setString(2, url);
            stm.setString(3, url);

            err = stm.execute();
        end            

        function is = check_img(this,url)
            stm =  this.connh.prepareStatement(['SELECT cid ' ...
                                     'FROM imgs ' ...
                                     'WHERE url=?']);
            stm.setString(1, SQL.get_canonical_path(url));
            rs = stm.executeQuery();
            is = rs.next();
        end

        function cids = put_img_set(this,set_name,img_set, ...
                                    varargin)
            cfg = [];
            cfg.description = [];
            cfg.replace = true;
            [cfg,leftover] =  cmp_argparse(cfg,varargin{:});

            stm = this.connh.prepareStatement(['SELECT COUNT(*) FROM img_sets ' ...
                                'WHERE name=?']);
            stm.setString(1, set_name);
            rs = stm.executeQuery();
            rs.next();
            count = rs.getInt(1);
            
            if (count == 0 || cfg.replace)
                stm =  this.connh.prepareStatement(['INSERT IGNORE INTO img_sets' ...
                                    ' (name,cid)' ...
                                    ' VALUES(?,UNHEX(?))']);                
                cids = {};
                for i = 1:length(img_set)
                    url = SQL.get_canonical_path(img_set{i});
                    filecontents = get_native_img(url);
                    cids{i} = KEY.hash(filecontents(:),'MD5');
                    [pth, img_name, ext] = fileparts(url);

                    err = this.put_img(cids{i},url);
                    
                    stm.setString(1, set_name);
                    stm.setString(2, cids{i});

                    stm.addBatch();
                end

                err = stm.executeBatch();
            end
            close(stm);
        end   

        function [] = remove_img_set(this,set_name)
            stm = this.connh.prepareStatement([ 'DELETE FROM img_sets ',...
                                                'USING img_sets INNER JOIN imgs ',...
                                                'WHERE img_sets.cid=imgs.cid ',...
                                                'AND img_sets.name=?' ]);
            stm.setString(1, set_name);
            rs = stm.executeQuery();
        end   

        function cid = get_img_cid(this,url)
            stm = this.connh.prepareStatement(['SELECT COUNT(*) FROM imgs']);
            rs = stm.executeQuery();
            rs.next();
            count = rs.getInt(1);
            cid = {};
            if (count > 0)    
                sql_query = ['SELECT HEX(cid) FROM imgs WHERE url=?'];
                stm = this.connh.prepareStatement(sql_query);
                stm.setString(1,url);
                rs = stm.executeQuery();
                row_num = 0;
                while (rs.next())
                    row_num = row_num+1;
                    cid = lower(char(rs.getString(1)));
                end
            end                               
        end 

        function rs = remove_img(this,cid)
            stm = this.connh.prepareStatement([ 'DELETE FROM img_sets ',...
                                                'WHERE cid=UNHEX(?)']);
            stm.setString(1, cid);
            rs = stm.executeUpdate(); 
        end
        
        function url = get_img_url(this,cid)
            stm = this.connh.prepareStatement(['SELECT COUNT(*) FROM imgs']);
            rs = stm.executeQuery();
            rs.next();
            count = rs.getInt(1);
            url = {};
            if (count > 0)    
                sql_query = ['SELECT url FROM imgs WHERE cid=UNHEX(?)'];

                stm = this.connh.prepareStatement(sql_query);
                stm.setString(1, cid); 
                rs = stm.executeQuery();

                % row_num = 0;
                while (rs.next())
                    % row_num = row_num+1;
                    url = char(rs.getString(1));
                end
            end        
        end 

        function img_set = get_img_set(this,set_name,img_names)
            if nargin < 3
                img_names = [];
            end
            img_set = {};

            stm = this.connh.prepareStatement(['SELECT COUNT(*) FROM img_sets ' ...
                               'WHERE name=?']);
            stm.setString(1, set_name);
            rs = stm.executeQuery();
            rs.next();
            count = rs.getInt(1);

            if (count > 0)    
                sql_query = ['SELECT url,HEX(imgs.cid) ' ...
                             'FROM img_sets JOIN imgs ' ...
                             'WHERE img_sets.cid=imgs.cid ' ...
                             'AND img_sets.name=?'];

                stm = this.connh.prepareStatement(sql_query);
                stm.setString(1, set_name); 
                rs = stm.executeQuery();

                img_set = {};
                row_num = 0;
                while (rs.next())
                    row_num = row_num+1;
                    img_set(row_num).url = char(rs.getString(1));
                    img_set(row_num).cid = lower(char(rs.getString(2))); 
                    [~,img_set(row_num).name,~] = fileparts(img_set(row_num).url); 
                end
            end
            
            if ~isempty(img_names)
                img_set = SQL.find_img_subset(img_set,img_names);
            end
        end


        function [] = put_stereo_set(this,set_name,img_set,varargin)
            cfg = [];
            cfg.description = [];
            cfg.replace = false;

            [cfg,leftover] =  cmp_argparse(cfg,varargin{:});
 
            h = char(zeros(2,32));

            stm = this.connh.prepareStatement(['SELECT COUNT(*) FROM stereo_sets ' ...
                                'WHERE name=?']);
            stm.setString(1, set_name);
            rs = stm.executeQuery();
            rs.next();
            count = rs.getInt(1);

            if (count == 0 || cfg.replace == 1)
                for i = 1:length(img_set)
                    for j = 1:2
                        [pth, img_name, ext] = fileparts(img_set{i}{j});
                        img{j} = imread(img_set{i}{j});
                        width  = size(img{j},2);
                        height = size(img{j},1);

                        sql_statement = ['SELECT COUNT(*) FROM imgs WHERE id=' ...
                                         'UNHEX(?)'];
                        stm = this.connh.prepareStatement(sql_statement);
                        h(j,:) = HASH.img(img{j}(:));
                        
                        stm.setString(1, h(j,:));
                        rs = stm.executeQuery();
                        rs.next();
                        count = rs.getInt(1);
                        rel_pth = regexpi(img_set{i}{j}, '[^/]*/[^/]*$', ...
                                          'match');
                        if (count == 0) 
                            this.put_img(img{j}, img_path_pair{j}, rel_pth, img_name, ext);
                        end
                    end
                    
                    sql_statement = ['SELECT COUNT(*) FROM stereo_sets WHERE ' ...
                                     'img1_id=UNHEX(?) AND img2_id=UNHEX(?)'];
                    stm = this.connh.prepareStatement(sql_statement);
                    stm.setString(1,h(1,:));
                    stm.setString(2,h(2,:));
                    rs = stm.executeQuery();
                    rs.next();
                    count = rs.getInt(1);
                    if (count == 0 || cfg.replace)
                        stm = this.connh.prepareStatement(['REPLACE INTO stereo_sets (name,img1_id,img2_id,gt_url,description)' ...
                                            'VALUES(?,UNHEX(?),UNHEX(?),?,?)']);
                        stm.setString(1,set_name);
                        stm.setString(2,h(1,:));
                        stm.setString(3,h(2,:));

                        if (numel(img_set{i}) > 2)
                            stm.setString(4,[img_set{i}{3}]); 
                        else
                            stm.setNull(4,java.sql.Types.VARCHAR);                
                        end

                        if isempty(cfg.description)
                            stm.setNull(5,java.sql.Types.VARCHAR);
                        else
                            stm.setString(5,cfg.description);
                        end

                        err = stm.execute();
                    end
                end
            end
        end

        function stereo_set = get_stereo_set(this,set_name)
            stereo_set = {};
            stm = this.connh.prepareStatement(['SELECT COUNT(*) FROM stereo_sets ' ...
                                'WHERE name=?']);
            stm.setString(1, set_name);
            rs = stm.executeQuery();
            rs.next();
            count = rs.getInt(1);

            if (count > 0)    
                img_num = 'img1_id';

                sql_query_1 = ['SELECT im1.url, im1.height, im1.width, im1.name, im1.ext, ' ...
                               'im2.url, im2.height, im2.width, im2.name, im1.ext, ss.gt_url ' ...
                               'FROM stereo_sets AS ss ' ...
                               'INNER JOIN imgs AS im1 ON img1_id = im1.id ' ...
                               'INNER JOIN imgs AS im2 ON img2_id = im2.id ' ...
                               'WHERE ss.name = ?'];

                stm = this.connh.prepareStatement(sql_query_1);
                stm.setString(1, set_name);
                rs = stm.executeQuery();

                stereo_set = {};
                row_num = 0;
                while (rs.next())
                    row_num = row_num+1;

                    stereo_set(row_num).img1.url = ...
                        char(rs.getString(1));
                    stereo_set(row_num).img1.height = ...
                        rs.getInt(2);
                    stereo_set(row_num).img1.width = ...
                        rs.getInt(3);
                    stereo_set(row_num).img1.name = ...
                        char(rs.getString(4));
                    stereo_set(row_num).img1.ext = ...
                        char(rs.getString(5));

                    names_lower{row_num} = lower(stereo_set(row_num).img1.name);

                    stereo_set(row_num).img2.url = ...
                        char(rs.getString(6));
                    stereo_set(row_num).img2.height = ...
                        rs.getInt(7);
                    stereo_set(row_num).img2.width = ...
                        rs.getInt(8);
                    stereo_set(row_num).img2.name = ...
                        char(rs.getString(9));
                    stereo_set(row_num).img2.ext = ...
                        char(rs.getString(10));

                    stereo_set(row_num).gt_url = ...
                        char(rs.getString(11));
                end
            end

            [~,ind] = sort(names_lower);
            stereo_set = stereo_set(ind);
        end
    end

end