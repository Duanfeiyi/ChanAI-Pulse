# MATLAB Compiler 安装检测与打包报告

生成时间：2026-06-04

项目路径：

```text
D:\Codex_Feiyi\ChanAI Pulse
```

## 1. 结论摘要

当前未能生成 ChanAI Pulse 安装包。

原因不是 ChanAI Pulse 源码缺失，而是当前 MATLAB 安装中仍然没有可用的 MATLAB Compiler 产品文件和命令入口：

- `license('test','Compiler') = 1`
- `mcc` 不可见
- `deploytool` 不可见
- `compiler.build.standaloneApplication` 不可见
- `E:\matlab2022b\toolbox\compiler` 不存在
- `ver` / `matlab.addons.installedAddons` 均未列出 MATLAB Compiler

判断：授权大概率存在，但 MATLAB Compiler 产品尚未安装到当前 R2022b 环境，或该环境没有注册 Compiler 产品。

## 2. 系统与磁盘检查

检测到固定磁盘：

```text
C:\  Free: 87.24 GB
D:\  Free: 430.65 GB
E:\  Free: 640.11 GB
```

`E:\MATLAB` 存在，目录内容包括：

```text
E:\MATLAB\untitled6
E:\MATLAB\untitled9
```

E 盘空间足够安装 MATLAB Compiler。

## 3. MATLAB 环境检测

MATLAB：

```text
MATLAB R2022b Update 10
matlabroot = E:\matlab2022b
```

当前可见相关产品：

- MATLAB
- Simulink
- 5G Toolbox
- Communications Toolbox
- Deep Learning Toolbox
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- Wireless HDL Toolbox
- Wireless Testbench

当前不可见：

- MATLAB Compiler
- `mcc`
- `deploytool`
- `compiler.build.*`

命令结果摘要：

```matlab
license('test','Compiler')              % 1
which mcc -all                          % not found
which deploytool -all                   % not found
which compiler.build.standaloneApplication -all  % not found
```

## 4. 安装器与安装可行性检查

发现本机存在 MATLAB R2022b 安装器缓存：

```text
C:\Users\22595\Downloads\_temp_matlab_R2022b_win64\setup.exe
C:\Users\22595\Downloads\_temp_matlab_R2022b_win64\installer_input.txt
```

`installer_input.txt` 中包含可选产品项：

```text
product.MATLAB_Compiler
product.MATLAB_Compiler_SDK
```

但是：

- 安装器 `archives/` 中未发现名称包含 `compiler`、`deploy` 或 `mcc` 的离线产品包；
- 静默安装通常需要 `fileInstallationKey`、license file 或 MathWorks 登录；
- 当前环境没有可用的 file installation key；
- 不应绕过授权；
- 不应自动安装与 MATLAB Compiler 无关的大型产品。

因此当前不能安全地自动安装 MATLAB Compiler。需要人工打开 MathWorks 安装器，登录账号并确认授权后安装。

## 5. 是否只是路径问题

当前更像是“产品未安装”，不是单纯路径未加载。

理由：

- `E:\matlab2022b\toolbox\compiler` 不存在；
- `ver` 不列出 MATLAB Compiler；
- `matlab.addons.installedAddons` 不列出 MATLAB Compiler；
- `which mcc -all` 和 `which deploytool -all` 均为空。

如果 MATLAB Compiler 安装在其他 MATLAB 版本或其他目录，需要切换到对应 MATLAB 或重新注册路径。

## 6. 打包前项目检查

已确认项目存在：

```text
app/ChannelSimulatorApp.m
demo_data/demo_sub6_scenario1.mat
demo_data/demo_mmwave_scenario2.mat
README.md
LICENSE
```

打包脚本设计为只包含公开内容：

- `app/`
- `core/`
- `demo_data/`
- `docs/`
- README / LICENSE / CITATION / CHANGELOG / ROADMAP

明确不包含：

```text
datasets/measured/raw_archives/
datasets/measured/extracted_preview/
*.zip
*.rar
*.7z
```

## 7. build_installer.m 执行结果

已创建：

```text
release/build_installer.m
```

执行：

```matlab
run("release/build_installer.m")
```

结果：安全停止，未生成安装包。

报错核心内容：

```text
MATLAB Compiler is not available in this MATLAB installation.
license('test','Compiler') may be positive, but mcc and compiler.build.* are not visible.
Install MATLAB Compiler or switch to a MATLAB installation that includes it.
```

这是预期失败，说明脚本没有误打包，也没有把真实数据加入安装包。

## 8. 输出目录状态

脚本准备的输出目录为：

```text
release/build/
release/for_testing/
release/for_redistribution/
```

这些目录已加入 `.gitignore`，避免 build 产物误提交。

当前未生成 `.exe` 或 installer。

## 9. 需要人工操作

需要人工操作：

1. 打开 MathWorks 安装器；
2. 登录具备 MATLAB Compiler 授权的 MathWorks 账号；
3. 在当前 R2022b 安装 `E:\matlab2022b` 中添加 MATLAB Compiler；
4. 或安装/切换到一个已包含 MATLAB Compiler 的 MATLAB；
5. 安装完成后重新运行：

```matlab
ver
which mcc -all
which deploytool -all
license('test','Compiler')
which compiler.build.standaloneApplication -all
```

如果 `mcc` 或 `compiler.build.*` 可见，再运行：

```matlab
run("release/build_installer.m")
```

## 10. 后续建议

推荐顺序：

1. 人工安装 MATLAB Compiler；
2. 重新运行诊断；
3. 运行 `release/build_installer.m`；
4. 若生成 installer，将大型安装包保留在 `release/for_redistribution/`；
5. 不把 installer 直接提交 Git；
6. 未来通过 GitHub Release 上传安装包。

