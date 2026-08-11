function [distance] = cal_distance_vector_multi(cA, cB)
%------------------------------------------------------------------------------
% CAL_DISTANCE_VECTOR: Calculate the 3D distance of vectors
%------------------------------------------------------------------------------
% Input:
% cA: Cartesian coordinates of point A (maybe a cluster of points!)
% cB: Cartesian coordinates of point B 
% 
% Output:
% distance: the distance between point A and point B
%------------------------------------------------------------------------------

NumA = size(cA,1); % number of point A
NumB = size(cB,1);
distance = zeros(NumA,NumB);

for ii=1:NumA
    for jj=1:NumB
        AB = cB(jj,:) - cA(ii,:);
        distance(ii,jj) = norm(AB);
    end
end
    
end

