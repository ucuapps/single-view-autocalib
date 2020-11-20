function [t0, t1] = MC_to_t(c)
    % From M circles to M undistorted lines
    % as functions of q of the form:
    % t(q) = t0 + t1 .* q;
    %
    % Args:
    %   c --  4xN array -- N circles underparametrized by
    %                      [px; py; nx; ny] (see Wildenauer BMVC13)

    M = size(c,2);

    px = c(1,:);
    py = c(2,:);
    nx = c(3,:);
    ny = c(4,:);
    t0 = [nx; ny; - nx .* px - ny .* py];
    t1 = [nx .* px.^2 - nx .* py.^2 + 2 * ny .* px .* py;...
            ny .* py.^2 - ny .* px.^2 + 2 * nx .* px .* py;...
            zeros(1, M)];
end