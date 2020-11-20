%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function scfg = class_to_struct(cfg)
    warning('off','MATLAB:structOnObject');
    scfg = struct(cfg);
    warning('on','MATLAB:structOnObject');