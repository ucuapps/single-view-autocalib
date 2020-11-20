classdef ManhattanHybridPrinter < handle
    properties
        params_idx = struct();
        data_idx = struct();
        
        reprojT_rgn = 1;
        reprojT_arc = 1;
        baselineT_rgn = 10;
        w_rgn = 1;
        w_arc = 1;

        MaxIter = 50;

        rgn_csponds = [];
        arc_sizes = []; 

        weight_fn = @huberWeightIRLS;
    end

    methods(Static)
        function alpha = pack_circ(circ, K, R, proj_params)
            q = proj_params(1);
            T = eye(3);

            vp0 = T \ RP2.project_div(R,[],proj_params);
            u = vp0(1,:);
            v = vp0(2,:);

            circ0 = CIRCLE.normalize(circ, K*T);
            a = circ0(1,:);
            b = circ0(2,:);
        
            r = vecnorm(vp0(1:2,:),2,1);
            r2 = r.^2;
            k = (1 + q * r2) ./ (2 * q * r);
            alpha1 =   a./v'.*r' - k'.*u'./v';
            alpha2 = - b./u'.*r' + k'.*v'./u';

            validu = abs(u)>1e-7;
            validv = abs(v)>1e-7;
            alpha = ones(size(alpha1))*NaN;
            alpha(validv,:) = alpha1(validv,:);
            alpha(validu,:) = alpha(validu,:)+alpha2(validu,:);
            alpha = alpha./(validu+validv)';
        end

        function circ = unpack_circ(K,R,proj_params,alpha)
            q = proj_params(1);
            T = eye(3);
            
            vp0 = T \ RP2.project_div(R,[],proj_params);
            u = vp0(1,:);
            v = vp0(2,:);

            r = vecnorm(vp0(1:2,:),2,1);
            r2 = r.^2;
            k = (1 + q * r2) ./ (2 * q * r);

            a = k'./r'.*u' + alpha.*v'./r';
            b = k'./r'.*v' - alpha.*u'./r';
            R = sqrt((a-u').^2 + (b-v').^2);
            circ0 = [reshape(a',1,[],3);reshape(b',1,[],3);reshape(R',1,[],3)];
            circ = CIRCLE.unnormalize(circ0, K*T);
        end
    end

    methods
        function this = ManhattanHybridPrinter(meas, groups, varargin)
            this = cmp_argparse(this, varargin{:});

            proj_params_idx = 1;
            f_idx = proj_params_idx(end)+1;
            R_idx = f_idx(end)+[1:3];
            this.params_idx = struct(...
                            'proj_params',proj_params_idx,...
                            'f', f_idx, ...
                            'R', R_idx);

            if groups.isKey('rgn') && ~isempty(groups('rgn'))
                this.rgn_csponds = label_to_cspond(groups('rgn'));
                valid = LAF.filter_by_baseline(meas('rgn'), this.rgn_csponds, this.baselineT_rgn);
                this.rgn_csponds = this.rgn_csponds(:,valid);
            end

            if groups.isKey('arc') && ~isempty(groups('arc'))
                arcs = meas('arc');
                this.arc_sizes = cellfun(@(x) size(x,2),arcs);
                alpha_idx = R_idx(end)+[1:3*numel(arcs)];
                this.params_idx.alpha = alpha_idx;
            end
        end

        function [loss, errs, ir, info] = calc_loss(this,meas,...
            model, varinput, varargin)
            if meas.isKey('arc') & ~isempty(meas('arc'))
                [loss, errs, ir, info] = ...
                        this.calc_loss_arcs(meas, model, varinput, varargin{:});
            end
            if 0 & meas.isKey('rgn') & ~isempty(meas('rgn'))
                [info.rgn.loss, info.rgn.errs,...
                 info.rgn.ir, info.rgn.info] = ...
                        this.calc_loss_rgns(meas, model, varinput,...
                                            varargin{:});
            end
        end

        function [loss, errs, ir, info] = calc_loss_rgns(this,meas,...
            model, varinput, varargin)
            rgnd = meas('rgn');
            xd = rgnd(:,this.rgn_csponds(1,:));
            xdp = rgnd(:,this.rgn_csponds(2,:));

            rgn = RP2.backproject_div(RP2.mtimesx(inv(model.K),rgnd),[],model.proj_params);
            x = rgn(:,this.rgn_csponds(1,:));
            xp = rgn(:,this.rgn_csponds(2,:));

            N = size(x,2);
            vpidx = nchoosek(1:3,2);
            ssq_err = inf(6,N);
            for k=1:3
                u = model.R(:,vpidx(k,1));
                v = model.R(:,vpidx(k,2));
                l = cross(u,v);
                
                su = p1p_ct_to_scale(x(4:6,:),xp(4:6,:),u,l);
                su = permute(su,[3 1 2]);
                Hu = repmat(eye(3,3),1,1,N)+su.*repmat(u*l',1,1,N);
                xfer_sqerr = calc_xfer_err(x,xp,xd,xdp,model.K,model.proj_params,Hu);
                ssq_err(2*k-1,:) = sum(xfer_sqerr);

                sv = p1p_ct_to_scale(x(4:6,:),xp(4:6,:),v,l);
                sv = permute(sv,[3 1 2]);
                Hv = repmat(eye(3,3),1,1,N)+sv.*repmat(v*l',1,1,N);
                xfer_sqerr = calc_xfer_err(x,xp,xd,xdp,model.K,model.proj_params,Hv);
                ssq_err(2*k,:) = sum(xfer_sqerr);
            end
            [ssq_err, idx] = min(ssq_err);
            Gvl = ceil(idx/2);
            Gvp = vpidx(sub2ind(size(vpidx),Gvl,2-mod(idx,2)));
            cs = ssq_err < 3 * this.reprojT_rgn.^2;
            ssq_err(~cs) = 3 * this.reprojT_rgn.^2;
            ir = sum(cs)/numel(cs);
            Gvl(~cs) = NaN;
            Gvp(~cs) = NaN;
            
            loss0 = sum(ssq_err(~cs));
            loss = sum(ssq_err);
            errs = sqrt(ssq_err./3);

            info = struct('cspond', this.rgn_csponds, ...
                          'Gvp', Gvp, ...
                          'Gvl', Gvl, ...
                          'cs', cs,...
                          'loss0',loss0);
        end

        function [loss, errs, ir, info] = calc_loss_arcs(this,meas,...
            model, varinput, varargin)
            cfg.alpha = [];
            cfg.cs = [];
            cfg.Gvp = [];
            cfg = cmp_argparse(cfg, varargin{:});
            if ~isempty(cfg.cs)
                cfg.cs = find(cfg.cs);
            end
            arcs = meas('arc');
            c = varinput('arc');
            x_arc = [arcs{:}];
            arc_idx = repelem(1:numel(arcs),this.arc_sizes);
            reprojT_arc = this.reprojT_arc.^2.*this.arc_sizes;

            % Find best circles through vps
            x_mid = repmat(RP2.backproject_div(RP2.homogenize(c(4:5,:)),model.K,model.proj_params),1,1,3);
            m = cross(x_mid,repmat(reshape(model.K*model.R,3,1,3),1,size(x_mid,2),1));
            m = reshape(m,3,[]);
            circ = LINE.project_div(m,model.K,model.proj_params);
            circ = reshape(circ,3,[],3);

            dx = vecnorm(x_arc(1:2,:)-circ(1:2,arc_idx,:),2,1);
            dr2 = (dx-circ(3,arc_idx,:)).^2; % distances
            dr2 = splitapply(@sum,dr2,arc_idx); % sum sq. distances
            [ssq_err,w] = min(dr2,[],3);

            cs = ssq_err <= reprojT_arc;
            this.params_idx.alpha = this.params_idx.R(end)+[1:3*sum(cs)];
            ir = sum(cs)/numel(cs);
            ssq_err(~cs) = this.reprojT_arc.^2.*this.arc_sizes(~cs);
            loss0 = sum(ssq_err(~cs));
            
            w2 = (0:size(circ,2)-1)*9+(w-1).*3+[1:3]';
            circ2 = vstack(circ(:,:,1), circ(:,:,2), circ(:,:,3));
            circ = circ2(w2);
            
            % Recompute to remove numerical error
            w = w(cs);
            alpha = this.pack_circ(circ,model.K,model.R,model.proj_params);
            if ~isempty(cfg.alpha)
                alpha(:,cfg.cs) = cfg.alpha;
            end
            circ1 = this.unpack_circ(model.K,model.R,model.proj_params,alpha(:,cs));
            cs_idx = find(cs);
            circ = LINE.project_div(m,model.K,model.proj_params);
            circ = reshape(circ,3,[],3);
            for k=1:numel(w)
                circ(:,cs_idx(k),w(k)) = circ1(:,k,w(k));
            end
            dx = vecnorm(x_arc(1:2,:)-circ(1:2,arc_idx,:),2,1);
            dr2 = (dx-circ(3,arc_idx,:)).^2; % distances
            dr2 = splitapply(@sum,dr2,arc_idx); % sum sq. distances
            [ssq_err,w] = min(dr2,[],3);

            cs = ssq_err <= reprojT_arc;
            ir = sum(cs)/numel(cs);
            ssq_err(~cs) = this.reprojT_arc.^2.*this.arc_sizes(~cs);
            loss0 = sum(ssq_err(~cs));
            
            w2 = (0:size(circ,2)-1)*9+(w-1).*3+[1:3]';
            circ2 = vstack(circ(:,:,1), circ(:,:,2), circ(:,:,3));
            circ = circ2(w2);

            % Calculate residual on inliers
            if ir~=0
                arcs_cs = arcs(cs);
                x_arc_cs = [arcs_cs{:}];
                arc_idx_cs = repelem(1:sum(cs),this.arc_sizes(cs));
                this.params_idx.alpha = this.params_idx.R(end)+[1:3*sum(cs)];

                [dz0,z0] = this.pack(model, alpha(:,cs));
                [~,dr] = this.calc_residual(dz0,z0,[],[],x_arc_cs,w(cs),arc_idx_cs,this.arc_sizes(cs));
                ssq_err(cs)=splitapply(@sum,sum(dr.^2,[1 3]),arc_idx_cs);
                
                loss1 = sum(dr(:).^2);
            else
                loss1 = 0;
            end
            loss = loss0 + loss1;

            errs = sqrt(ssq_err./this.arc_sizes);
            info = struct('circ', circ(:,cs),...
                          'alpha', alpha(:,cs),...
                          'Gvp', w(cs), ...
                          'cs', cs,...
                          'loss0',loss0);
        end

        function [residual, dr] = calc_residual(this,dz,z0,x,xp,x_arc,w,arc_idx, arc_sizes)
            [M, alpha] = this.unpack(dz,z0);
            K = M.K;
            R = M.R;
            proj_params = M.proj_params;

            circ = this.unpack_circ(K,R,proj_params,alpha);
            dx = vecnorm(x_arc(1:2,:)-circ(1:2,arc_idx,:),2,1);
            dr = (x_arc(1:2,:)-circ(1:2,arc_idx,:)).*...
                 (1-circ(3,arc_idx,:)./dx);
            w_pts = repelem(w,arc_sizes);
            w_one_hot = reshape(1:3,1,1,3)==w_pts;
            dr = w_one_hot.*dr;
            residual = dr(:);
        end
        
        function [model,res,stats] = fit(this,meas,model0,res0,varinput,varargin)
            cfg.MaxIter = this.MaxIter;
            [cfg,~] = cmp_argparse(cfg,varargin{:});
            if meas.isKey('rgn') & ~isempty(meas('rgn'))
                rgn = meas('rgn');
                x = rgn(:,this.rgn_csponds(1,:));
                xp = rgn(:,this.rgn_csponds(2,:));
            else
                x = [];
                xp = [];
            end
            if meas.isKey('arc') & ~isempty(meas('arc'))
                arcs = meas('arc');
                cs = res0.info.cs;
                arcs = arcs(cs);
                x_arc_cs = [arcs{:}];
                alpha0 = res0.info.alpha;
                w0 = res0.info.Gvp;
                arc_idx_cs = repelem(1:sum(cs),this.arc_sizes(cs));
                this.params_idx.alpha = this.params_idx.R(end)+[1:3*sum(cs)];
            else
                x_arc_cs = [];
                alpha0 = [];
                w0 = [];
            end

            fprintf('Starting non-linear refinement (%3.2f%% inliers) after %s.\n', sum(cs)/numel(cs)*100, res0.solver);

            common_params = {'Display', 'iter', ...
                             'MaxIter', cfg.MaxIter, ...
                             'MaxFunEvals', 1e6};
            Jpat = this.make_Jpat(w0, this.arc_sizes(cs));
            if ~isempty(Jpat)
                common_params = cat(2,common_params, ...
                                    'JacobPattern', Jpat);
            end
            options = optimoptions(@lsqnonlin, ...
                                   common_params{:});
            

            [dz0,z0] = this.pack(model0,alpha0);
            calc_residual_fn = @(dz,z0,x,xp,x_arc,w,arc_idx,arc_sizes) this.calc_residual(dz,z0,x,xp,x_arc,w,arc_idx,arc_sizes);
            [dz,~,dr] = lsqnonlin(calc_residual_fn,dz0,[],[],options,z0,x,xp,x_arc_cs,w0,arc_idx_cs,this.arc_sizes(cs));
            cs_loss = sum(dr.^2);
            loss = res0.info.loss0 + cs_loss;
            dr = reshape(dr,[2,size(x_arc_cs,2),3]);
            ssq_err=splitapply(@sum,sum(dr.^2,[1 3]),arc_idx_cs);
            errs = res0.errs;
            errs(cs) = sqrt(ssq_err./this.arc_sizes(cs));

            assert(loss <= res0.loss, ...
                   'Local optimization increased the loss.');

            [model,alpha] = this.unpack(dz,z0);
            circ = this.unpack_circ(model.K,model.R,model.proj_params,alpha);
            w2 = (0:size(circ,2)-1)*9+(w0-1).*3+[1:3]';
            circ2 = vstack(circ(:,:,1), circ(:,:,2), circ(:,:,3));
            circ = circ2(w2);

            loss_info = struct('min_model', model0, ...
                               'min_res', res0, ...
                               'circ', circ,... % only cs
                               'alpha', alpha,... % only cs
                               'Gvp', w0, ... % only cs
                               'cs', cs,...
                               'loss0', res0.info.loss0);
            res = struct('loss', loss, ...
                         'errs', errs,...
                         'ir', sum(cs)/numel(cs), ...
                         'dz', dz, ...
                         'info', loss_info);
        end

        function [model, alpha] = unpack(this,dz,z0)
            if isempty(dz)
                dz = zeros(size(z0));
            end
            z = z0+dz;
            proj_params = z(this.params_idx.proj_params)';
            f = z(this.params_idx.f);
            K = diag([f f 1]);
            R = rotationVectorToMatrix(z(this.params_idx.R)); 
            model = struct('proj_params', proj_params, ...
                           'K', K, ...
                           'R', R);
            alpha = reshape(z(this.params_idx.alpha),3,[]);
        end
                
        function [dz,z0,z] = pack(this, model, alpha)
            z0 = zeros(this.params_idx.alpha(end),1); 
            dz = z0;
            z0(this.params_idx.proj_params) = model.proj_params;
            z0(this.params_idx.f) = model.K(1,1);
            z0(this.params_idx.R) = rotationMatrixToVector(model.R);
            z0(this.params_idx.alpha) = reshape(alpha,1,[]);
            z = z0+dz;
        end

        function Jpat = make_Jpat(this, w1, arc_sizes)
            w = repelem(w1,arc_sizes);
            w_one_hot = reshape(1:3,1,1,3)==w;
            w_one_hot = repmat(w_one_hot,2,1,1);
            w_one_hot = w_one_hot(:);
            arc_idx = repelem(1:numel(arc_sizes),arc_sizes);
            arc_idx = repmat(arc_idx,2,1,3);
            arc_idx = arc_idx(:);
            Jpat = zeros(numel(w_one_hot),this.params_idx.alpha(end));
            for k=1:numel(arc_sizes)
                kk = this.params_idx.alpha((k-1)*3+w1(k));
                Jpat(w_one_hot & arc_idx==k,[1:this.params_idx.alpha(1)-1 kk]) = 1;
            end
        end
    end
end