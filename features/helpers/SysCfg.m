%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
classdef SysCfg
    properties 
        map
    end

    methods
        function this = SysCfg()
                this.map = ...
                    containers.Map({'Mserp','Mserm','HessianAffine', ... 
                                    'Laf','Sift','DistinctAffPt','Dollar'}, ...
                                   {'make_extrema','make_extrema', ...
                                    'make_hessian_affine', ...
                                    'make_mser_to_laf','make_affpt_to_sift', ... 
                                    'make_distinct', 'make_dollar'});
            end

        function chain = cfgs_to_gens(this,cfg_list)
            gen_str = cell(1,numel(cfg_list));
            for i = 1:numel(cfg_list)
                gen_str{i} = cell(1,numel(cfg_list{i}));
                for j = 1:numel(gen_str{i})
                    gen_str{i}{j} = values(this.map, {cfg_list{i}{j}.get_uname});
                end
            end
            chain = cellfun(@(x) cellfun(@(y) feval(str2func(y{:})),x, ...
                'UniformOutput',false),gen_str,'UniformOutput',false);
        end
        
    end
end

function extrema = make_extrema()
    extrema = MSER.Extrema();
end

function haff = make_hessian_affine()
    haff = COVDET.KmPts2();
end

function mser_to_laf = make_mser_to_laf()
    mser_to_laf = LAF.MserToLaf();
end

function affpt_to_sift = make_affpt_to_sift()
    affpt_to_sift = SIFT.AffPtToSift();
end

function dist = make_distinct()
    dist = COVDET.AffPtToDistinctAffPt();
end

function dollar = make_dollar()
    dollar = EDGE.Dollar();
end
