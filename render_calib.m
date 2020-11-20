function render_calib(data, varargin)
    cfg.undistortions = 1;
    cfg.rectifications = 1;
    cfg.reiterate = 1;
    cfg.features = 1;
    cfg.minsample = 0;
    cfg.img_path = [];
    cfg.gt = [];
    cfg.vl_min_dist = 0.2;
    cfg = cmp_argparse(cfg, varargin{:});

    if isstr(data)
        if isfile(data), mat_file_paths = {data};
        elseif isdir(data), mat_file_paths = glob(data,'*.mat');
        else display(['>>> Path ' data ' does not exist.']); return
        end
    else, mat_file_paths = data;
    end

    for k1=1:numel(mat_file_paths)
        mat_file_path = mat_file_paths{k1};
        [base_dir, file_name, ext] = fileparts(mat_file_path);
        display(['>>> Rendering ' mat_file_path])
        load(mat_file_path, 'model', 'res', 'stats', 'meas', 'groups','varinput', 'img_path', 'render');
        
        if ~isempty(cfg.img_path)
            img_path = cfg.img_path;
        elseif ~exist(img_path)
            error('Please provide a valid path to an image.');
        end

        img = imread(img_path);
        
        if isempty(fieldnames(model))
            error(['No model found in ' mat_file_path]);
        end

        base_path = fullfile(base_dir, file_name);

        ny = size(img,1);
        nx = size(img,2);

        try
            render = render_calib_model(img, img_path, base_path, '', meas, groups, model, res, nx, ny, cfg);
            if ~isempty(render)
                save(mat_file_path, 'model', 'res', 'stats', 'meas', 'groups', 'varinput', 'img_path', 'render');
            end
        catch e
            fprintf('>>> ERROR: Could not render %s\n',mat_file_path);
            display_error(e)
        end
        
    end
end

function render = render_calib_model(img, img_path, base_path, sufx, meas, groups, M, res, nx, ny, cfg)
    close all;
    render = [];
    M.q =  CAM.unnormalize_div(M.proj_params(1),M.K);
    M0 = res.info.min_model;
    M0.q =  CAM.unnormalize_div(M0.proj_params(1),M0.K);
    if isfield(res,'rgn')
        x = meas('rgn');
        xu = RP2.backproject_div(x,M.K,M.proj_params);
        cspond = res.rgn.info.cspond;
        Gvlx = res.rgn.info.Gvl;
    else
        x = [];
        cspond = [];
        Gvlx = [];
    end
    if isfield(res.info,'circ')
        circ = res.info.circ;
        Gvpc = res.info.Gvp;
    else
        circ = [];
        Gvpc = [];
    end
    if ~isempty(cfg.gt)
        [~,name,ext] = fileparts(img_path);
        img_id = [name ext];
        gt = cfg.gt(img_id);
        [pts_x, pts_y] = meshgrid(linspace(1, gt.nx, 30),...
        linspace(1, gt.ny, ceil(30/gt.nx*gt.ny)));
        pts=transpose([pts_x(:) pts_y(:) ones(numel(pts_x), 1)]);
        warperr = METRICS.warperr(pts, ...
            gt.proj_fn, gt.backproj_fn,...
            [], [], gt.K, gt.proj_params,...
            [], [], M.K, M.proj_params,...
            'rotation', 'none')
    end
    ld = LINE.project_div(M.l,M.K, M.proj_params);
    ud = RP2.project_div(RP2.renormI(M.K*M.R),M.K, M.proj_params);
    M.l = M.l ./ vecnorm(M.l(1:2,:),2,1);

    if isempty(sufx) & cfg.minsample & ~exist([base_path '_mss.jpg'])
        mimg = IMG.make_minimal_img(img, meas, M0, res.info.min_res);
        if ~isempty(mimg)
            imwrite(mimg, [base_path '_mss.jpg']);
        end
    end

    if cfg.undistortions & ~exist([base_path '_ud' sufx '.jpg'])
        [uimg,xborder,~,T_ud] = ...
            IMG.undistort_div(img, M.K, M.proj_params,'fov',140);
        imwrite(uimg, [base_path '_ud' sufx '.jpg']);
        T_ud(1:2,3) = -xborder(1:2)';
        render.T_ud = T_ud;
    end

    if cfg.features & ~exist([base_path '_sceneGvl' sufx '.jpg'])

        [simg1,simg2,simg3,simg4] = IMG.make_scene_img2(img, meas, groups, res, M);
        if ~isempty(simg1)
            imwrite(simg1, [base_path '_sceneGvpc' sufx '.jpg']);
        end
        if ~isempty(simg2)
            imwrite(simg2, [base_path '_sceneGvpx' sufx '.jpg']);
        end
        if ~isempty(simg3)
            imwrite(simg3, [base_path '_sceneGvl' sufx '.jpg']);
        end
        if ~isempty(simg4)
            imwrite(simg4, [base_path '_sceneGvp' sufx '.jpg']);
        end
    end

    if cfg.rectifications & ~exist([base_path '_rect' sufx '.jpg'])
        masks = IMG.make_ld_masks(ld,M.l,M.K(1:3,3),nx,ny);

        if numel(M.proj_params)==3
            M.cc = M.K * RP2.homogenize(M.proj_params(2:3)');
            M.cc = M.cc(1:2);
        else
            M.cc = M.K(1:2,3)';
        end
        [rimgs, T_rect] =...
            IMG.make_orthophotos2(img, masks, M,...
                        base_path, sufx,...
                        'size', [ny nx],...
                        'vl_min_dist', cfg.vl_min_dist,...
                        'reiterate',cfg.reiterate);
        render.T_rect = T_rect;
    end

    if ~isempty(cfg.gt)
        clr.vl = {'y','c','m'};
        clr.vp = {'r','g','b'};
        fontsize = min(200,ceil(sqrt(nx^2+ny^2)/30));
        if exist([base_path '_rect' sufx '.jpg'])
            resimgpath = [base_path '_rect' sufx '.jpg'];
        elseif exist([base_path '_ud' sufx '.jpg'])
            resimgpath = [base_path '_ud' sufx '.jpg'];
        else 
            return
        end
        resimg = imresize(imread(resimgpath),[1200,1800]);
        resimg = insertText(resimg,[1050 15],sprintf('%4.2f pixels',warperr),'Font','LucidaBrightDemiBold','FontSize',fontsize,'BoxColor','black','BoxOpacity',1,'TextColor','white');
        imwrite(resimg, resimgpath);
    end
end