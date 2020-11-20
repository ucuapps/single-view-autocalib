%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
classdef AffPtToSift < handle & matlab.mixin.Heterogeneous
    methods
        function this = AffPtToSift()
        end
    end
    
    methods(Static)
        function res = make(img,desc_cfg_list,feat)
            for k = 1:numel(desc_cfg_list)
                %            msg(1, 'Generating ''%s'' desc. from ''%s'' (%s)\n', ...
                %                upper(outputs{k}),dr{k}.name,img.url);
                t = cputime;
                ids = num2cell([1:numel(feat{k}.affpt)]);
                [feat{k}.affpt(:).id] = deal(ids{:});
                [res{k}] = affpatch(img.intensity,feat{k}.affpt, ...
                                  KEY.class_to_struct(desc_cfg_list{k}));
                if ~isfield(res{k},'affpt')
                    res{k}.affpt = [];
                else
                    % res{k}.affpt_sift = res{k}.affpt;
                    desc = [res{k}.affpt(:).desc];
                    desc = mat2cell(desc,1,128*ones(numel(desc)/128,1));
                    res{k}.affpt = feat{k}.affpt([res{k}.affpt(:).id]);
                    [res{k}.affpt.desc] = deal(desc{:});
                    [res{k}.affpt.reflected] = deal(false);
                end
               
                if ~isempty(res{k}.affpt)
                    ids = num2cell([1:numel(res{k}.affpt)]);
                    [res{k}.affpt(:).id_patch] = deal(ids{:});
                end
                res{k}.time = cputime-t;
                % res{k}.desc2dr = [res{k}.affpt(:).id];
                % res{k}.num_desc = length(res{k}.affpt);
            end
        end
    end
end