function [f, R] = uv_to_fR(u, v, cosphi, UV)
    if nargin < 3 || isempty(cosphi) || isnan(cosphi)
        % vps are orthogonal
        cosphi = 0;
    end
    if nargin < 4
        UV = [0;0;1];
    end
    f = [];
    R = {};

    u = u./vecnorm(u);
    v = v./vecnorm(v);

    un2 = dot(u(1:2), u(1:2));
    vn2 = dot(v(1:2), v(1:2));
    uv = dot(u(1:2), v(1:2));
    cosphi2 = cosphi^2;

    a = (u(3)*v(3))^2 * (1 - cosphi2);
    b = 2 * uv * u(3)*v(3) - (un2*v(3)^2 + vn2*u(3)^2) * cosphi2;
    c = uv^2 - un2 * vn2 * cosphi2;
    
    % Solve ax^2+bx+c=0 where x=f^2
    D = b^2 - 4*a*c;
    f_ = [];
    if abs(D) < 1e-9
        f_ = sqrt(-b / (2*a));
    elseif D > 1e-9
        f_(1) = sqrt((-b + sqrt(D)) / (2*a));
        f_(2) = sqrt((-b - sqrt(D)) / (2*a));
        f_ = f_(find(imag(f_)<1e-7));
    end
    if ~isempty(f_)
        for k=1:numel(f_)
            K = diag([f_(k),f_(k),1]);
            U = K \ u;
            V = K \ v;
            U = U./vecnorm(U);
            V = V./vecnorm(V);
            % U'*V
            % figure;
            % GRID.draw3d([1;-1;1;1;1;1;1;1;-1;1;1;1;-1;-1;1;1;1;-1;1;1],'color','k');
            % GRID.draw3d([u v U V;zeros(3,4)])
            % axis equal; view(30,30)
            % keyboard
            if abs(U'*V-cosphi) < 1e-7
                W = cross(U, sign(UV(3)) * V);
                V = cross(W, U);
                UVW = [U V W];
                f = [f f_(k)];
                R = {R{:} UVW ./ sqrt(sum(UVW.^2))};
            end
        end
    end
end
