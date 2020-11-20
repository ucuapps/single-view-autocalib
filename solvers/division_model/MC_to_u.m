function [u0, u1, u2] = MC_to_u(c)
    % From M pairs of circles to M vanishing points
    % as functions of q of the form:
    % u(q) = u0 + u1 .* q + u2 .* q^2; 
    %
    % Args:
    %   c --  8xM array, where 8 = 2 * (2 + 2) -- 2 circles
    %   underparametrized by [px; py; nx; ny] (see Wildenauer BMVC13)

    M = size(c,2);

    [t0, t1] = MC_to_t(reshape(c,4,[]));
    t0 = reshape(t0, 6, []);
    t1 = reshape(t1, 6, []);

    u0 = cross(t0(1:3,:), t0(4:6,:));
    u1 = cross(t0(1:3,:), t1(4:6,:)) + cross(t1(1:3,:), t0(4:6,:));
    u2 = cross(t1(1:3,:), t1(4:6,:));
end