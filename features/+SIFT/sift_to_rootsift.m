%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function rootSIFTs = sift_calc_rootSIFT(sifts)
sifts = double(sifts);
rootSIFTs = sqrt(bsxfun(@rdivide,sifts,sum(abs(sifts),1)));