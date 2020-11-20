function res = mnrnd_without_repeat(n,p,m)
    res = [];
    for k=1:n
        idx = find(mnrnd(1,normalize(p,'norm',1),m));
        res = [res idx];
        p(idx) = 0;
    end
    res = sum(1:numel(p)==res',1);
end