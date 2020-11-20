function G = rm_singletons(G)
freq = hist(G,1:max(G));
[~,idxb] = ismember(find(freq == 1),G);
G(idxb) = nan;
G = reshape(findgroups(G),1,[]);