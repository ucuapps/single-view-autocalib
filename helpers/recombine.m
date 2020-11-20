function res = recombine(split_res,idx0,G)
[~,dim] = max(size(G));
idx = cat(dim,idx0{:});
max_idx = max(idx);
indices = repmat({':'},1,ndims(split_res{1}));
indices{dim} = idx;
max_indices = size(split_res{1});
max_indices(dim) = numel(G);

if isnumeric(split_res{1})
    res = nan(max_indices);
end
   
res(indices{:}) = cat(dim,split_res{:});
