function [cid] = cid(impath)
    fid = fopen(impath, 'r');
    filecontent = fread(fid, inf, '*uint8');
    cid = KEY.hash(filecontent, 'MD5');
end