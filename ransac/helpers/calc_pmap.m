function pmap = calc_pmap(freq,k)
is_good = freq >= k; 
Z = zeros(1,numel(freq));
Z(is_good) = arrayfun(@(n) nchoosek(n,k),freq(is_good)); 
pmap = Z/sum(Z);