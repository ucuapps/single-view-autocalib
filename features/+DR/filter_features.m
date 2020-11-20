function G = filter_features(x,G,img_size)
    img_area = img_size(1)*img_size(2);
    areaT = 0.000015*img_area;
    G(find(abs(LAF.calc_scale(x)) < areaT)) = nan;
    angles = LAF.calc_angle(x);
    G(find((angles < 1/10*pi) | (angles > 9/10*pi))) = nan;
    G = DR.rm_singletons(findgroups(G));