%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function X = cvdb_hash_xor(varargin)
X = varargin{1};

for k = 2:numel(varargin)
    X2 = varargin{k};
    for i=1:4
        tmp(i) = bitxor(uint32(hex2dec(X(8*(i-1)+1:8*i))), ...
                        uint32(hex2dec(X2(8*(i-1)+1:8*i))));
    end
    X = reshape(dec2hex(tmp,8)',1,32);
end