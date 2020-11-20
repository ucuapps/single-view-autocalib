%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
classdef Extrema < Gen
    properties(Constant)
        subids = containers.Map({class(MSER.CFG.Mserp()),class(MSER.CFG.Mserm())},[1 2]);
    end

    methods
        function this = Extrema()
        end
    end
    
    methods(Static)
        function res = make(img,feat_cfg_list,varargin)
            disp(['MSER detection ' img.url ':']);
            
            a = img.data;

            cfg_list_names = cellfun(@(x) class(x),feat_cfg_list,'UniformOutput',false);
            subids = cell2mat(values(MSER.Extrema.subids,cfg_list_names));
            key_list = cellfun(@(x) KEY.cfg2hash(x),feat_cfg_list,'UniformOutput',false);
            if (numel(unique(key_list)) == 1)
                [mser img det_time] = extrema(a, ...
                          KEY.class_to_struct(feat_cfg_list{1}), ...
                          subids);
            else
                mser = cell(1,numel(subids));
                det_time = zeros(1,numel(subids));
                for k = 1:numel(subids)
                    [mser(k) img] = extrema(a, ...
                            KEY.class_to_struct(feat_cfg_list{k}), ...
                            subids(k));
                end
            end

            % store msers and images in apropriate cells
            res = cell(1,numel(subids));
            for k = 1:numel(subids)
                ind = 1:numel(mser{k});
                if ~isempty(mser{:,k})
                    res{k}.rle = mser{:,k};
                end
                %                res{k}.time = det_time(k);
            end
        end
    end
end