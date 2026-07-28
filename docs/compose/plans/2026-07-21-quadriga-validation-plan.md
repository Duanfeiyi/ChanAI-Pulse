# Step V2-1: 数据集生成验证方案

**日期：** 2026-07-21
**目标：** 验证 QuaDRiGa 生成管线的正确性、可复现性和数据质量

---

## 一、验证层级

```
Level 1: 环境检查（无 QuaDRiGa 也可运行）
Level 2: 配置与场景验证（无 QuaDRiGa 也可运行）
Level 3: 生成器功能验证（需要 QuaDRiGa）
Level 4: 数据质量验证（需要 QuaDRiGa + 生成数据）
Level 5: 端到端管线验证（完整流程）
```

---

## 二、Level 1: 环境检查验证

### 2.1 在 MATLAB 中运行

```matlab
% 添加路径
addpath(genpath('core/generation/quadriga'));

% 运行环境检查
status = quadriga_check();
disp(status);
```

### 2.2 预期结果

| 字段 | QuaDRiGa 已安装 | QuaDRiGa 未安装 |
|---|---|---|
| `is_available` | `true` | `false` |
| `version` | 版本号 (如 "2.6") | `""` |
| `issues` | `{}"` (空) | 包含错误描述 |
| `summary` | "QuaDRiGa environment OK" | "QuaDRiGa NOT available" |

### 2.3 验收标准

- [ ] `quadriga_check()` 无报错
- [ ] 返回 struct 包含所有字段
- [ ] QuaDRiGa 未安装时 issues 有明确描述

---

## 三、Level 2: 配置与场景验证

### 3.1 场景注册表验证

```matlab
% 测试所有 6 个场景
scenarios = ["3GPP_38.901_UMi", "3GPP_38.901_UMi-LOS", ...
             "3GPP_38.901_UMa", "3GPP_38.901_UMa-LOS", ...
             "3GPP_38.901_RMa", "3GPP_38.901_INH"];

for s = scenarios
    sc = quadriga_scenarios(s);
    fprintf('✓ %s: BS=%dm, Speed=%.2fm/s, Clusters=%d, Environment=%s\n', ...
        sc.name, sc.bs_height_m, sc.ue_speed_mps, sc.num_clusters, sc.environment);
end

% 测试未知场景的错误处理
try
    quadriga_scenarios("Unknown_Scenario");
    error('应该报错但没有');
catch ME
    fprintf('✓ 未知场景正确报错: %s\n', ME.message);
end
```

### 3.2 默认配置验证

```matlab
% 测试默认配置
cfg = default_quadriga_config();
assert(cfg.num_subcarriers == 64, '默认子载波数应为 64');
assert(cfg.random_seed == 42, '默认随机种子应为 42');
assert(cfg.snapshots == 100, '默认快拍数应为 100');
assert(cfg.bandwidth_mhz == 100, '默认带宽应为 100 MHz');
fprintf('✓ 默认配置验证通过\n');

% 测试配置验证与填充
cfg = default_quadriga_config();
cfg = validate_quadriga_config(cfg);
assert(cfg.bs_height_m == 10, 'UMi BS 高度应自动填充为 10m');
assert(cfg.num_clusters == 12, 'UMi 簇数应自动填充为 12');
fprintf('✓ 配置验证与自动填充通过\n');

% 测试无效配置的错误处理
cfg = default_quadriga_config();
cfg.num_subcarriers = -1;
try
    validate_quadriga_config(cfg);
    error('应该报错但没有');
catch
    fprintf('✓ 无效配置正确报错\n');
end
```

### 3.3 验收标准

- [ ] 6 个场景全部加载无误
- [ ] 每个场景的物理参数合理（BS 高度、UE 速度、簇数）
- [ ] 未知场景返回明确错误
- [ ] 默认配置字段完整
- [ ] `validate_quadriga_config` 正确填充空字段
- [ ] 无效配置返回明确错误

---

## 四、Level 3: 生成器功能验证（需要 QuaDRiGa）

### 4.1 基础生成测试

