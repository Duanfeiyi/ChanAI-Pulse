function package_matlab_app()
%PACKAGE_MATLAB_APP Package ChanAI Pulse as a MATLAB App Package.
%
% The MATLAB App packaging API requires a valid app packaging .prj file.
% If release/matlab_app_package/ChanAI_Pulse.prj exists, this script packages
% it with matlab.apputil.package. Otherwise it stops and prints manual steps.

projectRoot = fileparts(fileparts(mfilename("fullpath")));
packageDir = fullfile(projectRoot, "release", "matlab_app_package");
assetDir = fullfile(projectRoot, "release", "github_release_assets");
projectFile = fullfile(packageDir, "ChanAI_Pulse.prj");
targetPackage = fullfile(packageDir, "ChanAI_Pulse_v1.0.0.mlappinstall");
assetPackage = fullfile(assetDir, "ChanAI_Pulse_v1.0.0.mlappinstall");

if ~isfolder(packageDir), mkdir(packageDir); end
if ~isfolder(assetDir), mkdir(assetDir); end

fprintf("ChanAI Pulse MATLAB App Package workflow\n");
fprintf("Project root: %s\n", projectRoot);
fprintf("Expected package project: %s\n", projectFile);

assertPublicPackagingInputs(projectRoot);

if ~isfile(projectFile)
    fprintf("\nNo App Packaging .prj file was found.\n");
    fprintf("Manual MATLAB steps are required:\n");
    fprintf("1. In MATLAB, run: addpath(genpath(pwd))\n");
    fprintf("2. Open APPS > Package App.\n");
    fprintf("3. Main file: app/ChannelSimulatorApp.m\n");
    fprintf("4. App name: ChanAI Pulse\n");
    fprintf("5. Version: 1.0.0\n");
    fprintf("6. Include public folders only: core, configs, demo_data, docs.\n");
    fprintf("7. Include README.md and LICENSE.\n");
    fprintf("8. Do NOT include legacy or datasets/measured.\n");
    fprintf("9. Save project as: %s\n", projectFile);
    fprintf("10. Package to: %s\n\n", targetPackage);
    error("Missing App Packaging project file. Manual packaging setup is required.");
end

matlab.apputil.package(projectFile);

if ~isfile(targetPackage)
    produced = dir(fullfile(packageDir, "*.mlappinstall"));
    if isempty(produced)
        error("Packaging finished but no .mlappinstall was found in %s", packageDir);
    end
    [~, idx] = max([produced.datenum]);
    targetPackage = fullfile(produced(idx).folder, produced(idx).name);
end

copyfile(targetPackage, assetPackage);
fprintf("Package copied to release asset: %s\n", assetPackage);
end

function assertPublicPackagingInputs(projectRoot)
required = [
    fullfile(projectRoot, "app", "ChannelSimulatorApp.m")
    fullfile(projectRoot, "core")
    fullfile(projectRoot, "demo_data", "demo_sub6_scenario1.mat")
    fullfile(projectRoot, "demo_data", "demo_mmwave_scenario2.mat")
    fullfile(projectRoot, "README.md")
    fullfile(projectRoot, "LICENSE")
];

for i = 1:numel(required)
    if ~(isfile(required(i)) || isfolder(required(i)))
        error("Required public packaging input missing: %s", required(i));
    end
end
end

