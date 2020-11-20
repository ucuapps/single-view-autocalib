classdef c5 < WRAP.DivisionSolver
    % Estimated parameters: q u1 u2

    properties
        param_idx = [1];
        input_configs = [];
        input_dirs = [];
    end

    methods(Static)

        function M = solve(c, arcs)
            M = [];
            
            tic
            [q,~,u,v] = c5_to_qlu(c(4:7,:));         
            soltime = toc;
            soltime = soltime*ones(size(q));
            uv = [u;v];
            valid = WRAP.DivisionSolver.valid_q(q);
            q = real(q(valid));
            uv = real(uv(:,valid));
            soltime = soltime(valid);
            consistency = eval_min_hybrid(q,uv,[],arcs,c);

            if ~isempty(q)
                vp = reshape(uv,3,[]);
                M = struct(...
                'proj_params', mat2cell(q,1,ones(size(q))), ...
                'vp', squeeze(mat2cell(vp,3,2*ones(size(q)))),...
                'pp', [0; 0],...
                'consistency',...
                    mat2cell(consistency,2,ones(size(q))),...
                'solver_time', soltime);
            end
        end
    end

    methods
        function this = c5(varargin)
            mss = containers.Map();
            mss('arc') = [5];
            this = this@WRAP.DivisionSolver(mss);

            cfg1 = containers.Map({'arc'},{[3 2]});
            cfg2 = containers.Map({'arc'},{[3 1 1]});
            this.input_configs = {cfg1, cfg2};
            this.input_dirs = {{[1;0],[0;1]},...
                               {[1;0],[0;1],[0;0]}};
            this.name = 'Wildenauer';
        end

        function M = fit(this, meas, idx, varinput)
            arcs = meas('arc');
            c = varinput('arc');
            if ~isempty(idx)
                cIdx = idx('arc');
                c = c(:,[cIdx{:}]);
                arcs = arcs([cIdx{:}]);
            end
            M = this.solve(c, arcs);
        end
    end
end