%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function [] = put_img_set(base_path,name,varargin)
cache_params = { 'read_cache', true, ...
                 'write_cache', true };
init_dbs(cache_params{:});

sqldb = SQL.SqlDb.getObj();
cassdb = CASS.CassDb.getObj();

img_urls = get_img_urls(base_path);

for k = 1:numel(img_urls)
    cids{k} = cassdb.put_img(img_urls{k});
end

cids = sqldb.put_img_set(name,img_urls,...
                         'InsertMode','Replace');

function img_urls = get_img_urls(base_path)
img_urls = dir(fullfile(base_path,'*.jpg'));
img_urls = cat(1,img_urls,dir(fullfile(base_path,'*.JPG')));
img_urls = cat(1,img_urls,dir(fullfile(base_path,'*.png')));
img_urls = cat(1,img_urls,dir(fullfile(base_path,'*.PNG')));
img_urls = cat(1,img_urls,dir(fullfile(base_path,'*.gif')));
img_urls = cat(1,img_urls,dir(fullfile(base_path,'*.GIF')));

img_urls = rmfield(img_urls,{'date','bytes','isdir','datenum'});
img_urls = arrayfun(@(x)[x.folder '/' x.name], ...
                    img_urls,'UniformOutput',false)
