% ChanAI Pulse v1.0 smoke test.
% This script performs non-destructive checks for the MATLAB environment,
% required toolboxes, optional demo data, and app availability.
%
% GUI launch and tab switching are optional because MATLAB batch mode can hang
% on some desktop environments. To enable the GUI check, set:
%   setenv("CHANAI_GUI_SMOKE", "1")

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
appDir = fullfile(repoRoot, "app");
demoDir = fullfile(repoRoot, "demo_data");

fprintf("ChanAI Pulse smoke test\n");
fprintf("Repository root: %s\n", repoRoot);
fprintf("MATLAB version: %s\n", version);

addpath(appDir);

installed = ver;
installedNames = string({installed.Name});

checks = struct();
checks.matlabVersion = version;
checks.hasDeepLearningToolbox = any(installedNames == "Deep Learning Toolbox");
checks.hasSignalProcessingToolbox = any(installedNames == "Signal Processing Toolbox");
checks.hasStatisticsToolbox = any(installedNames == "Statistics and Machine Learning Toolbox");
checks.hasMatlabCompilerLicense = license("test", "Compiler") == 1;
checks.hasMatlabCompilerProduct = any(installedNames == "MATLAB Compiler");
checks.hasMccOnPath = exist("mcc", "file") > 0;
checks.hasStandaloneApplicationApi = exist("compiler.build.standaloneApplication", "file") > 0;
checks.appFileExists = isfile(fullfile(appDir, "ChannelSimulatorApp.m"));
checks.demoDataExists = isfile(fullfile(demoDir, "demo_sub6_scenario1.mat")) || ...
    isfile(fullfile(demoDir, "demo_mmwave_scenario2.mat"));
checks.guiSmokeRequested = strcmp(getenv("CHANAI_GUI_SMOKE"), "1");

fprintf("\nEnvironment checks:\n");
printCheck("Deep Learning Toolbox", checks.hasDeepLearningToolbox);
printCheck("Signal Processing Toolbox", checks.hasSignalProcessingToolbox);
printCheck("Statistics and Machine Learning Toolbox", checks.hasStatisticsToolbox);
printCheck("MATLAB Compiler license test", checks.hasMatlabCompilerLicense);
printCheck("MATLAB Compiler product installed", checks.hasMatlabCompilerProduct);
printCheck("mcc available on path", checks.hasMccOnPath);
printCheck("compiler.build.standaloneApplication available", checks.hasStandaloneApplicationApi);
printCheck("App file exists", checks.appFileExists);
printCheck("Demo data exists", checks.demoDataExists);

checks.appLaunches = false;
checks.hasThreeTabs = false;
checks.tabsSwitch = false;

if checks.guiSmokeRequested
    app = [];
    try
        fprintf("\nLaunching app for optional GUI smoke check...\n");
        app = ChannelSimulatorApp;
        drawnow;

        checks.appLaunches = true;
        checks.hasThreeTabs = numel(app.TabGroup.Children) == 3;

        if checks.hasThreeTabs
            app.TabGroup.SelectedTab = app.DataImportTab;
            drawnow;
            app.TabGroup.SelectedTab = app.ChannelGenTab;
            drawnow;
            app.TabGroup.SelectedTab = app.ChannelPredTab;
            drawnow;
            checks.tabsSwitch = true;
        end

        printCheck("App launches", checks.appLaunches);
        printCheck("Three tabs detected", checks.hasThreeTabs);
        printCheck("Tabs switch", checks.tabsSwitch);
    catch ME
        fprintf(2, "Optional app GUI smoke check failed: %s\n", ME.message);
    end

    if ~isempty(app)
        try
            delete(app);
        catch
        end
    end
else
    fprintf("\nSkipping GUI launch check. Set CHANAI_GUI_SMOKE=1 to enable it.\n");
end

requiredChecks = [
    checks.hasDeepLearningToolbox
    checks.hasSignalProcessingToolbox
    checks.hasStatisticsToolbox
    checks.appFileExists
];

if checks.guiSmokeRequested
    requiredChecks = [
        requiredChecks
        checks.appLaunches
        checks.hasThreeTabs
        checks.tabsSwitch
    ];
end

fprintf("\nSmoke test summary:\n");
if all(requiredChecks)
    fprintf("PASS: core environment and GUI checks passed.\n");
else
    fprintf(2, "FAIL: one or more required checks failed.\n");
    error("ChanAI Pulse smoke test failed.");
end

if ~checks.demoDataExists
    fprintf("NOTE: demo data is not present yet. This is expected in stage 1.\n");
end

if ~checks.hasMatlabCompilerProduct || ~checks.hasMccOnPath
    fprintf("NOTE: MATLAB Compiler packaging is not available on the current MATLAB path.\n");
end

function printCheck(name, ok)
if ok
    status = "OK";
else
    status = "MISSING";
end
fprintf("  %-55s %s\n", name + ":", status);
end
