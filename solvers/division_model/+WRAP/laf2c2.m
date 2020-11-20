classdef laf2c2 < WRAP.DivisionSolver
    % Estimated parameters: q u1 u2 u3

    properties
        param_idx = [1];
        solver_impl = [];
        input_configs = [];
        input_dirs = [];
    end

    methods
        function this = laf2c2()
            mss = containers.Map({'rgn','arc'}, {[2],[2]});
            this = this@WRAP.DivisionSolver(mss);

            cspond = { [[1 4]' [2 5]' [3 6]'], ...
                       [[1 2]' [4 5]'], ...
                       [[1 3]' [4 6]'], ...
                       [[2 3]' [5 6]'] };

            this.solver_impl = WRAP.p2x4c2('cspond', cspond);

            cfg2 = containers.Map({'rgn','arc'}, {[2],[1 1]});
            this.input_configs = {mss, cfg2};
            this.input_dirs = {{[1;0],[0;1]},...
                               {[1;0],[0;1],[0;0]}};
            this.name = 'Solver4PC2CA';
        end

        function M = fit(this, meas, idx, varinput)
            x = meas('rgn');
            arcs = meas('arc');
            c = varinput('arc');
            if ~isempty(idx)
                xIdx = idx('rgn');
                cIdx = idx('arc');

                x = x(:,[xIdx{:}]);
                c = c(:,[cIdx{:}]);
                arcs = arcs(:,[cIdx{:}]);
            end
            M = this.solver_impl.fit(x, c, arcs);
        end
    end
end