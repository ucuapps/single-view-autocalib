%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
classdef AffPtToDistinctAffPt < Gen
    methods
        function this = AffPtToDistinctAffPt()
        end
    end
       
    methods(Static)
        function res = make(img,cfg_list,laf_list,varargin)
            disp(['DISTINCT regions ' img.url]);                
            res = cell(1,numel(cfg_list));
            for k = 1:numel(cfg_list)
                if isempty(laf_list{k}.affpt)
                    res{k}.affpt = [];
                    continue;
               end
                res{k}.affpt = laf_list{k}.affpt;
            end
        end
    end
end
