function arcs = extract(img, varargin)
    cfg = struct('low', 15, ...
                 'high', 50, ...
                 'alpha', 1.5, ...
                 'min_length', 0.04, ...
                 'line_tol', 0.0015);
    cfg = cmp_argparse(cfg, varargin{:});

    
    h = size(img,1);
    w = size(img,2);
    min_contour_length = cfg.min_length * max(w,h);
    line_tol = cfg.line_tol * max(w,h);

    contours = EDGE.extract(img.url, min_contour_length);
    arcs = ARC.get_from_contour_DP(contours, line_tol,
                                   min_contour_length);
end