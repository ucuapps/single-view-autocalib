classdef DistinctAffPt < CfgBase 
    properties(Access=private,Constant)
        uname = 'DistinctAffPt';
    end

    properties(Access=public)
        acute = 1/10*pi
        oblique = 9/10*pi
        ovthresh = 0.1
        min_laf_scale 
    end
    
    methods
        function this = DistinctAffPt(min_size,varargin)
            this = this@CfgBase(varargin{:});
            if nargin < 1
                min_size = 0;
            end
            if ~isempty(varargin)
                if numel(varargin) > 1
                    [this,~] = cmp_argparse(this,varargin{:});
                elseif isa(varargin{1},'COVDET.CFG.DistinctAffPt')
                    this = copy(varargin{1});
                end
            end
            this.min_laf_scale = min_size;
        end

        function uname = get_uname(this)
            uname = COVDET.CFG.DistinctAffPt.uname;
        end
    end
end 