%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function affpt = split_reflect(affpt)
if ~isfield(affpt,'reflected')
	warning('No reflections');
	return;
end
is_reflected = [affpt.reflected];
if isfield(affpt,'class')
	drid = num2cell([affpt(is_reflected).class] * 2);
	[affpt(is_reflected).class] = deal(drid{:});
elseif isfield(affpt,'drid')
	drid = num2cell([affpt(is_reflected).drid] * 2);
	[affpt(is_reflected).drid] = deal(drid{:});
end