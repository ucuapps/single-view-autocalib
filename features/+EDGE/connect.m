function connected_edges_list = connect(edges_list)
    eps = 10;
    num_edges = size(edges_list, 2);
    edges_info = zeros(2 * num_edges, 4); % x y alpha
    
    for i=1:num_edges
        num_points = size(edges_list{i}, 1);    
        x1 = edges_list{i}(1,1);
        y1 = edges_list{i}(1,2);
        x2 = edges_list{i}(num_points,1);
        y2 = edges_list{i}(num_points,2);
        
        slope = (y2 - y1) ./ (x2 - x1);
        angle = atand(slope);
        
        edges_info(2 * i - 1, 1) = edges_list{i}(1,1);
        edges_info(2 * i - 1, 2) = edges_list{i}(1,2);
        edges_info(2 * i - 1, 3) = angle;
        edges_info(2 * i - 1, 4) = i;
    
        
        edges_info(2 * i, 1) = edges_list{i}(num_points,1);
        edges_info(2 * i, 2) = edges_list{i}(num_points,2);
        edges_info(2 * i, 3) = angle;
        edges_info(2 * i, 4) = i;
    
    end
    
    edges_info = sortrows(edges_info,[1,2]);
    clusters = -ones(1, num_edges);
    
    count = 1;
    for i=1:size(edges_info)-1
        dist = norm(edges_info(i, 1:2) - edges_info(i + 1, 1:2)) + abs(edges_info(i, 3) - edges_info(i + 1, 3));
        if dist < eps
            id1 = edges_info(i, 4);
            id2 = edges_info(i + 1, 4);
            
            if clusters(id1) == -1 && clusters(id2) == -1
                clusters(id1) = count;
                clusters(id2) = count;
                count = count + 1;
            elseif clusters(id1) == -1
                clusters(id1) = clusters(id2);
            elseif clusters(id2) == -1
                clusters(id2) = clusters(id1);
            else
                clusters(clusters == clusters(id2)) = clusters(id1);
            end
        end
    end
    
    unique_clusters = unique(clusters);
    connected_edges_list = {};
    for i=1:size(unique_clusters, 2)
        cluster_id = unique_clusters(i);
        ids = find(clusters == cluster_id);
        if cluster_id ~= -1        
            new_edge = unique(vertcat(edges_list{:,ids}), 'rows');
            connected_edges_list = cat(2, connected_edges_list, new_edge);
            
        else
            connected_edges_list = cat(2, connected_edges_list, edges_list{:,ids});
        end
    end
end