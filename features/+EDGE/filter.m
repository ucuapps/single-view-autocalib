function edges_list = filter(edges_list, min_edge_size)
    num_groups = size(edges_list,2);
    groups_to_keep = [];
    for group_id=1:num_groups
        if size(edges_list{:,group_id}, 1) > min_edge_size
            groups_to_keep = [groups_to_keep group_id];
        end
    end
    edges_list = edges_list(:,groups_to_keep);
end