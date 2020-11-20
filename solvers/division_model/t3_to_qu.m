function [q, u] = t3_to_qu(t0, t1)
    % From 3 lines as functions of division model parameter q:
    % (t(q) = t0 + t1 * q) to division model parameter [q]
    % and vanishing point [u]

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
    q = transpose(roots(coeffs_q));

    % The vanishing point
    u0 = cross(t0_, t0_p);
    u1 = cross(t0_, t1_p) + cross(t1_, t0_p);
    u2 = cross(t1_, t1_p);
    u = u0 + u1 .* q + u2 .* q.^2;
end
