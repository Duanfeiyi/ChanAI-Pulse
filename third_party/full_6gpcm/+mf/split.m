function [op_no_txant,op_no_rxant] = split(no_snap,no_clusters,freq_sample)


r = 0.2;                                        %GPU在满载时运算会变慢，此运载比例也为经验值
gpuInfo = gpuDevice;                            % 获取当前 GPU 设备的信息
availableMemory = gpuInfo.AvailableMemory.*r;   % 获取最佳可用内存大小（以字节为单位）

%确定最佳收发天线矩阵
% 注意一个double类型的变量占8个字节，且comolex double 占16字节
no_ant = ceil (availableMemory/no_snap/(no_clusters*3 + freq_sample) )/8;   %rx数*tx数
n = round( log2(no_ant));                                                   %对2取对数
op_no_txant = 2^(round(n/2));                                               %确定最优tx天线数
op_no_rxant = 2^(n - round(n/2));                                          %确定最优rx天线数

end