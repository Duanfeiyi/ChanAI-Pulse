function outputFiles = render_step5_standard_review(outputDirectory, options)
%RENDER_STEP5_STANDARD_REVIEW Render four reproducible review sheets.

arguments
    outputDirectory (1, 1) string
    options.Visible (1, 1) string = "off"
end

root = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(root, "core")));
addpath(genpath(fullfile(root, "app")));
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

scenarios = load_v3_standard_scenarios();
outputFiles = strings(numel(scenarios), 1);
for scenarioIndex = 1:numel(scenarios)
    pair = generate_v3_standard_pair(scenarios(scenarioIndex));
    analysis = analyze_channel_characteristics(pair.cir, ...
        Region="all", ModuleRole="review");
    selected = select_channel_plot_entries(analysis.registry);
    plotCount = numel(selected);
    columnCount = min(3, max(plotCount, 1));
    rowCount = ceil(plotCount / columnCount);

    figureHandle = figure( ...
        "Visible", options.Visible, ...
        "Color", "white", ...
        "Position", [50, 50, 560 * columnCount, 380 * rowCount]);
    cleanup = onCleanup(@() closeIfValid(figureHandle));
    layout = tiledlayout(figureHandle, rowCount, columnCount, ...
        "TileSpacing", "compact", "Padding", "compact");
    for entry = selected.'
        axesHandle = nexttile(layout);
        render_channel_characteristic(axesHandle, analysis, entry.id);
    end
    title(layout, sprintf("%s｜标准特性 %d/%d｜附加图 %d", ...
        scenarios(scenarioIndex).display_name_zh, ...
        analysis.registry.available_standard_plot_count, ...
        analysis.registry.ideal_standard_plot_count, ...
        analysis.registry.available_additional_plot_count), ...
        "FontName", "Microsoft YaHei UI", "FontWeight", "bold");

    outputFiles(scenarioIndex) = fullfile(outputDirectory, ...
        string(scenarios(scenarioIndex).id) + "_step5_review.png");
    exportgraphics(figureHandle, outputFiles(scenarioIndex), ...
        "Resolution", 150);
    clear cleanup
end
end

function closeIfValid(figureHandle)
if isvalid(figureHandle)
    close(figureHandle);
end
end
