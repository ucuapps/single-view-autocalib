
classdef fRUpgrade < WRAP.Solver & dynamicprops
    properties
        rect_solver = [];
        proj_model = 'div';
        reprojT_rgn = inf;
        reprojT_arc = inf;
    end

    methods
        function this = fRUpgrade(solver)
            this = this@WRAP.Solver(solver.mss);
            prop = properties(solver);
            for k1 = 1:numel(prop)
                p = prop(k1);
                try
                    this.addprop(p{1});
                end
                this.(p{1}) = solver.(p{1});
            end
            this.rect_solver = solver;
        end

        function models = fit(this, meas, idx, varinput, varargin)
            cfg = struct('reprojT_rgn',this.reprojT_rgn,...
                         'reprojT_arc',this.reprojT_arc);
            [cfg,varargin] = cmp_argparse(cfg,varargin{:});
            models0 = this.rect_solver.fit(meas, idx, varinput, varargin{:});
            norm_fn = str2func(['CAM.normalize_' this.proj_model]);
            backproj_fn = str2func(['RP2.backproject_' this.proj_model]);
            models = [];
            if ~isempty(models0)

                if isfield(models0,'consistency')
                    msqerrs = [models0(:).consistency];
                    ix = (msqerrs(1,:)<=cfg.reprojT_rgn^2 |...
                        isnan(msqerrs(1,:)))&...
                        (msqerrs(2,:)<=cfg.reprojT_arc^2 |...
                        isnan(msqerrs(2,:)));
                    w = 1/32;
                    K = 10;
                    K = min(numel(ix),K);
                    wmsqerrs = nanmean(2/(1+w)*msqerrs.*[w;1]);
                    [~,ix2] = sort(wmsqerrs);
                    models0=models0(ix&sum(1:numel(ix2)==ix2(1:K)'));
                end

                for k1 = 1:numel(models0)
                    model = models0(k1);
                    proj_params = model.proj_params;
                    vp = model.vp;
                    pp = model.pp;
                    pairs = nchoosek(1:size(vp,2),2);
                    f_list = [];
                    R_list = {};
                    for k2=1:size(pairs,1)
                        %%% Focal length + orientation wrt plane
                        u = vp(:,pairs(k2,1));
                        v = vp(:,pairs(k2,2));
                        [f, R] = uv_to_fR(u, v);
                        valid_f_idx = find(WRAP.fRUpgrade.valid_f(f));
                        f = real(f(valid_f_idx));
                        R = cellfun(@(r) real(r), R(valid_f_idx),...
                                            'UniformOutput',false);
                        f_list = [f_list f];
                        R_list = {R_list{:} R{:}};
                    end
                    K = arrayfun(@(f) [diag([f, f]) pp; 0 0 1], f_list,'UniformOutput',false);
                    R = R_list;

                    for k2=1:numel(K)
                        M = struct();
                        M.proj_params = norm_fn(proj_params, K{k2});
                        M.K = K{k2};
                        M.R = R{k2};
                        models = [models M];
                    end
                    models = WRAP.DivisionSolver.valid_models(models);
                end
            end
        end

        function res = verify_eqs(this, varargin)
            res = this.rect_solver.verify_eqs(varargin{:});
        end

        function flag = is_model_good(this, meas, idx, model, varargin)
            flag = this.valid_f(model.K(1,1)) & this.rect_solver.is_model_good(meas, idx, model, varargin{:});
        end
    end

    methods(Static)
        function flag = valid_f(f)
            flag = abs(imag(f)) < 1e-9 &...
                real(f) > 1e-9 &...
                real(f) < 10;
        end
    end
end 