```matlab
env = quadriga_check();
if ~env.is_available
    error('QuaDRiGa 未安装，跳过 Level 3 验证');
end

% 最小配置测试
cfg = default_quadriga_config();
cfg.snapshots = 10;
cfg.num_subcarriers = 16;
cfg.random_seed = 42;

result = quadriga_adapter(cfg);

% 验证结果结构
assert(isfield(result, 'complex_h'), '缺少 complex_h 字段');
assert(isfield(result, 'time_axis_s'), '缺少 time_axis_s 字段');
assert(isfield(result, 'freq_axis_hz'), '缺少 freq_axis_hz 字段');
assert(isfield(result, 'engine'), '缺少 engine 字段');
assert(result.engine == "QuaDRiGa", 'engine 应为 QuaDRiGa');
fprintf('✓ 基础生成测试通过\n');
```

### 4.2 维度一致性测试

```matlab
cfg = default_quadriga_config();
cfg.snapshots = 20;
cfg.num_subcarriers = 32;
result = quadriga_adapter(cfg);

assert(isequal(size(result.complex_h), [20, 32]), ...
    sprintf('维度错误: 期望 [20,32], 实际 [%d,%d]', ...
    size(result.complex_h, 1), size(result.complex_h, 2)));
assert(length(result.time_axis_s) == 20, '时间轴长度应为 20');
assert(length(result.freq_axis_hz) == 32, '频率轴长度应为 32');
fprintf('✓ 维度一致性测试通过\n');
```

### 4.3 复数性测试

```matlab
cfg = default_quadriga_config();
cfg.snapshots = 10;
cfg.num_subcarriers = 16;
result = quadriga_adapter(cfg);

assert(iscomplex(result.complex_h), 'complex_h 应为复数');
assert(~isreal(result.complex_h), 'complex_h 不应为实数');
assert(any(imag(result.complex_h) ~= 0), 'complex_h 应有非零虚部');
fprintf('✓ 复数性测试通过\n');
```

### 4.4 种子可复现性测试

```matlab
cfg = default_quadriga_config();
cfg.snapshots = 10;
cfg.num_subcarriers = 16;
cfg.random_seed = 123;

result1 = quadriga_adapter(cfg);
result2 = quadriga_adapter(cfg);

assert(isequal(result1.complex_h, result2.complex_h), ...
    '相同种子未产生相同输出');
assert(isequal(result1.time_axis_s, result2.time_axis_s), ...
    '相同种子未产生相同时间轴');
fprintf('✓ 种子可复现性测试通过\n');
```

### 4.5 物理轴合理性测试

```matlab
cfg = default_quadriga_config();
cfg.snapshots = 10;
cfg.num_subcarriers = 16;
cfg.carrier_freq_ghz = 3.5;
cfg.bandwidth_mhz = 100;
result = quadriga_adapter(cfg);

% 时间轴应严格递增
assert(all(diff(result.time_axis_s) > 0), '时间轴应严格递增');
% 时间间隔应为 10ms
assert(all(abs(diff(result.time_axis_s) - 0.01) < 1e-10), ...
    '时间间隔应为 0.01s (10ms)');

% 频率轴应关于 0 对称
assert(abs(result.freq_axis_hz(1) + result.freq_axis_hz(end)) < 1e-6, ...
    '频率轴应关于 0 对称');
% 频率范围应为带宽
freq_range = result.freq_axis_hz(end) - result.freq_axis_hz(1);
assert(abs(freq_range - 100e6) < 1e-6, '频率范围应等于带宽 100MHz');

fprintf('✓ 物理轴合理性测试通过\n');
```

### 4.6 验收标准

- [ ] 基础生成无报错，返回完整结果 struct
- [ ] `complex_h` 维度 = `[snapshots, num_subcarriers]`
- [ ] `complex_h` 为复数且有非零虚部
- [ ] 相同种子 + 相同配置 → 完全相同的输出
- [ ] 时间轴严格递增，间隔 = `snapshot_interval_s`
- [ ] 频率轴关于 0 对称，范围 = 带宽
- [ ] BS 位置和 UE 轨迹非空

