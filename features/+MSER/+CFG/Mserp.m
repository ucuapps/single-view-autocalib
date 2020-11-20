classdef Mserp < MSER.CFG.Mser
	properties(Access=private,Constant)
        uname = 'Mserp';
    end

    methods 
        function this = Mserp(varargin)
            this@MSER.CFG.Mser(varargin{:});
        end

        function uname = get_uname(this)
            uname = MSER.CFG.Mserp.uname;
        end
    end
end