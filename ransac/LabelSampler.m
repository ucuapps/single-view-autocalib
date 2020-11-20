%  Written by James Pritts
%
classdef LabelSampler < handle
    properties
        min_trial_count = 1e2;
        max_trial_count = 1e4;
        max_num_retries = 2e2;
        confidence = 0.99
        N

        freq_map = containers.Map();
        mss_map = containers.Map();
        pmap = MapNested();

        G = [];
        G2 = []; % Hierarchical grouping
    end
    
    methods
        function this = LabelSampler(mss_map, G, varargin)
            [this,~] = cmp_argparse(this, varargin{:});
            keys = mss_map.keys;

            num_available =...
                cellfun(@(x) sort(hist(x,1:max(x)), 'descend'),...
                        G.values(keys), 'UniformOutput',false);
            cmss_map =...
                cellfun(@(x,y) y(1:min(numel(y),numel(x))),...
                        mss_map.values(keys), num_available,...
                            'UniformOutput', false);
            is_valid =...
                all(cellfun(@(x,y) all(x <= y),...
                    mss_map.values(keys), cmss_map));
                       
            if is_valid
                this.G = containers.Map(keys,...
                                cellfun(@(x) findgroups2(x),...
                                        G.values(keys), ...
                                        'UniformOutput', false));
                if isempty(this.G2)
                    this.G2 = containers.Map(keys,...
                        cellfun(@(x) [], G.values(keys), ...
                            'UniformOutput', false));
                end
                this.freq_map = containers.Map(keys,...
                                cellfun(@(x) hist(x,1:max(x)),...
                                         this.G.values(keys), ...
                                         'UniformOutput', false));
                this.mss_map = mss_map;
                umss_map = containers.Map(keys,...
                                cellfun(@(x) unique(x),...
                                this.mss_map.values(keys), ...
                                'UniformOutput', false));
                for key=keys
                    key = key{1};
                    umss = umss_map(key);
                    freq = this.freq_map(key);
                    for k2 = 1:numel(umss)
                        this.pmap(key, umss(k2)) = calc_pmap(freq, umss(k2));
                    end
                end
            end
        end
        
        function idx_map = sample(this, meas, varargin)
            idx_map = containers.Map();
            for key = this.pmap.keys
                key = key{1};
                idx_map(key) = ...
                LabelSampler.sample_token(...
                            this.G(key), ...
                            this.mss_map(key), ...
                            this.pmap(key), ...
                            this.G2(key));
            end
        end

        function N = update_trial_count(this, inliers)
            mss = this.mss_map('arc');
            n = sum(mss);
            w = sum(inliers) / numel(inliers);
            N = round(log(1-this.confidence) / log(1-w^n));
            N = max(this.min_trial_count,...
                    min([N, this.max_trial_count]));
        end
    end

    methods(Static)
        function idx = sample_token(G, mss, pmap, G2)
            [smss,inda] = sort(mss);
            [Gmss,id] = findgroups(findgroups(smss));
            idx = {};
            s = [];
            pmap_ = pmap;
            for k=Gmss
                x = smss(Gmss==k);
                s_ = mnrnd_without_repeat(numel(x),pmap_(x(1)),1);
                s = [s {s_}];
                for k2=smss
                    p = pmap_(k2);
                    p(find(s_)) = 0;
                    pmap_(k2) = p;
                end
            end

            k3 = 1;
            for k = 1:numel(id)
                labels = s{k};
                ind = find(labels);
                replabel = repelem(ind,labels(ind));
                for k2 = 1:numel(replabel)
                    good_idx = find(G == replabel(k2));
                    if nargin < 4 || isempty(G2)
                        perm_idx = randperm(numel(good_idx), smss(k));
                    else
                        G2_ = unique(G2(good_idx));
                        perm_idx = G2_(randperm(numel(G2_), smss(k)));
                        perm_idx = arrayfun(@(x) randsample(...
                            find(G2(good_idx) == x), 1), perm_idx);
                    end
                    selected_idx = good_idx(perm_idx);
                    idx{k3} = selected_idx;
                    k3 = k3+1;
                end
            end
            idx(inda) = idx;
        end
    end
end 


function G = findgroups2(G)
    if ~isempty(G)
        G = findgroups(G);
    end
end