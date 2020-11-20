%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function mser = apply_T(mserin,T)
mser = mserin;
for k = 1:size(mser.rle,2)
	rle1 = mser.rle{1,k};
	rle1 = [rle1{1}; ones(1,size(rle1{1},2))];
	rle1 = renormI(T*rle1);
	mser.rle{1,k} = rle1(1:2,:);

	rle2 = mser.rle{3,k};
	rle2 = [rle2; ones(1,size(rle2,2))];
	rle2 = renormI(T*rle2);
	mser.rle{3,k} = rle2(1:2,:);
end