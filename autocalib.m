function is_image_valid = autocalib(img_path, solvers, priors,...
                                    res_dir, img_id, varargin)
    cfg.render = 1;
    cfg.debug = 0;
    cfg.gt = [];
    [cfg, varargin] = cmp_argparse(cfg, varargin{:});
    [sampler_cfg, ransac_cfg, lo_cfg] = cfg_autocalib(varargin{:});

    if nargin < 3 || isempty(priors)
        priors = ones(1,numel(solvers));
    end
    if nargin < 4 || isempty(res_dir)
        res_dir = make_tmp_dir;
    end
    if nargin < 5 || isempty(img_id)
        [~,name,ext] = fileparts(img_path);
        img_id = [name ext];
    end

    if iscell(solvers)
        solvers_lists = solvers;
        priors_lists = priors;
    else
        solvers_lists = {solvers};
        priors_lists = {priors};
    end
    assert(numel(solvers_lists)==numel(priors_lists))

    display(['>>>>>> Image: ' img_id])
    img = get_image(img_path, 3000);
    if ~isempty(cfg.gt)
        [~,name,ext] = fileparts(img_path);
        gt = cfg.gt([name ext]);
        rgns = gt.rgns;
        Gapp = gt.Gapp;
        arcs = gt.arcs;
        circ = gt.circles;
        Gc = ones(1,numel(arcs));
    else
        if isunix & ~ismac
            [rgns,Gapp] = get_rgns(img,'write_cache',1,...
                                        'read_cache',1);
            [arcs,circ,Gc] = get_arcs(img,'write_cache',1,...
                                            'read_cache',1);
        elseif ismac
            display('WARNING: MacOS systems are partially supported. Only arcs and no regions will be extracted.')
            rgns = []; Gapp = [];
            [arcs, circ, Gc] = get_arcs(img,...
                                    'write_cache', 0,...
                                    'read_cache', 0);
        else
            error('Linux systems are supported only.')
        end
    end
    nx = img.width; 
    ny = img.height;
    img = img.data;
    
    % Filtering if too many circles
    lengthT = 0.04;
    valid = cellfun(@(u) size(u,2)>lengthT*max(nx, ny),arcs);
    arcs = arcs(valid);
    circ  = circ(:,valid);
    Gc = Gc(valid);

    % Sparsifying if too dense
    max_sz = 4;
    arc_sizes = cellfun(@(x) size(x,2),arcs);
    dense_arcs = find(arc_sizes>max_sz);
    arcs(dense_arcs) = cellfun(@(arc,sz) arc(:,floor(linspace(1,sz,max_sz))), arcs(dense_arcs), num2cell(arc_sizes(dense_arcs)),'UniformOutput',0);

    display(['>>>> ' num2str(size(rgns,2)) ' regions.'])
    display(['>>>> ' num2str(numel(arcs)) ' arcs.'])
    if cfg.debug
        % Plot measurements
        close all
        fig;
        subplot(2,2,1)
        imshow(img);
        CIRCLE.draw(circ(1:3,:),'color',Gc)
        ARC.draw(arcs,'color',Gc,'linewidth',4)
        xlim([1 nx])
        ylim([1 ny])
        subplot(2,2,2)
        imshow(img);
        GRID.draw(rgns,'color',Gapp,'size',8,'linewidth',2)
    end

    meas = containers.Map();
    meas('rgn') = rgns;
    meas('arc') = arcs;
    varinput = containers.Map();
    varinput('arc') = circ;
    groups = containers.Map();
    groups('rgn') = Gapp;
    groups('arc') = Gc;

    cs = containers.Map('UniformValues',0);
    cs('rgn') = CspondCs();
    cs('arc') = LabelingCs(groups('arc'));
    
    cc = [nx/2+0.5; ny/2+0.5];
    A = inv(CAM.make_diag_normalization(cc));
    [meas_norm, varinput_norm] = MEAS.normalize(meas, A, varinput);
    lo_cfg{2} = lo_cfg{2} / A(1,1); % reprojT_rgn
    lo_cfg{4} = lo_cfg{4} / A(1,1); % reprojT_arc
    lo_cfg{6} = lo_cfg{6} / A(1,1); % baselineT_rgn

    is_image_valid = zeros(1,numel(solvers_lists));
    for k=1:numel(solvers_lists)
        solvers = solvers_lists{k};
        for k1=1:numel(solvers)
            if HybridSampler.is_solver_valid(groups, solvers(k1));
                is_image_valid(k) = 1;
                break
            end
        end
    end
    if ~sum(is_image_valid)
        return;
    end
    for k=1:numel(solvers_lists)
        solvers = solvers_lists{k};
        priors = priors_lists{k};
        names = strjoin({solvers(:).name},'+');
        display(['>>>>>> Solver(s): ' names])
        [solvers(:).reprojT_rgn] = deal(8*lo_cfg{2});
        [solvers(:).reprojT_arc] = deal(2*lo_cfg{4});
        [solvers(:).baselineT_rgn] = deal(lo_cfg{6});

        if is_image_valid(k)
            lo=ManhattanHybridPrinter(meas_norm,groups,lo_cfg{:});
            if cfg.debug
                keyboard
            end
            sampler=HybridSampler(solvers,priors,groups,cs,sampler_cfg{:});
            ransac=HybridRansac(solvers,sampler,lo,lo,ransac_cfg{:});
            [model,res,stats] = ransac.fit(meas_norm,varinput_norm);

            if ~isempty(model)
                [model, res] = eval_unnorm(model, res, A, lo,...
                                            meas_norm, varinput_norm);

                [res.info.min_model, res.info.min_res] =...
                eval_unnorm(res.info.min_model, res.info.min_res,...
                             A, lo, meas_norm, varinput_norm);
                
                if cfg.debug
                    if isfield(res.info,'circ')
                        arcs = meas('arc');
                        arcs = arcs(res.info.cs);
                        Gvpc = res.info.Gvp;
                        subplot(2,2,3)
                        imshow(img);
                        CIRCLE.draw(res.info.circ,'color',Gvpc)
                        ARC.draw(arcs,'color',Gvpc,'linewidth',4)
                        xlim([1 nx])
                        ylim([1 ny])
                        GRID.draw(RP2.project_div(model.K*model.R,model.K,model.proj_params),'color','k','size',30)
                        GRID.draw(RP2.project_div(model.K*model.R,model.K,model.proj_params))
                    end
                    if isfield(res,'rgn')
                        rgns = meas('rgn');
                        cspond = res.rgn.info.cspond;
                        Gvpx = res.rgn.info.Gvp;
                        cs = res.rgn.info.cs;
                        clr = eye(3);
                        subplot(2,2,4)
                        imshow(img);
                        for k=1:3
                            GRID.draw([rgns((k-1)*3+1:k*3,cspond(1,cs));rgns((k-1)*3+1:k*3,cspond(2,cs))],'color',clr(Gvpx(cs),:),'size',8,'linewidth',2)
                        end 
                        xlim([1 nx])
                        ylim([1 ny])
                        GRID.draw(RP2.project_div(model.K*model.R,model.K,model.proj_params),'color','k','size',30)
                        GRID.draw(RP2.project_div(model.K*model.R,model.K,model.proj_params))
                        keyboard
                    end
                end
            end
        else
            model = [];
            res = [];
            stats = [];
        end
        if isempty(model)
            display(['WARNING: Solver(s) ' names ' did not return a model for image ' img_path]);
            model = struct();
        end

        result_path = fullfile(res_dir, names);
        if ~exist(result_path, 'dir'), mkdir(result_path); end
        [~,img_name] = fileparts(img_path);
        
        run_id = 1;
        mat_file_path = fullfile(result_path, [img_name '_run' num2str(run_id,'%04d') '.mat']);
        while exist(mat_file_path)
            run_id = run_id+1;
            mat_file_path = fullfile(result_path, [img_name '_run' num2str(run_id,'%04d') '.mat']);
        end
        display(['>>>> .mat file with results: ', mat_file_path])
        save(mat_file_path, 'model', 'res', 'stats', 'meas', 'groups', 'varinput', 'img_path');
        display('>>>> Modeled and saved.')
        
        if cfg.render
            if ~isempty(cfg.gt)
                render_calib(mat_file_path,'gt',cfg.gt)
            else
                render_calib(mat_file_path)
            end
        end
    end
