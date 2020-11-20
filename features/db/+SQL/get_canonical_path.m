%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function ourl = get_canonical_path(iurl)
[ipath,name,ext] = fileparts(iurl);
if isempty(ipath)
    ipath = pwd;
end
opath = cd(cd(ipath));
ourl = [opath '/' name ext];
