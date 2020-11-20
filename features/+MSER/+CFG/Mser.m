classdef Mser < CfgBase 
    properties(Access=private,Constant)
        uname = 'Mser';
    end

    properties(Access = public)
        verbose = 1;
        relative = 0;
        preprocess = 1;
        export_image = 1;
        min_size = 30;
        min_margin = 10;
        max_area = 0.01;
        use_hyst_thresh = 0;
        low_factor = 0.9;
        precise_border = 0;
        subsample_to_minsize = 0;
        chroma_thresh = 0.09;
        min_areadiff = 0.1;
        nms_method = 0;
    end

    methods
        function this = Mser(varargin)
            this = this@CfgBase(varargin{:});
            if ~isempty(varargin)
                this = cmp_argparse(this,varargin{:});
            end
        end

        function uname = get_uname(this)
            uname = MSER.CFG.Mser.uname;
        end
    end
end 