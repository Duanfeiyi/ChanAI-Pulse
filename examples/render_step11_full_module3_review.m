function outputPath = render_step11_full_module3_review( ...
        outputPath, pythonExecutable, engineRoot)
%RENDER_STEP11_FULL_MODULE3_REVIEW Render real Full 6GPCM module-three page.

arguments
    outputPath (1, 1) string = ""
    pythonExecutable (1, 1) string = "python"
    engineRoot (1, 1) string = string(getenv("CHANAI_FULL_6GPCM_ROOT"))
end
if strlength(strtrim(engineRoot)) == 0 || ~isfolder(engineRoot)
    error("render_step11_full_module3_review:MissingEngine", ...
        "Provide the extracted Full 6GPCM engineRoot.");
end
root = fileparts(fileparts(mfilename("fullpath")));
if strlength(outputPath) == 0
    outputPath = fullfile(root, "docs", "v3.0", "review_assets", ...
        "step11", "step11_module3_full_demo.png");
end
outputDirectory = fileparts(outputPath);
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
figureHandle = step11_module3_demo( ...
    "Visible", "off", ...
    "PythonExecutable", pythonExecutable, ...
    "TaskType", "extrapolation", ...
    "Backend", "full_6gpcm", ...
    "EngineRoot", engineRoot, ...
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
