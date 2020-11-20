function errs = eval_min_rgns(q, vp, xd)
    xd = RP2.renormI(reshape(xd,3,[]));
    cspond = {[1 2 3; 4 5 6], [1 4; 2 5], [1 4; 3 6], [2 5; 3 6]};
    errs = ones(1,numel(q))*NaN;
    N_vp = size(vp,1)/3;
    vpidx = nchoosek(1:N_vp,2);
    errs = ones(1,numel(q))*NaN;
    for k=1:numel(q)
        x = RP2.backproject_div(xd,eye(3),q(k));
        vp_local = reshape(vp(:,k),3,N_vp);
        ssq_err = zeros(size(vpidx,1),1);
        for k1=1:size(vpidx,1)
            u = vp_local(:,vpidx(k1,1));
            v = vp_local(:,vpidx(k1,2));
            l = cross(u,v);
            for k2=1:numel(cspond)
                cs = cspond{k2};
                x1 = x(:,cs(1,:));
                x2 = x(:,cs(2,:));
                xd1 = xd(:,cs(1,:));
                xd2 = xd(:,cs(2,:));
                w = vp_from_lines_cls(cross(x1, x2), l);
                x_mid = (x1+x2)./2;
                chat = LINE.distort_div(cross(repmat(w,1,size(cs,2)), x_mid), eye(3), q(k));
                ssq_err(k1) = ssq_err(k1) + sum((vecnorm([xd1(1:2,:) xd2(1:2,:)] - [chat(1:2,:) chat(1:2,:)]) - [chat(3,:) chat(3,:)]).^2);
            end
        end
        [errs(k), Gvp] = min(ssq_err./(size([cspond{:}],2)*2));
    end
    % q
    % ssq_err
    % keyboard
        % errs = errs ./ (size([cspond{:}],2)*2);
            % su = p1p_ct_to_scale(x(4:6,1),x(4:6,2),u,l);
            % su = permute(su,[3 1 2]);
            % Hu = repmat(eye(3,3),1,1,1)+su.*repmat(u*l',1,1,1);
            % xfer_sqerr = calc_xfer_err(x(:,1),x(:,2),xd(:,1),xd(:,2),eye(3),q(k),Hu);
            % ssq_err(2*k1-1,:) = sum(xfer_sqerr);
            % sv = p1p_ct_to_scale(x(4:6,1),x(4:6,2),v,l);
            % sv = permute(sv,[3 1 2]);
            % Hv = repmat(eye(3,3),1,1,1)+sv.*repmat(v*l',1,1,1);
            % xfer_sqerr = calc_xfer_err(x(:,1),x(:,2),xd(:,1),xd(:,2),eye(3),q(k),Hv);
            % ssq_err(2*k1,:) = sum(xfer_sqerr);
        % end
        % [ssq_err, idx] = min(ssq_err);
        % Gvl = ceil(idx/2);
        % Gvp = vpidx(sub2ind(size(vpidx),Gvl,2-mod(idx,2)));
        % errs(k) = ssq_err/3;
    % q
    % errs
    % [~,ix]=min(errs)
end

function u = vp_from_lines_cls(lines, vl)
    M = lines';
    C = [vl'; 0 0 1];
    b = zeros(3,1);
    d = [0 1]';
    A = [2 * M' * M, C'; C, zeros(2,2)];
    if det(A)<1e-2
        sol = pinv(A)*[b; d];
    else
        sol = A \ [b; d];
    end
    u = sol(1:3);
end