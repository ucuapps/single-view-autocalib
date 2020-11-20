classdef c6 < WRAP.DivisionSolver
    % Estimated parameters: q u1 u2 u3 

    properties
        param_idx = [1];
        input_configs = [];
        input_dirs = [];
    end

    methods(Static)
        function M = solve(c, arcs)
            M = [];
            q = [];
            uvw = [];
            soltime = [];
            consistency = [];

            %%%% Rectification from (2+2+2)CA
            tic
            [q1, ~, u1, v1, w1] = NP_MC_to_qlu([], c([4:7 11:14],:));
            soltime1 = toc;
            soltime1 = soltime1*ones(size(q1));
            uvw1 = [u1;v1;w1];
            valid = WRAP.DivisionSolver.valid_q(q1);
            q1 = real(q1(valid));
            uvw1 = real(uvw1(:,valid));
            soltime1 = soltime1(valid);
            q = [q q1];
            uvw = [uvw uvw1];
            soltime = [soltime soltime1];
            consistency = [consistency eval_min_hybrid(q1,uvw1,[],arcs,reshape(c,7,[]))];

            %%%% Auto-calibration from (2+2+2)CA
            tic
            [q1, u1, v1, w1] = NP_MC_to_qfu([], c([4:7 11:14],:));
            soltime1 = toc;
            soltime1 = soltime1*ones(size(q1));
            uvw1 = [u1;v1;w1];
            valid = WRAP.DivisionSolver.valid_q(q1);
            q1 = real(q1(valid));
            uvw1 = real(uvw1(:,valid));
            soltime1 = soltime1(valid);
            q = [q q1];
            uvw = [uvw uvw1];
            soltime = [soltime soltime1];
            consistency = [consistency eval_min_hybrid(q1,uvw1,[],arcs,reshape(c,7,[]))];

            if ~isempty(q)
                vp = reshape(uvw,3,[]);
                M = struct(...
                    'proj_params', mat2cell(q,1,ones(size(q))),...
                    'vp', squeeze(mat2cell(vp,3,3*ones(size(q)))),...
                    'pp', [0; 0],...
                    'consistency',...
                            mat2cell(consistency,2,ones(size(q))),...
                    'solver_time',mat2cell(soltime,1,ones(size(q)))); 
            end

            %%%% Rectification from (3+2)CA and
            %%%% auto-calibration from (3+1+1)CA
            q = [];
            uvw = [];
            soltime = [];
            consistency = [];
            cidx_configs = ...
                 [[1 2 3 4 5];[1 2 3 4 6];[1 2 3 5 6];...
                  [1 2 4 3 5];[1 2 4 3 6];[1 2 4 5 6];...
                  [1 2 5 3 4];[1 2 5 3 6];[1 2 5 4 6];...
                  [1 2 6 3 4];[1 2 6 3 5];[1 2 6 4 5];...
                  [1 3 4 2 5];[1 3 4 2 6];[1 3 4 5 6];...
                  [1 3 5 2 4];[1 3 5 2 6];[1 3 5 4 6];...
                  [1 3 6 2 4];[1 3 6 2 5];[1 3 6 4 5];...
                  [1 4 5 2 3];[1 4 5 2 6];[1 4 5 3 6];...
                  [1 4 6 2 3];[1 4 6 2 5];[1 4 6 3 5];...
                  [1 5 6 2 3];[1 5 6 2 4];[1 5 6 3 4];...
                  [2 3 4 1 5];[2 3 4 1 6];[2 3 4 5 6];...
                  [2 3 5 1 4];[2 3 5 1 6];[2 3 5 4 6];...
                  [2 3 6 1 4];[2 3 6 1 5];[2 3 6 4 5];...
                  [2 4 5 1 3];[2 4 5 1 6];[2 4 5 3 6];...
                  [2 4 6 1 3];[2 4 6 1 5];[2 4 6 3 5];...
                  [2 5 6 1 3];[2 5 6 1 4];[2 5 6 3 4];...
                  [3 4 5 1 2];[3 4 5 1 6];[3 4 5 2 6];...
                  [3 4 6 1 2];[3 4 6 1 5];[3 4 6 2 5];...
                  [3 5 6 1 2];[3 5 6 1 4];[3 5 6 2 4];...
                  [4 5 6 1 2];[4 5 6 1 3];[4 5 6 2 3];...
                   ];
            c1 = reshape(c,7,[]);
            c2 = reshape(c([4:7 11:14],:),4,[]);
            for k=1:size(cidx_configs,1)
                idx = cidx_configs(k,:);
                tic
                [q1, ~, u1, v1] = c32s_to_qlu(c2(:,idx));
                soltime1 = toc;
                soltime1 = soltime1*ones(size(q1));
                uvw1 = [u1;v1];
                valid = WRAP.DivisionSolver.valid_q(q1);
                q1 = real(q1(valid));
                uvw1 = real(uvw1(:,valid));
                soltime1 = soltime1(valid);
                q = [q q1];
                uvw = [uvw uvw1];
                soltime = [soltime soltime1];
                consistency = [consistency eval_min_hybrid(q1,uvw1,[],arcs(idx),c1(:,idx))];
            end
            if ~isempty(q)
                vp = reshape(uvw,3,[]);
                M = [M struct(...
                    'proj_params', mat2cell(q,1,ones(size(q))),...
                    'vp', squeeze(mat2cell(vp,3,2*ones(size(q)))),...
                    'pp', [0; 0],...
                    'consistency',...
                            mat2cell(consistency,2,ones(size(q))),...
                    'solver_time',mat2cell(soltime,1,ones(size(q))))];
            end
        end
    end

    methods
        function this = c6()
            mss = containers.Map();
            mss('arc') = [6];
            this = this@WRAP.DivisionSolver(mss);

            cfg1 = containers.Map({'arc'},{[2 2 2]});
            cfg2 = containers.Map({'arc'},{[2 2 2]});
            cfg3 = containers.Map({'arc'},{[3 2 1]});
            this.input_configs = {cfg1, cfg2, cfg3};
            this.input_dirs = {{[1;0],[0;1],[0.2;0.3]},...
                               {[1;0],[0;1],[0;0]},...
                               {[1;0],[0;1],[0.2;0.3]},...
                              };
            this.name = 'Solver6CA';
        end

        function M = fit(this, meas, idx, varinput)            
            arcs = meas('arc');
            c = varinput('arc');
            if ~isempty(idx)
                cIdx = idx('arc');
                c = c(:,[cIdx{:}]);
                arcs = arcs(:,[cIdx{:}]);
            end
            c = reshape(c, 14, []);
            M = this.solve(c, arcs);
        end
    end
end