end

function [arcs, circ, Gvc] = fltr(arcs, circ, Gvc, nx, ny, lengthT)
    valid1 = cellfun(@(u) size(u,2)>lengthT*max(nx, ny),arcs);
    valid2 = circ(3,:) > min(nx, ny);
    valid3 = (nx/2+0.5-circ(1,:)).^2 +...
              (ny/2+0.5-circ(2,:)).^2 < circ(3,:).^2;
    valid = valid1 & valid2 & valid3;
    arcs = arcs(valid);
    circ  = circ(:,valid);
    Gvc = Gvc(valid);
end

function [model, res] = eval_unnorm(model, res, A, eval, meas, varinput)
    if ~isempty(meas('rgn'))
        [res.rgn.loss, res.rgn.errs, res.rgn.ir, res.rgn.info] = eval.calc_loss_rgns(meas, model, varinput);
        res.rgn.loss = A(1,1)^2 * res.rgn.loss;
        res.rgn.errs = A(1,1) * res.rgn.errs;
    end
    if ~isempty(meas('arc')) & isfield(res.info,'circ')
        res.info.circ =...
                CIRCLE.unnormalize(res.info.circ, A);
        res.errs = A(1,1) * res.errs;
        res.info.loss0 = A(1,1) * res.info.loss0;
        res.loss = A(1,1)^2 * res.loss;
    end
    
    model.K = A * model.K;
    R0 = [1 0 0 ; 0 -1 0; 0 0 -1];
    R{1} = CAM.rotation_wrt_plane(model.R);
    R{2} = CAM.rotation_wrt_plane(model.R(:, [1 3 2]));
    R{3} = CAM.rotation_wrt_plane(model.R(:, [2 3 1]));
    for k = 1:numel(R)
        Hs(:,:,k) = model.K * R0 * R{k}' * inv(model.K);
        model.l(:, k) = PT.renormI(transpose(Hs(3,:,k)));
    end
    model.Hs = Hs;
end