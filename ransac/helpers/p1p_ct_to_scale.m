function s = p1p_ct_to_scale(X,Xp,u,l)
y = X(2,:);
z = X(3,:);
x = X(1,:);
yp = Xp(2,:);
zp = Xp(3,:);
xp = Xp(1,:);
u1 = u(1);
u2 = u(2);
u3 = u(3);
l1 = l(1);
l2 = l(2);
l3 = l(3);

lx = l1*x + l2*y + l3*z;
s1 = -(x.*zp - xp.*z)./((u1*zp - u3*xp).*lx);
s2 = -(y.*zp - yp.*z)./((u2*zp - u3*yp).*lx);

s1(isnan(s1)) = s2(isnan(s1));
s2(isnan(s2)) = s1(isnan(s2));

sl = [s1; s2];
s = mean(sl,1);