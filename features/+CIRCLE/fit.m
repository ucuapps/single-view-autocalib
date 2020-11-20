function [c_hat, s1_hat, s2_hat, p_hat, n_hat, arc_list] = fit(arc_list, varargin)
    cfg = struct('method', 'GN');
    cfg = cmp_argparse(cfg, varargin{:});
    warning('off', 'MATLAB:rankDeficientMatrix');

    options = optimoptions(@lsqnonlin, ...
                           'Algorithm', 'trust-region-reflective', ...
                           'Display','off', ...
                           'MaxIterations',3);
    
    for k = 1:size(arc_list, 2)
        arc = arc_list{k};
        arc = arc(1:2,:);
        m(:,k) = arc(:,floor(size(arc,2)/2))';
        c_hat0(:,k) = CIRCLE.fit_taubin(arc');
        dc = lsqnonlin(@(dc,c0,xd) calc_arc_cost(dc,c0,xd), ...
                       zeros(3,1),[],[],options,c_hat0(:,k),arc);
        c_hat(:,k) = c_hat0(:,k)+dc;
        s1(:,k) = arc(:,1);
        s2(:,k) = arc(:,end);
    end
    s1_hat = CIRCLE.project(s1, c_hat);
    s2_hat = CIRCLE.project(s2, c_hat);
    [p_hat, n_hat] = ARC.get_midpoint(c_hat, s1_hat, s2_hat);
end
    
function cost = calc_arc_cost(dc,c0,xd)
    c = c0+dc;
    rhat = sqrt(sum((xd(1:2,:)-c(1:2)).^2));
    r = c(3);
    cost = reshape(rhat-r,[],1);
end