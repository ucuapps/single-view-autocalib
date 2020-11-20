% Copyright (c) 2017 James Pritts
% 
classdef laf22_to_qluv < WRAP.DivisionSolver
    properties
        param_idx = [1];
        solver_impl = [];
        input_configs = {};
        input_dirs = {};
    end
    
    methods
        function this = laf22_to_qluv(solver_type)
            if nargin < 1
                solver_type = 'det';
            end
            mss = containers.Map();
            mss('rgn') = [2 2];
            this = this@WRAP.DivisionSolver(mss);
            this.solver_impl = ...
                WRAP.pt4x2_to_qluv('solver',solver_type);
            this.name = 'EVP';
            this.input_configs = {mss};
            this.input_dirs = {{[1;0],[0;1]}};
        end
        
        function M = fit(this,x,idx,varargin)
            x = x('rgn');
            if ~isempty(idx)
                idx = idx('rgn');
                x = x(:,[idx{:}]);
            end
            xp = [x(1:3,1:2) x(4:6,1:2) x(1:3,3:4) x(4:6,3:4)];
            try
                M = this.solver_impl.fit(xp, ...
                                    mat2cell([1 3 5 7;2 4 6 8], ...
                                    2,ones(1,4)));
            catch
                M = [];
            end
        end
    end
end
