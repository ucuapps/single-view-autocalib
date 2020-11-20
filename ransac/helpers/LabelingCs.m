classdef LabelingCs < Cs & handle
    properties
        G = [];
        freq = [];
        pmap = [];
    end
    
    methods
        function this = LabelingCs(G)
            this.G = G;
            this.freq = hist(this.G,1:max(this.G));
            this.pmap = containers.Map('KeyType', 'int32', ...
                                       'ValueType', 'any');
        end
        
        function inlier_ratio = calc_inlier_ratio(this,cs,mss)
            inlier_ratio = this.calc_pjoint_inlier(cs,mss);
        end
        
        function pjoint_inlier = calc_pjoint_inlier(this,cs,mss)
            if nargin < 3
                mss = 1;
            end
            cs = int32(cs);
            pk = nan(1,numel(mss));
            
            umss = unique(mss);
            for k = 1:numel(umss)
                if ~isKey(this.pmap,umss(k))
                    this.pmap(umss(k)) = calc_pmap(this.freq,umss(k));
                end
            end
            
            for k = 1:numel(mss)
                cs(find(cs==0)) = nan;
                mode_list = msplitapply(@(x) LabelingCs.get_mode(x), ...
                                        cs, this.G); 
                cs(cs ~= mode_list) = nan;
                inl_ratio = ...
                    cmp_splitapply(@(x) LabelingCs.calc_inl_ratio(x,mss(k)), ...
                                   cs,this.G);
                pk(k) = dot(this.pmap(mss(k)),inl_ratio);
            end
            pjoint_inlier = prod(pk);
        end
    end

    methods(Static)
        function inl_ratio = calc_inl_ratio(x,mss)
            num_valid = sum(~isnan(x));
            if num_valid >= mss && numel(x) >= mss
                inl_ratio = nchoosek(num_valid,mss)/nchoosek(numel(x),mss);
            else
                inl_ratio = 0;
            end
        end
        
        function mode_list = get_mode(x)
            mode_list = repmat(mode(x),1,numel(x));
        end
    end
end