---

## 五、Level 4: 数据质量验证（需要生成数据集）

### 5.1 生成完整 Demo 数据集

```matlab
% 生成 3 个场景的 demo 数据
generate_quadriga_demo();
```

### 5.2 验证生成的文件

```matlab
demoDir = fullfile(pwd, 'demo_data', 'quadriga_demo');
dataDir = fullfile(demoDir, 'data');

% 检查 metadata.json
assert(exist(fullfile(demoDir, 'metadata.json'), 'file') > 0, ...
    '缺少 metadata.json');
meta = jsondecode(fileread(fullfile(demoDir, 'metadata.json')));
assert(meta.version == "1.0", '版本应为 1.0');
assert(meta.generator == "QuaDRiGa", '生成器应为 QuaDRiGa');
assert(numel(meta.files) >= 3, '应至少有 3 个文件');

% 检查 .mat 文件
files = dir(fullfile(dataDir, '*.mat'));
assert(numel(files) >= 3, '应至少有 3 个 .mat 文件');

for idx = 1:numel(files)
    loaded = load(fullfile(dataDir, files(idx).name));
    assert(isfield(loaded, 'result'), '缺少 result 字段');
    assert(isfield(loaded.result, 'complex_h'), '缺少 complex_h');
    assert(iscomplex(loaded.result.complex_h), 'complex_h 应为复数');
    fprintf('  ✓ %s: %dx%d complex_h\n', files(idx).name, ...
        size(loaded.result.complex_h, 1), size(loaded.result.complex_h, 2));
end
fprintf('✓ 文件验证通过\n');
```

### 5.3 时间连续性验证

```matlab
% 验证相邻快拍的相位连续性
loaded = load(fullfile(dataDir, files(1).name));
h = loaded.result.complex_h;

% 计算相邻快拍的相位差
phase = angle(h);
phase_diff = abs(diff(phase, 1, 1));
% 相位差应在合理范围内（不是随机跳变）
mean_phase_diff = mean(phase_diff(:));
assert(mean_phase_diff < pi, '相邻快拍相位差应小于 π');
fprintf('✓ 时间连续性验证通过 (平均相位差: %.4f rad)\n', mean_phase_diff);
```

### 5.4 多场景一致性验证

```matlab
% 验证不同场景的物理参数差异
scenarios = {'3GPP_38.901_UMi', '3GPP_38.901_UMa', '3GPP_38.901_INH'};
bw_values = [100, 200, 400];  % MHz

for idx = 1:numel(scenarios)
    cfg = default_quadriga_config();
    cfg.scenario = scenarios{idx};
    cfg.bandwidth_mhz = bw_values(idx);
    cfg.snapshots = 10;
    cfg.num_subcarriers = 16;
    
    result = quadriga_adapter(cfg);
    
    % 验证带宽影响频率轴
    freq_range = result.freq_axis_hz(end) - result.freq_axis_hz(1);
    expected_range = bw_values(idx) * 1e6;
    assert(abs(freq_range - expected_range) < 1e-6, ...
        sprintf('%s 频率范围错误', scenarios{idx}));
    
    fprintf('  ✓ %s: %.1f MHz → freq range %.0f MHz\n', ...
        scenarios{idx}, bw_values(idx), freq_range/1e6);
end
fprintf('✓ 多场景一致性验证通过\n');
```

### 5.5 验收标准

- [ ] `generate_quadriga_demo()` 无报错生成 3 个文件
- [ ] `metadata.json` 包含完整元数据
- [ ] 每个 .mat 文件包含 `result` struct 和 `complex_h`
- [ ] 相邻快拍相位连续（平均相位差 < π）
- [ ] 不同场景/带宽产生不同频率轴范围
- [ ] 所有文件可被 MATLAB `load()` 正确加载

---

## 六、Level 5: 端到端管线验证

### 6.1 Legacy 兼容性验证

