% Copyright (c) 2017 James Pritts
% 
classdef HybridRansac < handle
    properties 
        solvers
        sampler
        eval
        lo
        display = true
        display_freq = 50;
        irT = 0;
    end
    
    methods
        function this = HybridRansac(solvers,sampler,eval,lo,varargin)
            this = cmp_argparse(this, varargin{:});

            this.solvers = solvers;
            this.sampler = sampler;
            this.eval = eval;
            if nargin < 4
                this.lo = [];
            else
                this.lo = lo;
            end
        end
        
        function [loM,lo_res,lo_stats] = do_lo(this,meas,M,res,varargin)
            loM = [];
            lo_res = [];
            if ~isempty(this.lo)
                [loM,lo_res] = this.lo.fit(meas,M,res,varargin{:});
            end
        end

        function  [optM,opt_res,stats] = fit(this,meas,varargin)
            tic;
            stats = struct('time_elapsed', 0, ...
                           'trial_count', zeros(1,numel(this.solvers)), ...
                           'max_trial_count', this.sampler.max_trial_count,...
                           'sample_count', 0, ...
                           'model_count', 0, ...
                           'local_list', [], ...
                           'global_list', []);

            res = struct('loss', inf, 'ir', 0);

            optM = [];
            lo_res = res;
            opt_res = res;
            
            has_model = false;
            while true
                for k = 1:this.sampler.max_num_retries
                    [solver_idx,idx,stats.trial_count] = this.sampler.sample(meas);
                    if this.display & mod(sum(stats.trial_count), this.display_freq)==0
                        disp(['Trial '  num2str(stats.trial_count) ' out of ' num2str(stats.max_trial_count)]);
                    end
                    solver = this.solvers(solver_idx);
                    is_sample_good = ...
                        solver.is_sample_good(meas,idx,varargin{:});
                    if is_sample_good
                        model_list = solver.fit(meas,idx,varargin{:});
                        if ~isempty(model_list)
                            has_model = true;
                            break;
                        end
                    end
                end

                if ~(is_sample_good & has_model)
                    optM = [];
                    opt_res = [];
                    stats = [];
                    return
                end
                
                stats.sample_count = stats.sample_count+k;
                is_model_good = false(1,numel(model_list));

                for k = 1:numel(model_list)
                    is_model_good(k) = ...
                        solver.is_model_good(meas,idx,model_list(k),varargin{:});
                end

                model_list = model_list(is_model_good);

                if ~isempty(model_list)
                    stats.model_count = stats.model_count+numel(model_list);
                    loss = inf(numel(model_list),1);
                    for k = 1:numel(model_list)
                        [loss(k),errs{k},ir{k},loss_info{k}] = ...
                            this.eval.calc_loss(meas,model_list(k), ...
                                                varargin{:});

                    end
                    [~,mink] = min(loss);
                    M0 = model_list(mink);
                    res0 = struct('errs', errs{mink}, ...
                                  'loss', loss(mink), ...
                                  'ir', ir{mink}, ...
                                  'solver', this.solvers(solver_idx).name,...
                                  'info', loss_info(mink), ...
                                  'mss', {idx});
                    if (res0.ir > this.irT) && ...
                       (res0.ir >= res.ir) && ...
                       (res0.loss < res.loss)
                        M = M0;
                        res = res0;
                        stats.global_list = cat(2,...
                        stats.global_list, ...
                         struct('model',M, ...
                                'res',res, ...
                                'model_count', stats.model_count, ...
                                'trial_count', stats.trial_count));
                        if res.loss < opt_res.loss
                            optM = M;
                            opt_res = res;
                        end
                        if ~isempty(this.lo)
                            [loM,lo_res] = this.do_lo(meas,M,res,varargin{:});
                            lo_stats = struct(...
                                'model',loM, ...
                                'res',lo_res, ...
                                'trial_count',stats.trial_count, ...
                                'model_count',stats.model_count);
                            if (lo_res.loss <= opt_res.loss)
                                stats.local_list = cat(2,stats.local_list,lo_stats);
                                optM = loM;
                                opt_res = lo_res;
                            end
                        end
                    
                        cs=containers.Map({'arc'},{opt_res.info.cs});

                        if meas.isKey('rgn') & ~isempty(meas('rgn'))
                            [opt_res.rgn.loss, opt_res.rgn.errs, opt_res.rgn.ir, opt_res.rgn.info] = ...
                                this.eval.calc_loss_rgns(meas, optM, varargin{:});
                            cs('rgn') = opt_res.rgn.info.cs;
                        end                        
                        stats.max_trial_count = this.sampler.update_trial_count(cs);
                    end   
                end

                if (any(stats.trial_count > stats.max_trial_count))
                    break;
                end
            end

            if ~isempty(optM)
                min_model = opt_res.info.min_model;
                min_res = opt_res.info.min_res;

                [loss,errs,ir,loss_info] = ...
                        this.eval.calc_loss(meas,optM,varargin{:});
                res0 = struct('errs', errs, ...
                            'loss', loss, ...
                            'ir', ir, ...
                            'solver', min_res.solver,...
                            'info', loss_info);
                if (res0.ir > this.irT) && (res0.ir >= res.ir) && ...
                (res0.loss < res.loss)
                    M = optM;
                    res = res0;
                    if res.loss < opt_res.loss
                        optM = M;
                        opt_res = res;
                    end
                    if ~isempty(this.lo)
                        [loM,lo_res] = this.do_lo(meas,M,res,varargin{:},'MaxIter',100);
                        lo_stats = struct(...
                            'model',loM, ...
                            'res',lo_res, ...
                            'trial_count',stats.trial_count, ...
                            'model_count',stats.model_count);
                        if (lo_res.loss <= opt_res.loss)
                            stats.local_list = cat(2,stats.local_list,lo_stats);
                            optM = loM;
                            opt_res = lo_res;
                        end
                    end
                    opt_res.info.min_model = min_model;
                    opt_res.info.min_res = min_res;
                end
            end

            stats.time_elapsed = toc;               
        end
    end
end