function [theta_1,phi_1] = transfm(theta,phi)

theta_1 = [cos(theta).*cos(phi)
    cos(theta).*sin(phi)
    -sin(theta)];

phi_1 = [-sin(phi)
    cos(phi)
    zeros(size(phi))];