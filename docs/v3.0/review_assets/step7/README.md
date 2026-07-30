# Step 7 review assets

本目录保存 Step 7 Grid Search 的可复现人工审阅图片。

生成命令：

```matlab
addpath("examples");
render_step7_grid_search_review( ...
    "docs/v3.0/review_assets/step7", ...
    EngineRoot=getenv("CHANAI_FULL_6GPCM_ROOT"));
```

交互 Demo 截图由 `step7_grid_search_demo` 的隐藏窗口冒烟运行导出。

图片只用于功能审阅，不代表 Step 12 最终平台 UI。
