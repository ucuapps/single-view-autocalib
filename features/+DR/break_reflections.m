% handle problems with reflections
function G = break_reflections(x,G) 
    is_ccwise = PT.is_ccwise(x);
    G(is_ccwise) = findgroups(G(is_ccwise));
    if any(is_ccwise)
        offset = max(G(is_ccwise));
    else
        offset = 0;
    end
    if any(~is_ccwise)
        G(~is_ccwise) = findgroups(G(~is_ccwise))+offset;
    end
    
    G = DR.rm_singletons(findgroups(G));