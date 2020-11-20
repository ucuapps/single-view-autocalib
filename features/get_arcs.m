function [arcs, circles, G] = get_arcs(img, varargin)
    cfg = struct('read_cache', true, ...
                 'write_cache', true, ...
                 'outlierT', 1e5, ...
                 'vqT', 500, ...
                 'n_clusters', 10,...
                 'min_support', 3);
    cfg = cmp_argparse(cfg, varargin{:});
    
    dbpath = fileparts(mfilename('fullpath'));
    db = KeyValContourDb.getObj('dbfile', [dbpath '/db_arc.db']);
    
    cid = KEY.cid(img.url);
    is_found = false;

    if cfg.read_cache
        [arcs, is_found] = db.get(cid, 'arcs');
        [circles, ~] = db.get(cid, 'circles');
        [G, ~] = db.get(cid, 'labels');
    end

    if ~is_found 
        contours_params = {'low', 15, ...
                           'high', 50, ...
                           'alpha', 1.5, ...
                           'min_length', 0.04};
        contours = EDGE.extract(img, contours_params);
        disp('Extracted subpixel edges.');
        
        arc_params = struct('line_tol', 0.0015);
        line_tol = arc_params.line_tol * max(img.width, img.height);
        min_contour_length = struct(contours_params{:}).min_length * max(img.width, img.height);
        arcs = ARC.get_from_contour_DP(contours, ...
                                       line_tol, ...
                                       min_contour_length);
        disp('Extracted arcs with Douglas-Peukcker.');

        if size(arcs, 2) > 0
            [c, ~, ~, p, n, arcs] = CIRCLE.fit(arcs);
            circles = [c; p; n];
            disp('Fitted to circles.');
            inliers = CAM.rd_div_filter_circles(c, img.width, img.height, cfg.outlierT);
            circles = circles(:,inliers);
            arcs = arcs(:,inliers);
            disp(['Filtered circles. Got ' num2str(size(circles,2)) ' circles']);
            G = ones(1,numel(arcs));

            disp('Extracted groups.');
        else
            arcs = {};
            circles = [];
            G = [];
            disp('No arcs exracted.');
        end
        if cfg.write_cache
            db.put(cid, 'arcs', arcs);
            db.put(cid, 'circles', circles);
            db.put(cid, 'labels', G);
        end
    end

    display(['>>>> ', img.url...
             ': Extracted ' num2str(size(unique(G),2))...
             ' groups of ' num2str(size(arcs,2))...
             ' arcs/circles.']);
end