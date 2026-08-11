function [D1,H1] = obstacle_loc(htr,Re,t_pos,r_pos,rho1,rho2,miu_B)
%--------------------------------------------------------------------------
% generate locations of obstacles to calculate the minimum elevation angle
% build-up area
%--------------------------------------------------------------------------
% syms x y H
% % d_eff=2880*(sqrt(t_pos(3))+sqrt(r_pos(3)));
% % d_max=4120*(sqrt(t_pos(3))+sqrt(r_pos(3)));
% dlos = sqrt((t_pos(1)-r_pos(1))^2+(t_pos(2)-r_pos(2))^2);
% eqns = [x + y == dlos/Re, (Re+t_pos(3))/(Re+H) == cos(x),(Re+r_pos(3))/(Re+H) == cos(y),x>=0,y>=0];
% vars = [x y H];
% [x,y,H] = solve(eqns, vars);  % H是没有障碍物遮挡的时候收发端天线高度处的地平线交点的高度；y/x是地平线交点与收/发端所对应的的弧度
% x=double(x);
% y=double(y);
% H=double(H);
dlos = sqrt((t_pos(1)-r_pos(1))^2+(t_pos(2)-r_pos(2))^2);
x = 0.5*dlos/Re;
% y = 0.5*dlos/Re;
% H = (Re+0.5*t_pos(3)+0.5*r_pos(3))/cos(x)-Re;

d_los = (Re+t_pos(3))*x;
W_B = 1000*sqrt(rho1/rho2);
S_B = 1000*(1-sqrt(rho1))/sqrt(rho2);
N_B = floor(d_los*sqrt(rho1)/(W_B+S_B));
d = zeros(1,N_B);
h = zeros(1,N_B);
for  i = 1:N_B
    d(i)= (i-0.5)*d_los/(N_B)+0.5*W_B;
    h(i)= htr-d(i)*(htr-t_pos(3))/d_los;
end
 D1 =d_los-roundn(d(floor(N_B)),-4);
 H1 = roundn(h(floor(N_B)),-4);
% P = real(prod(1-exp(-power(h,2)/(2*power(miu_B,2)))));
end



