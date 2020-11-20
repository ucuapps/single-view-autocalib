function rgn_cspond = label_to_cspond(G)
    G = findgroups(reshape(G,1,[]));
    rgn_cspond = splitapply(@(ind) { make_cspond(ind) }, ...
                            1:numel(G),G);
    rgn_cspond = sort([rgn_cspond{:}]);
end

function cspond = make_cspond(ind)
    cspond = [];
    N = size(ind,2);
    if N > 1
        [ii0,jj0] = itril([N N],-1);
        cspond = [ind(ii0);ind(jj0)];
    end
end