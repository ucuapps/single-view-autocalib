function arcs = get_from_contour_DP(edges_list, ...
                                    line_tol, ...
                                    min_arc_length)
    % Splits edges (list of edges) to arcs (list of arcs)
    % using Douglas-Peucker Polyline Simplification algorith
    

    if ~exist('line_tol', 'var') | isempty(line_tol)
        line_tol = 5;
    end
    num_groups = size(edges_list, 2);
    idx = 0;
    for group_id = 1:num_groups
        edges = edges_list{:,group_id};
        [ps,ix] = EDGE.dp_simplify(edges, line_tol);
        for i=1:size(ix,1)-1
            idx = idx+1;
            arcs{idx} = edges(ix(i):ix(i+1),:);
        end
    end

    arcs = EDGE.filter(arcs, min_arc_length);
    arcs = EDGE.connect(arcs);

    for i=1:size(arcs,2)
        arcs{i} = PT.homogenize(cell2mat(arcs(:,i))');
    end
end