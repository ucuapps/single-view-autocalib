function G = limit_drs(G,T)
    freq = hist(G,1:max(G));
    [sfreq,ind0] = sort(freq,'descend');
    csum = cumsum(sfreq);
    ind1 = find(csum > T);
    rmind = ind0(ind1);
    [Lia,Lib] = ismember(G',rmind' ,'rows');
    G(Lia) = nan;