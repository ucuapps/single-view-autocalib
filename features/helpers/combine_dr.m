%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function dr = combine_dr(desc,names_list)
dr = [];
ind = find(cellfun(@(x) ~isempty(x),desc));

for k = reshape(ind,1,[])
    for k2 = 1:numel(desc{k}.affpt)
        desc{k}.affpt(k2).class = desc{k}.affpt(k2).class;
        desc{k}.affpt(k2).uname = names_list{k};
    end
    m = LAF.affpt_to_pt3x3(desc{k}.affpt);
    t = [desc{k}.affpt(:).desc]';
    dr = cat(2,dr,struct('u', mat2cell(m,9,ones(size(m,2),1)), ...
                         'desc', mat2cell(t, 128*ones(1,numel(t)/128),1)', ...
                         'class', {desc{k}.affpt(:).class}, ...
                         'uname',{desc{k}.affpt(:).uname}));
end

[~,drid] = ismember([dr(:).class],unique([dr(:).class]));
tmp = mat2cell(drid,1,ones(1,numel(drid)));
[dr(:).drid] = tmp{:};
