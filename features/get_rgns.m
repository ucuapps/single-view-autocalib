function [x,G,rgn_cspond] = get_rgns(img, varargin)
    cfg = struct('read_cache', true, ...
                 'write_cache', true);
    cfg = cmp_argparse(cfg, varargin{:});

    dbpath = fileparts(mfilename('fullpath'));

    KeyValDb.getObj('dbfile', [dbpath '/db_laf.db']); 
    cid_cache = CidCache(img.cid,...
                        'read_cache', cfg.read_cache, ...
                        'write_cache', cfg.write_cache );
    dr = DR.get(img,cid_cache, ...
                     {'type','mser', ...
                      'reflection', false});
    G = DR.label(dr,size(img.data));
    [dr,G] = DR.keep_only_valid(dr,G);
    x = [dr(:).u];

    display(['>>>> ', img.url...
            ': Extracted ' num2str(size(unique(G),2))...
            ' groups of ' num2str(size(x,2))...
            ' regions.']);
end
