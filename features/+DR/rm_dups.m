%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function Gp = rm_dups(x,G)
N = size(x,2);
d2 = pdist(x','euclidean');
ind = find(d2 < 20);
if ~isempty(ind)
    [I,J] = itril(N,-1);
    I = I(ind);
    J = J(ind);
    Gp([I;J]) = nan;
    num_good = sum(~isnan(G));
    if num_good == 1
        Gp = nan(size(G));
    end
end
