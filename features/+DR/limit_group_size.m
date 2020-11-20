function G = limit_group_size(G,T)
    freq = hist(G,1:max(G));
    breakit = find(freq > T);
    for k = breakit
        ind = find(G == k);
        m = ceil(freq(k)/T);
        Gp = repmat([1:m],T,1)+max(G);
        Gp = Gp(1:end-(numel(Gp)-numel(ind)));
        G(ind) = Gp;
    end
    G = DR.rm_singletons(findgroups(G));