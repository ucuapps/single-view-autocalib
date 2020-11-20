classdef CspondCs < Cs & handle
    methods
        function this = CspondCs(varargin)
        end
        
        function p = calc_inlier_ratio(this,cs,varargin)
            p = this.calc_pjoint_inlier(cs,2);
        end
        
        function pjoint_inlier = calc_pjoint_inlier(this,cs,mss)
            assert(all(mss == 2), ...
                   'These are not correspondences!');
            pjoint_inlier = (sum(cs)/numel(cs))^numel(mss);
        end
    end 
end