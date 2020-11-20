%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function img = read_img()
    try
        img = readim(filecontent);
    catch
        if exist('/tmp','dir') == 7
            tmpurl = ['/tmp/tmpimpng' cid];
        else
            tmpurl = ['tmpimpng' cid];
        end
        fid = fopen(tmpurl,'w');
        fwrite(fid,filecontent);
        fclose(fid);
        img = imread(tmpurl);
        delete(tmpurl);                    
    end
end
