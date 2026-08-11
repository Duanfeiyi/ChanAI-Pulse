function [Cmatrix_total_end] = gen_birth_death_array_2D(Nc0, scen_para, M_I, M_J, deltaT_H, deltaT_V, betaH_E, betaV_E, Plot)
%------------------------------------------------------------------------------
% GEN_BIRTH_DEATH_array_2D: Generate birth-death matrix of LED array at Tx side
%------------------------------------------------------------------------------
% Input:
% lambda_B: cluster generation (birth) rate
% lambda_D: cluster recombination (death) rate
% M_I, M_J: number of LED units in H direction and V direction
% deltaT_H, deltaT_V: spacing of LED units in H direction and V direction
% betaH_E, betaV_E: elevation angle of LED array in H direction and V direction
% Plot: plot the figure or not
%
% Output:
% Cmatrix_total_end: the birth-death matrix of LED array with size M_I*M_J*Nc
%------------------------------------------------------------------------------
corr_distance_array = scen_para.Corr_distance_A;              % coherence distance in (m).
lambda_B = scen_para.lambdaG; 
lambda_D = scen_para.lambdaR;

delta_H_array = deltaT_H*cos(betaH_E)/corr_distance_array;
prob_death_H = min(exp(-lambda_D*delta_H_array), 1); % 
% H方向上演进(第一列)
Max_ClusterH_Index=ones(1,M_I)*Nc0;                   % initial max cluster index unit.
N_new_avg=lambda_B/lambda_D*(1-prob_death_H);         % average number of newly generated clusters.
Cmatrix_H(1,1:Nc0)=1;                                 % initial Cluster matrix at L_11 side at t=0s.
NewClusterH_num = zeros(1,M_I);

for k=2:M_I
   Cmatrix_H(k,1:Max_ClusterH_Index(k-1)) = Cmatrix_H(k-1,1:Max_ClusterH_Index(k-1)).*(rand(1,Max_ClusterH_Index(k-1))<prob_death_H); % recombination
   N_new_H = poissrnd(N_new_avg);
   NewClusterH_num(k) = N_new_H;
   if N_new_H>0
      Cmatrix_H(k,(Max_ClusterH_Index(k-1)+1):(Max_ClusterH_Index(k-1)+N_new_H)) = 1; % generation
   end
   Max_ClusterH_Index(k) = Max_ClusterH_Index(k-1)+N_new_H;
end

[array,cluster] = size(Cmatrix_H);
Cmatrix_H1 = zeros(size(Cmatrix_H));
ran_H = rand(1,cluster);
for i=1:cluster
   start_H = round(ran_H(i)*M_I);
   Cmatrix_H1(:,i)=Cmatrix_H(mod(start_H:start_H+M_I-1,M_I)+1,i);
end

%%
delta_V_array = deltaT_V*cos(betaV_E)/corr_distance_array;
prob_death_V = min(exp(-lambda_D*delta_V_array), 1);
% V方向上演进(逐列演进)
Max_ClusterV_Index = ones(1,M_J)*cluster;                   % initial max cluster index unit.
N_new_avg=lambda_B/lambda_D*(1-prob_death_V);         % average number of newly generated clusters.
NewClusterV_num = zeros(1,M_J);
Cmatrix_total = zeros(M_I,M_J,cluster);
Cmatrix_total(:,1,1:cluster) = Cmatrix_H1;

for k=2:M_J
   Cmatrix_total(:,k,1:Max_ClusterV_Index(k-1)) = Cmatrix_total(:,k-1,1:Max_ClusterV_Index(k-1)).*(rand(M_I,1,Max_ClusterV_Index(k-1))<prob_death_V); % recombination
   N_new_V = poissrnd(N_new_avg);
   NewClusterV_num(k) = N_new_V;
   if N_new_V>0
      Cmatrix_total(:,k,(Max_ClusterV_Index(k-1)+1):(Max_ClusterV_Index(k-1)+N_new_V)) = 1; % generation
   end
   Max_ClusterV_Index(k) = Max_ClusterV_Index(k-1)+N_new_V;
end

[arrayH,arrayV,cluster_new] = size(Cmatrix_total);
Cmatrix_total_end = zeros(size(Cmatrix_total));
ran_H = rand(1,cluster_new);
for i=1:cluster_new
   start_H = round(ran_H(i)*M_J);
   Cmatrix_total_end(:,:,i)=Cmatrix_total(:,mod(start_H:start_H+M_J-1,M_J)+1,i);
end

if Plot == 1
    figure; 
    % death/birth process.看某一列LED对所有簇的可见性
    Number_of_cluster=zeros(1,length(arrayH));
    for i=1:arrayH
        cluster_index=(squeeze(Cmatrix_total_end(i,5,:)).').*(1:cluster_new);
        cluster_index(cluster_index==0)=[];
        Number_of_cluster(i)=length(cluster_index);

        plot(i,cluster_index,'b+','lineWidth',1.3);  
        hold on
    end
    xlabel('LED array in H direction (s)');
    ylabel('Cluster index');
    grid on
    
    figure;
    % 看LED阵列对某一个簇的可见性
    [arrayH,arrayV,cluster_new] = size(Cmatrix_total_end);
    for i=1:arrayH
        for j=1:arrayV
            if Cmatrix_total_end(i,j,5) == 1
                plot(i,j,'b+','lineWidth',1.3);
                hold on;
            end
        end
    end
end

end