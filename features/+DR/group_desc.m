%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function G = group_desc(dr,varargin)
cfg.desc_cutoff = 150;
cfg.desc_linkage = 'single';

[cfg,leftover] = cmp_argparse(cfg,varargin{:});

N = numel(dr);

tmp = squeeze(struct2cell(dr)); 
names = tmp(4,:);
names = cellfun(@(u) strrep(u,'ReflectImg:',''),names, ...
                 'UniformOutput',false);
Gnames = categorical(names);
Gunames = findgroups(Gnames);
[T,idx] =  ...
    splitapply(@(x,y) ...
               deal({clusterdata(single([x(:).desc]'), ...
                                 'linkage',cfg.desc_linkage, ...
                                 'criterion','distance', ...
                                 'cutoff',cfg.desc_cutoff)},{y}), ... 
               dr,1:numel(dr),Gunames);

maxT = 0;
for k = 1:numel(T)
    G(idx{k}) = T{k}+maxT;
    maxT = max(G);
end

freq = hist(G,1:max(G));
[~,idxb] = ismember(find(freq == 1),G);
G(idxb) = nan;
G = reshape(findgroups(G),1,[]);
