function xfer_sqerr = calc_xfer_err(x,xp,xd,xdp,K,proj_params,H)
    ydp = RP2.mtimesx(K,RP2.project_div(PT.mtimesx(H,x),[],proj_params));
    yd = RP2.mtimesx(K,RP2.project_div(PT.mtimesx(multinv(H),xp),[],proj_params));
    err = [xd-yd; xdp-ydp];
    xfer_sqerr = [];
    for k=1:3
        xfer_sqerr = [xfer_sqerr;...
                      sum(err([3*k-2:3*k-1 9+3*k-2:9+3*k-1],:).^2)/2];
    end
end

% function cost = calc_xfer_err(xd,xpd,cc,q,H)
% M = 2*size(xd,1);
% Hinv = multinv(H);
% ut_j =  RP2.rd_div(PT.renormI(PT.mtimesx(H,RP2.ru_div(xd,cc,q))),cc,q);
% ut_i =  RP2.rd_div(PT.renormI(PT.mtimesx(Hinv,RP2.ru_div(xpd,cc,q))),cc,q);
% cost = [ut_j-xpd;ut_i-xd];
% ind = reshape(1:M,3,[]);
% ind = reshape(ind(1:2,:),1,[]);
% cost = cost(ind,:);