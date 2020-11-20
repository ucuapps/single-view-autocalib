function errs = eval_min_hybrid(q, vp, xd, arcs, c)
    errs = ones(2,numel(q)) * NaN;
    if ~isempty(xd)
        errs(1,:) = eval_min_rgns(q, vp, xd);
    end
    if ~isempty(arcs)
        errs(2,:) = eval_min_arcs(q, vp, arcs, c);
    end
end