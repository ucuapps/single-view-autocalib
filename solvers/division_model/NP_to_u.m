function [u0, u1, u2] = NP_to_u(x)
    % From N pairs of point correspondences to N vanishing points
    % as functions of q of the form:
    % u(q) = u0 + u1 .* q + u2 .* q^2; 
    %
    % Args:
    %   x --  12xN array, where 12 = 2 * 6 -- 2 point csponds
    %   6 -- [x1 y1 1 xp1 yp1 1] (1st PC) [x2 y2 1 xp2 yp2 1] (2nd PC)

    [t0, t1] = NP_to_t(reshape(x,6,[]));
    t0 = reshape(t0, 6, []);
    t1 = reshape(t1, 6, []);

    u0 = cross(t0(1:3,:), t0(4:6,:));
    u1 = cross(t0(1:3,:), t1(4:6,:)) + cross(t1(1:3,:), t0(4:6,:));
    u2 = cross(t1(1:3,:), t1(4:6,:));
end