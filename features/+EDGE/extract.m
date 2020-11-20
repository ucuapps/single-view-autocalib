function contours = extract(img, varargin)
    cfg = struct('low', 15, ...
                 'high', 50, ...
                 'alpha', 1.5, ...
                 'min_length', 0.04);
    cfg = cmp_argparse(cfg, varargin{:});

    min_contour_length = cfg.min_length * max(img.width, img.height);
    contours = edgeSubPix(...
                convertCharsToStrings(GetFullPath(img.url)), ...
                        cfg.low, cfg.high, cfg.alpha);
    
    for i=1:size(contours,2)
        contours{:,i} = contours{:,i}';
    end

    contours = EDGE.filter(contours, min_contour_length);
end