function [t0, t1] = NP_to_t(x)
    % From N point csponds to N undistorted lines
    % as functions of q of the form:
    % t(q) = t0 + t1 .* q;
    %
    % Args:
    %   x --  6xN array -- N point correspondences

    N = size(x,2);

    d = [zeros(2,N); sum(x(1:2,:).^2); zeros(2,N); sum(x(4:5,:).^2)];

    t0  = cross(x(1:3,:), x(4:6,:));
    t1  = cross(x(1:3,:), d(4:6,:)) + cross(d(1:3,:), x(4:6,:));
end