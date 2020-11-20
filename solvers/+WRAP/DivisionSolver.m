classdef DivisionSolver < WRAP.Solver
    properties
        proj_model = 'div';
        proj_model_full = 'Division';
        param_names = {'q', 'cx', 'cy'}
    end
    
    methods
        function this = DivisionSolver(mss, varargin)
            this = this@WRAP.Solver(mss, varargin{:});
        end
    end

    methods(Static)
        function flag = valid_q(q, varargin)
            cfg.normalization = 'diag';
            cfg = cmp_argparse(cfg, varargin{:});
            if strcmp(cfg.normalization, 'K')
                q_bound = -2;
            elseif strcmp(cfg.normalization, 'diag')
                q_bound = -2;
            elseif strcmp(cfg.normalization, 'fitz')
                q_bound = -16;
            end
            flag = ~isnan(q) &...
                   abs(imag(q)) < 1e-9 &...
                   real(q) < 1e-9 &...
                   real(q) > q_bound;
        end

        function flag = valid_dc(dc, varargin)
            cfg.normalization = 'diag';
            cfg = cmp_argparse(cfg, varargin{:});
            if strcmp(cfg.normalization, 'K')
                dc_bound = 1;
            elseif strcmp(cfg.normalization, 'diag')
                dc_bound = 1;
            elseif strcmp(cfg.normalization, 'fitz')
                dc_bound = sqrt(2)/4;
            end
            flag = all(abs(dc) < dc_bound);
        end

        function [models, flag] = valid_models(models, varargin)
            flag = arrayfun(@(m) WRAP.DivisionSolver.valid_q(m.proj_params(1)), models);
            if ~isempty(models) & numel(models(1).proj_params) > 1
                flag = flag & arrayfun(@(m) WRAP.DivisionSolver.valid_dc(m.proj_params(2:3)), models);
            end
            models = models(flag);
        end
    end
end
