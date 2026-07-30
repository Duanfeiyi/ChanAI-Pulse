function outputPath = render_step10_module3_review(outputPath, pythonExecutable)
%RENDER_STEP10_MODULE3_REVIEW Render the real Step 10 product-page skeleton.

arguments
    outputPath (1, 1) string = ""
    pythonExecutable (1, 1) string = "python"
end
root = fileparts(fileparts(mfilename("fullpath")));
if strlength(outputPath) == 0
    outputPath = fullfile(root, "docs", "v3.0", "review_assets", ...
        "step10", "step10_module3_demo.png");
end
outputDirectory = fileparts(outputPath);
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
figureHandle = step10_module3_demo( ...
    "Visible", "off", ...
    "PythonExecutable", pythonExecutable, ...
    "TaskType", "extrapolation", ...
    "AutoRun", true);
cleanup = onCleanup(@() close(figureHandle));
drawnow;
exportapp(figureHandle, outputPath);
end
