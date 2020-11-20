classdef HessianAffine < COVDET.CFG.AffPt
    properties(Access=private,Constant)
        uname = 'HessianAffine';
    end
    
    properties
        detector = 7;
    end

    methods 
        function this = HessianAffine(varargin)
            this@COVDET.CFG.AffPt(varargin{:});
        end
    end
    
    methods(Static)
        function uname = get_uname()
            uname = COVDET.CFG.HessianAffine.uname;
        end
    end
end