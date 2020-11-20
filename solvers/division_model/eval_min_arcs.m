function errs = eval_min_arcs(q, vp, arcs, c)
    arc_sizes = cellfun(@(x) size(x,2), arcs);
    arc_idx = repelem(1:numel(arcs), arc_sizes);
    x_arc = [arcs{:}];
    errs = ones(size(q))*NaN;
    N_vp = size(vp,1)/3;
    for k=1:numel(q)
        x_mid = repmat(RP2.backproject_div(RP2.homogenize(c(4:5,:)),eye(3),q(k)),1,1,N_vp);
        m = cross(x_mid,repmat(reshape(vp(:,k),3,1,N_vp),1,size(x_mid,2),1));
        m = reshape(m,3,[]);
        circ = LINE.project_div(m,eye(3),q(k));
        circ = reshape(circ,3,[],N_vp);
        dx = vecnorm(x_arc(1:2,:)-circ(1:2,arc_idx,:),2,1);
        dr2 = (dx-circ(3,arc_idx,:)).^2; % distances
        dr2 = splitapply(@sum,dr2,arc_idx); % sum sq. distances
        [ssq_err,Gvp] = min(dr2,[],3);
        errs(k) = sum(ssq_err)/sum(arc_sizes);
    end
end