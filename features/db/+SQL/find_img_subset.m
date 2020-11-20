%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function [img_subset,ind] = find_img_subset(img_set,subset)
if iscell(subset)
    for k = 1:numel(subset)
        [img_subset(k),ind(k)] = SQL.find_img_name(img_set,subset{k});
    end
else
    [img_subset,ind] = SQL.find_img_name(img_set,subset);
end