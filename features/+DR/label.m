function G = label(dr,img_size,varargin)
    cfg = struct('desc_cutoff', 150,...
                 'desc_linkage', 'single');
    cfg = cmp_argparse(cfg,varargin{:});

    x =[dr(:).u];
    
    G = DR.group_desc(dr, ...
                      'desc_cutoff', cfg.desc_cutoff, ...
                      'desc_linkage', cfg.desc_linkage);
    G = DR.filter_features(x,G,img_size);
    G = DR.limit_group_size(G,100);
    G = DR.limit_drs(G,2000);
    G = DR.break_reflections(x,findgroups(G));