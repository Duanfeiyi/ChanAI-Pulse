基于信道模型参数优化方法的信道生成

1. 基本使用流程
(1) 先确保 data 文件夹中已有 UM-MIMO.mat或其它DS_CDF文件。
(2) 运行 test_RL_channel_env_DS_v3.m，检查环境函数 RL_channel_env_DS_v3 是否可正常调用。
(3) 运行 example.m，生成信道矩阵样本，并绘制第一个快照的 PDP 与时延扩展 CDF。
(4) 如需对比不同参数配置，运行 Fig_channel_env_DS_v3.m。
(5) 如需搜索更优参数，运行 Gridsearch_DS_v3.m。
(6) 参数确定后，可调用 generate_channel_v1.m 批量生成 H 矩阵。

2. 目录结构
	example.m                        最小使用示例
	Fig_channel_env_DS_v3.m          DS 拟合结果对比绘图脚本
	generate_channel_v1.m            根据信道参数生成 H 矩阵
	Gridsearch_DS_v3.m               DS_v3 环境参数搜索脚本
	RL_channel_env_DS_v3.m           DS 拟合环境主函数

	工具函数和脚本：
	calc_capacity.m                  容量计算函数
	RL_calculate_common_error.m      仿真CDF与测量CDF公共误差计算函数
	test_RL_channel_env_DS_v3.m      DS_v3 环境测试脚本
	readme.txt                       说明文档

3. 文件说明
example.m
调用 generate_channel_v1.m，生成样本并绘制第一个快照的 PDP 和整体时延扩展 CDF，适合作为最基本的使用入口。

Fig_channel_env_DS_v3.m
对多组参数配置进行批量调用，读取测量数据并绘制 DS CDF 对比图。

generate_channel_v1.m
输入确定后的信道模型参数和生成个数 N，输出 N 个信道矩阵 H 及对应 delay。

Gridsearch_DS_v3.m
围绕给定起点和搜索范围，对 DS_v3 环境中的参数进行随机粗搜与局部搜索，以 NRMSE 为优化目标。

RL_channel_env_DS_v3.m
输入 DS_mu、DS_sigma、r_DS、num_clusters、num_rays、LNS_ksi、KF_mu、KF_sigma，输出 DS 拟合误差、状态向量和容量结果。

calc_capacity.m
根据 CIR 或信道响应计算容量，用于环境函数中的容量输出。

RL_calculate_common_error.m
将仿真结果与测量数据映射到公共横轴上，计算 NRMSE、KS distance 及对应CDF。

test_RL_channel_env_DS_v3.m
用于检查依赖、目标数据格式、底层 CIR 生成、DS 有效性以及环境函数整体输出是否正常。

实现功能：
1. 信道模型参数搜索：使用Gridsearch函数获取RL_channel_env_DS_v3环境下的最优参数配置
2. 基于6GPCM的信道生成：人工输入最佳参数（example）生成仿真信道矩阵和相应信道特性
