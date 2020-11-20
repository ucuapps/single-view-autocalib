function [q, l, u, v, w] = NP3_MC_to_qlu(x, c)
    % From 3 point correspondences and a pair of circles
    % to division model parameter [q],
    % vanishing line [l] and three vanishing points [u, v, w]
    %
    % Args:
    %   x --  6xN array, N=3 point csponds
    %   c --  4xM array, M circles
    %   underparametrized by [px; py; nx; ny] (see Wildenauer BMVC13)
    
    M = size(c,2);
    cidx = nchoosek(1:M,2);
    N = size(cidx,1);

    q = nan(1,4*N);
    l = nan(3,4*N);
    u = nan(3,4*N);
    v = nan(3,4*N);
    w = nan(3,4*N);
    f = nan(1,4*N);

    [t0, t1] = NP_to_t(x);
    [q_, u_] = t3_to_qu(t0, t1);

    q([1:4:4*N]) = q_(1);
    q([3:4:4*N]) = q_(2);
    u(:,[1:4:4*N]) = u_(:,1) .* ones(1,N);
    u(:,[3:4:4*N]) = u_(:,2) .* ones(1,N);
    q([2:2:4*N]) = q([1:2:4*N]);
    u(:,[2:2:4*N]) = u(:,[1:2:4*N]);

    [t0, t1] = MC_to_t(c);

    for k = 1:2:4*N
        ind = [k:k+1];
        cind = cidx(ceil(k/4),:);
        t = t0(:,cind) + q(k)*t1(:,cind);
        [v(:,ind),w(:,ind),f(ind),l(:,ind)] = t2u_to_vw(t, u(:,k));
    end
end
