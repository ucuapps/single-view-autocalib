function [q,vl,u,v,f] = c5_to_qlu(t)
    % Solver from "Closed form solution for radial distortion estimation from a single vanishing point" by Wildenauer et al.
    %
    % Args:
    %     t -- 4x5 array, 5 underparameterized circles
    %          ([x...; y...; nx...; ny...])
    
    q = nan(1,60);
    vl = nan(3,60);
    u = nan(3,60);
    v = nan(3,60);
    f = nan(1,60);

    ind = [1 2 3 4 5
           1 2 4 3 5
           1 2 5 3 4
           1 3 4 2 5
           1 3 5 2 4
           1 4 5 2 3
           2 3 4 1 5
           2 3 5 1 4
           2 4 5 1 3
           3 4 5 1 2 ];
    
    t = reshape(t(:,ind'),4,5,[]);
    for k = 1:10
        ind = 6*(k-1)+1:6*(k-1)+6;
        [q(ind),vl(:,ind),u(:,ind),v(:,ind),f(ind)] = ...
            inner_c32_to_qlu(t(:,:,k)); 
    end
end

function [q,vl,u,v,f] = inner_c32_to_qlu(t)
    q = nan(1,6);
    vl = nan(3,6);
    u = nan(3,6);
    v = nan(3,6);
    f = nan(1,6);
    
    px = t(1,:);
    py = t(2,:);
    nx = t(3,:);
    ny = t(4,:);
    t0 = [nx; ny; - nx .* px - ny .* py];
    t1 = [nx .* px.^2 - nx .* py.^2 + 2 * ny .* px .* py;...
          ny .* py.^2 - ny .* px.^2 + 2 * nx .* px .* py;...
          zeros(1,5)];

    % Solving for q
    t0_ = t0(:,1);
    t1_ = t1(:,1);
    t0_p = t0(:,2);
    t1_p = t1(:,2);
    t0_pp = t0(:,3);
    t1_pp = t1(:,3);
    d = [t0_' t0_p' t0_pp'];
    e = [t1_' t1_p' t1_pp'];

    coeffs_q(1) = (e(4)*e(8) - e(5)*e(7))*d(3) -...
        (e(1)*e(8) - e(2)*e(7))*d(6) +...
        (e(1)*e(5) - e(2)*e(4))*d(9);
    coeffs_q(2) = (e(4)*d(8) - e(5)*d(7))*d(3) -...
        (e(1)*d(8) - e(2)*d(7))*d(6) +...
        (e(1)*d(5) - e(2)*d(4))*d(9) +...
        (d(4)*e(8) - d(5)*e(7))*d(3) -...
        (d(1)*e(8) - d(2)*e(7))*d(6) +...
        (d(1)*e(5) - d(2)*e(4))*d(9);
    coeffs_q(3) = (d(4)*d(8) - d(5)*d(7))*d(3) -...
        (d(1)*d(8) - d(2)*d(7))*d(6) +...
        (d(1)*d(5) - d(2)*d(4))*d(9);

    q(1:2) = reshape(roots(coeffs_q),1,[]); 

    % The first vanishing point
    u0 = cross(t0_, t0_p);
    u1 = cross(t0_, t1_p) + cross(t1_, t0_p);
    u2 = cross(t1_, t1_p);
    u(:,1:2) = u0 + u1 .* q(1:2) + u2 .* q(1:2).^2;
    
    % The second vanishing point
    t0_ = t0(:,4);
    t1_ = t1(:,4);
    t0_p = t0(:,5);
    t1_p = t1(:,5);
    v0 = cross(t0_, t0_p);
    v1 = cross(t0_, t1_p) + cross(t1_, t0_p);
    v2 = cross(t1_, t1_p);

    v(:,1:2) = v0 + v1 .* q(1:2) + v2 .* q(1:2).^2;

    % The vanishing line
    vl(:,1:2) = cross(u(:,1:2), v(:,1:2));
    for k = 1:2
        ind = [2*k+1:2*k+2];
        t = [t0_ + q(k)*t1_, t0_p + q(k)*t1_p];
        [v(:,ind),~,f(ind),vl(:,ind)] = t2u_to_vw(t, u(:,k));
        u(:,ind) = repmat(u(:,k),1,2);
        q(:,ind) = q(k);
    end
end