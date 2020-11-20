classdef p2x4c2 < handle & WRAP.DivisionSolver
    % Estimated parameters: q u1 u2 u3

    properties
        param_idx = [1];
        cspond = [];
    end

    methods(Static)
        function M = solve(x, c, arcs)
            M = [];
            q = [];
            uvw = [];
            soltime = [];
            consistency = [];

            idx_configs = [1 2 4 5
                           2 3 5 6
                           1 3 4 6
                           1 4 2 5
                           1 4 3 6
                           2 5 3 6];
            idx_configs2 = [[1;4], [1;5], [1;6],...
                            [2;4], [2;5], [2;6],...
                            [3;4], [3;5], [3;6]];

            %%%% Rectification from (2+2)PC+2CA
            x_rgns = reshape(x, 18, []);
            for k=1:size(idx_configs2,2)
                idx1 = reshape((idx_configs...
                    (idx_configs2(1,k),:)-1).* 3 + [1;2;3],[],1);
                idx2 =reshape((idx_configs...
                    (idx_configs2(2,k),:)-1).* 3 + [1;2;3],[],1);
                tic
                [q1, ~, u1, v1, w1] = NP_MC_to_qlu([x_rgns(idx1,:) x_rgns(idx2,:)], c([4:7 11:14],:));
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
                consistency = [consistency eval_min_hybrid(q1,uvw1,x,arcs,reshape(c,7,[]))];
            end

            %%%% Rectification from 3PC+2CA and
            %%%% auto-calibration from 3PC+(1+1)CA
            idx = kron(([1 2 3; 4 5 6]-1) .* 3, [1;1;1]) + [1;2;3;1;2;3];
            c = reshape(c,7,[]);
            tic
            [q1, ~, u1, v1, w1] = NP3_MC_to_qlu(x_rgns(idx),c(4:7,:));
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
            consistency = [consistency eval_min_hybrid(q1,uvw1,x,arcs,reshape(c,7,[]))];
            if ~isempty(q)
                vp = reshape(uvw,3,[]);
                M = struct(...
                    'proj_params', mat2cell(q,1,ones(size(q))),...
                    'vp', squeeze(mat2cell(vp,3,3*ones(size(q)))),...
                    'pp', [0; 0],...
                    'consistency',...
                            mat2cell(consistency,2,ones(size(q))),...
                    'solver_time', mat2cell(soltime,1,ones(size(q))));
            end
        end
    end
    
    methods
        function this = p2x4c2(varargin)
            mss = containers.Map();
            mss('ct') = [4];
            mss('arc') = [2];
            this = this@WRAP.DivisionSolver(mss, varargin{:});
            this.name = 'Solver4PC2CA';
        end
        
        function M = fit(this, x, c, arcs)
            c = reshape(c, 14, []);
            M = this.solve(x, c, arcs);
        end
    end
end