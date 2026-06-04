function build_installer()
%BUILD_INSTALLER Build ChanAI Pulse with MATLAB Compiler when available.
%
% This script is intentionally conservative:
% - public source, core helpers, docs, and synthetic demo data are included;
% - measured raw archives and extracted previews are never included;
% - if MATLAB Compiler APIs are unavailable, the script stops with guidance.

projectRoot = fileparts(fileparts(mfilename("fullpath")));
appMain = fullfile(projectRoot, "app", "ChannelSimulatorApp.m");
releaseRoot = fullfile(projectRoot, "release");
buildDir = fullfile(releaseRoot, "build");
testingDir = fullfile(releaseRoot, "for_testing");
redistributionDir = fullfile(releaseRoot, "for_redistribution");
logFile = fullfile(releaseRoot, "build_installer.log");

addpath(genpath(projectRoot));

if ~isfile(appMain)
    error("Main App file not found: %s", appMain);
end

ensureDir(buildDir);
ensureDir(testingDir);
ensureDir(redistributionDir);

diary(logFile);
cleanupDiary = onCleanup(@() diary("off"));

fprintf("ChanAI Pulse installer build\n");
fprintf("Project root: %s\n", projectRoot);
fprintf("MATLAB version: %s\n", version);
fprintf("Compiler license test: %d\n", license("test", "Compiler"));
fprintf("mcc path: %s\n", which("mcc"));
fprintf("deploytool path: %s\n", which("deploytool"));
fprintf("compiler.build.standaloneApplication path: %s\n", which("compiler.build.standaloneApplication"));

publicAdditionalFiles = {
    fullfile(projectRoot, "core")
    fullfile(projectRoot, "demo_data")
    fullfile(projectRoot, "docs")
    fullfile(projectRoot, "README.md")
    fullfile(projectRoot, "LICENSE")
    fullfile(projectRoot, "CITATION.cff")
    fullfile(projectRoot, "CHANGELOG.md")
    fullfile(projectRoot, "ROADMAP.md")
};

assertNoMeasuredData(publicAdditionalFiles);

if exist("compiler.build.standaloneApplication", "file") == 2
    fprintf("Using compiler.build.standaloneApplication workflow.\n");
    buildResults = compiler.build.standaloneApplication(appMain, ...
        "ExecutableName", "ChanAIPulse", ...
        "ExecutableVersion", "1.0.0", ...
        "OutputDir", buildDir, ...
        "AdditionalFiles", publicAdditionalFiles);

    if exist("compiler.package.installer", "file") == 2
        compiler.package.installer(buildResults, ...
            "InstallerName", "ChanAI Pulse", ...
            "InstallerVersion", "1.0.0", ...
            "OutputDir", redistributionDir);
    else
        fprintf("compiler.package.installer is unavailable; standalone build output remains in %s\n", buildDir);
    end
elseif exist("mcc", "file") == 2 || exist("mcc", "file") == 6
    fprintf("Using mcc fallback workflow.\n");
    args = {
        "-m"
        appMain
        "-d"
        testingDir
        "-o"
        "ChanAIPulse"
    };
    for i = 1:numel(publicAdditionalFiles)
        args = [args; {"-a"; publicAdditionalFiles{i}}]; %#ok<AGROW>
    end
    mcc(args{:});
    fprintf("mcc output written to: %s\n", testingDir);
    fprintf("Installer packaging may require deploytool or compiler.package.installer.\n");
else
    error(["MATLAB Compiler is not available in this MATLAB installation. " + ...
        "license('test','Compiler') may be positive, but mcc and compiler.build.* are not visible. " + ...
        "Install MATLAB Compiler or switch to a MATLAB installation that includes it."]);
end

fprintf("Build workflow completed.\n");
end

function ensureDir(pathValue)
if ~isfolder(pathValue)
    mkdir(pathValue);
end
end

function assertNoMeasuredData(files)
for i = 1:numel(files)
    text = lower(string(files{i}));
    if contains(text, "datasets" + filesep + "measured") || ...
            contains(text, "raw_archives") || contains(text, "extracted_preview")
        error("Measured dataset path must not be packaged: %s", files{i});
    end
end
end
