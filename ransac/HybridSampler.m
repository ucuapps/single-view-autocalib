classdef HybridSampler < handle
    properties
        min_trial_count = 1e2;
        max_trial_count = 1e4;
        max_num_retries = 2e2;
        
        sampler_list = {};
        
        confidence = 0.99;
        
        Ks = [];
        Ps = [];        
        Pp = [];
        P = [];
        trial_count = [];
        
        valid_idx = [];
        num_valid = 0;

        display = true;

        solvers = [];
        cs_map = [];
    end

    methods
        function this = HybridSampler(solvers, priors,...
                                      groups, cs_map,...
                                      varargin)
            this.solvers = solvers;
            this.cs_map = cs_map;
            kSolvers = numel(solvers);
            kPriors = numel(priors);
            assert(kPriors == kSolvers);

            if isempty(priors)
                priors = ones(1,numel(solvers));
            end
            priors = priors ./ sum(priors);
            this.Pp = zeros(1,kPriors);
            
            [this, ~] = cmp_argparse(this, varargin{:});
            
            if numel(this.min_trial_count)==1
                this.min_trial_count = this.min_trial_count .* ones(1,numel(solvers));
            else
                assert(numel(this.min_trial_count) == kSolvers);
            end
            if numel(this.max_trial_count)==1
                this.max_trial_count = this.max_trial_count .* ones(1,numel(solvers));
            else
                assert(numel(this.max_trial_count) == kSolvers);
            end
            
            for k = 1:kSolvers
                if HybridSampler.is_solver_valid(groups,solvers(k))
                    this.sampler_list{k} =...
                        LabelSampler(solvers(k).mss,...
                                           groups, varargin{:});
                    this.Pp(k) = priors(k);
                else
                    this.min_trial_count(k) = 0;
                    this.max_trial_count(k) = 0;
                end
            end

            this.Pp = this.Pp/sum(this.Pp);
            this.P = this.Pp;
            this.Ks = inf(1,kSolvers);
            this.Ps = ones(1,kSolvers)/kSolvers;
            this.trial_count = zeros(1,kSolvers);
        end

        function [solver_idx, hybrid_idx,trial_count] = sample(this,meas, ...
                                                              varargin)

            solver_idx = [];
            hybrid_idx = [];

            if ~isempty(this.sampler_list)
                solver_idx = find(mnrnd(1,this.P,1));
                assert(numel(solver_idx)==1);
            
                this.trial_count(solver_idx) = this.trial_count(solver_idx)+1;
                hybrid_idx = ...
                    this.sampler_list{solver_idx}.sample(meas, varargin);
                ind = this.trial_count >= this.max_trial_count;

                this.Pp(ind) = 0;
                this.P(ind) = 0;
                if nnz(this.Pp) > 0
                    this.Pp = this.Pp/sum(this.Pp);
                    this.P = this.P/sum(this.P);
                else
                    this.P = 0;
                end
            end
            
            trial_count = this.trial_count;
        end

        function [Ks,eKs] = update_trial_count(this,cs)
            plist = this.calc_pjoint_inlier(cs);
            ind = this.trial_count > this.min_trial_count;
            this.Ps(ind) = plist(ind).*(1-plist(ind)).^this.trial_count(ind)+eps;
            this.Ps(~ind) = plist(~ind)+eps;
            this.P = this.Ps.*this.Pp;
            
            if nnz(this.P) > 0
                this.P = this.P/sum(this.P);
            end
                
            Ks = round(log(1-this.confidence)./(log(1-plist)-eps));
            disp(['Estimated trial count: ' num2str(Ks)]);
            eKs = Ks;
            Ks = min([Ks; this.max_trial_count]);
            Ks = max([Ks; this.min_trial_count]);            

            disp(['Bounded trial count: ' num2str(Ks)]);
            this.Ks = Ks;

            assert(~any(isnan(this.P)));
            assert(all(isfinite(this.P)), 'Infinite Ps');
            assert(all(~isnan(this.P)), 'Ps is NaN');
            assert(all(this.Ks) >= 0, ...
                   'No. of trials needed is non-positive.');
        end

        function pjoint_list = calc_pjoint_inlier(this,cs)
            pjoint_list = nan(1,numel(this.solvers));
            for k = 1:numel(this.solvers)
                pk2 = [];
                for key = this.solvers(k).mss.keys
                    key = key{1};
                    if ~isempty(this.solvers(k).mss(key))
                        pk2 = [pk2...
                        this.cs_map(key).calc_pjoint_inlier(...
                            cs(key), this.solvers(k).mss(key))];
                    end
                end                
                pjoint_list(k) = prod(pk2);
            end
        end
        
        function stopit = is_enough(this)            
            no_valid_samplers = isempty(this.sampler_list);
            
            stopit = any(this.trial_count >= this.Ks) & ...
                     all(this.trial_count >= this.min_trial_count) ...
                     | no_valid_samplers ;
            
        end
    end

    methods(Static)
        function is_valid = is_solver_valid(G,solver)
            keys = solver.mss.keys;
            
            num_available = ...
                cellfun(@(x) sort(hist(x,1:max(x)),'descend'),...
                        G.values(keys), 'UniformOutput', false); 
                
            cmss = ...
                cellfun(@(x,y) y(1:min(numel(y), numel(x))),...
                        solver.mss.values(keys),...
                        num_available,...
                        'UniformOutput', false);                 

            is_valid_solver =...
                cellfun(@(x,y) all(x <= y),...
                        solver.mss.values(keys), cmss);
            
            is_valid = all(is_valid_solver);
        end
    end
end