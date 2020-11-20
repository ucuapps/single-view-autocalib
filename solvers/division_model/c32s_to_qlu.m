function [q, l, u, v] = c32s_to_qlu(c)
    % Args:
    %   c --  4x5 array, 5 circular arcs
    %         ([x...; y...; nx...; ny...])
    % Returns:
    %   q --  division model parameter solutions
    %   l --  vanishing line solutions
    %   u --  1st vanishing point (VP) solutions
    %   v --  2nd VP solutions

    assert(size(c,2)==5), ['Size of c should be 5, but it is ' num2str(size(c,2))];
    
    c_ = c(:,[1 3 4]);
    cp_ = c(:,[2 2 5]);
    
    % %%%% DEBUG
    % close all
    % CIRCLE.draw([c_(:,1) cp_(:,1)],'color','red')
    % axis equal
    % keyboard
    % CIRCLE.draw([c_(:,2) cp_(:,2)],'color','blue')
    % keyboard
    % CIRCLE.draw([c_(:,3) cp_(:,3)],'color','green')
    % keyboard
    % %%%%

    [u0, u1, u2] = MC_to_u([c_; cp_]);

    idx1 = 1;  % index of the first VP to coincide
    idx2 = 2;  % index of the second VP to coincide
    idx3 = 3;  % index of the third VP

    coeffs_q(:,4) = cross(u0(:,idx1), u0(:,idx2));
    coeffs_q(:,3) = cross(u0(:,idx1), u1(:,idx2)) + cross(u1(:,idx1), u0(:,idx2));
    coeffs_q(:,2) = cross(u0(:,idx1), u2(:,idx2)) + cross(u1(:,idx1), u1(:,idx2)) + cross(u2(:,idx1), u0(:,idx2));
    coeffs_q(:,1) = cross(u1(:,idx1), u2(:,idx2)) + cross(u2(:,idx1), u1(:,idx2));

    q1 = roots(coeffs_q(1,:));
    q2 = roots(coeffs_q(2,:));
    q3 = roots(coeffs_q(3,2:4));
    q = [q1; q2; q3; q1; q2; q3; q1; q2; q3]';

    l = zeros(3,8*3);
    u = zeros(3,8*3);
    v = zeros(3,8*3);
    for k = 1:8
        M = u0 + u1 .* q(k) + u2 .* q(k)^2;
        u(:,k) = M(:,idx1);
        v(:,k) = M(:,idx3);
        l(:,k) = LINE.inhomogenize(cross(u(:,k),v(:,k)));
    end
    u(:,9:16) = u(:,1:8);
    u(:,17:24) = u(:,1:8);

    [t0, t1] = MC_to_t(c_(:,idx3));
    [t0p, t1p] = MC_to_t(cp_(:,idx3));
    for k = 1:8
        ind = [8+k 16+k];
        t = [t0 + q(k)*t1, t0p + q(k)*t1p];
        [v(:,ind),~,~,l(:,ind)] = t2u_to_vw(t, u(:,k));
    end
end