```matlab
% 验证 DPSD 转换
cfg = default_quadriga_config();
cfg.snapshots = 20;
cfg.num_subcarriers = 32;
result = quadriga_adapter(cfg);

% 转换为 DPSD
dpsd = quadriga_result_to_dpsd(result);
assert(size(dpsd, 1) == 20, 'DPSD 快拍数应为 20');
assert(size(dpsd, 2) == 32, 'DPSD 延迟 bin 数应为 32');
assert(all(dpsd(:) <= 0), 'DPSD 应为 dB 值 (<=0)');
fprintf('✓ DPSD 转换验证通过\n');

% 转换为 Complex-H
[ch, t, f] = quadriga_result_to_complex_h(result);
assert(isequal(ch, result.complex_h), '提取的 complex_h 应与原始一致');
fprintf('✓ Complex-H 提取验证通过\n');
```

### 6.2 多算法基线兼容验证

```matlab
% 验证生成的数据可被现有预处理管道使用
cfg = default_quadriga_config();
cfg.snapshots = 50;
cfg.num_subcarriers = 64;
result = quadriga_adapter(cfg);

% 验证幅度谱
amplitude = abs(result.complex_h);
assert(all(amplitude(:) >= 0), '幅度应非负');
assert(~all(amplitude(:) == 0), '幅度不应全为零');

% 验证功率谱
power = amplitude.^2;
total_power = sum(power(:));
assert(isfinite(total_power) && total_power > 0, '总功率应为正有限值');
fprintf('✓ 幅度与功率谱验证通过\n');
```

### 6.3 验收标准

- [ ] DPSD 转换正确（维度匹配，值为 dB）
- [ ] Complex-H 提取正确
- [ ] 幅度谱非负且非全零
- [ ] 功率谱为正有限值
- [ ] 生成数据可被现有预处理管道使用

---

## 七、自动化测试运行

### 7.1 运行完整测试套件

```matlab
% 运行所有测试
results = test_quadriga_adapter();

% 检查结果
fprintf('\n测试结果:\n');
fprintf('  通过: %d\n', results.passed);
fprintf('  失败: %d\n', results.failed);
fprintf('  跳过: %d\n', results.skipped);

if results.failed == 0
    fprintf('\n✓ 所有测试通过!\n');
else
    fprintf('\n✗ 有 %d 个测试失败\n', results.failed);
end
```

### 7.2 预期结果（QuaDRiGa 未安装时）

| 测试 | 状态 |
|---|---|
| Environment Check | PASS |
| Scenario Registry (6 scenarios) | PASS |
| Default Config & Validation | PASS |
| QuaDRiGa Adapter (requires QuaDRiGa) | SKIP |
| Seed Reproducibility | SKIP |
| Complex-valued H(t,f) | SKIP |
| Dimension Consistency | SKIP |
| Multi-band Support | SKIP |

预期: 3 PASS, 5 SKIP, 0 FAIL

### 7.3 预期结果（QuaDRiGa 已安装时）

预期: 8 PASS, 0 SKIP, 0 FAIL

---

## 八、验证报告模板

完成验证后，填写以下报告：

```markdown
# QuaDRiGa Pipeline 验证报告

**日期：** YYYY-MM-DD
**验证人：** 
**QuaDRiGa 版本：** 
**MATLAB 版本：** 

## 环境检查
- [ ] quadriga_check() 通过
- [ ] QuaDRiGa 版本: ___
- [ ] MATLAB 版本: ___

## Level 1-2: 配置验证
- [ ] 6 个场景加载正常
- [ ] 默认配置正确
- [ ] 配置验证正常

## Level 3: 生成器验证
- [ ] 基础生成正常
- [ ] 维度正确 [T, F]
- [ ] 复数性确认
- [ ] 种子可复现
- [ ] 物理轴合理

## Level 4: 数据质量
- [ ] Demo 数据集生成正常
- [ ] metadata.json 完整
- [ ] 时间连续性确认
- [ ] 多场景一致性确认

## Level 5: 端到端
- [ ] DPSD 转换正常
- [ ] Complex-H 提取正常
- [ ] 幅度/功率谱正常

## 问题记录
- 无 / 有问题描述

## 结论
- 通过 / 有条件通过 / 不通过
```
