classdef Mserm < MSER.CFG.Mser
	properties(Access=private,Constant)
        uname = 'Mserm';
    end

    methods 
        function this = Mserm(varargin)
            this@MSER.CFG.Mser(varargin{:});
        end

        function uname = get_uname(this)
            uname = MSER.CFG.Mserm.uname;
        end
    end
end