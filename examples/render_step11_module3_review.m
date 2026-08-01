function outputPath = render_step11_module3_review(outputPath, pythonExecutable)
%RENDER_STEP11_MODULE3_REVIEW Render the Step 11 formal-style module page.

arguments
    outputPath (1, 1) string = ""
    pythonExecutable (1, 1) string = "python"
end
root = fileparts(fileparts(mfilename("fullpath")));
if strlength(outputPath) == 0
    outputPath = fullfile(root, "docs", "v3.0", "review_assets", ...
        "step11", "step11_module3_demo.png");
end
outputDirectory = fileparts(outputPath);
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
figureHandle = step11_module3_demo( ...
    "Visible", "off", ...
    "PythonExecutable", pythonExecutable, ...
    "TaskType", "extrapolation", ...
    "Backend", "lite_6gpcm", ...
    "AutoRun", true);
cleanup = onCleanup(@() closeIfValid(figureHandle));
drawnow;
exportapp(figureHandle, outputPath);
end

function closeIfValid(figureHandle)
if isvalid(figureHandle)
    close(figureHandle);
end
end
