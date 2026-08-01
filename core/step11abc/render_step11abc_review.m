function outputs = render_step11abc_review(validationDirectory, outputDirectory)
%RENDER_STEP11ABC_REVIEW Render external-only Step 11ABC review figures.

arguments
    validationDirectory (1, 1) string
    outputDirectory (1, 1) string
end
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
summary = readtable(fullfile(validationDirectory, "step11abc_end_to_end_summary.csv"), "TextType", "string");
tasks = unique(summary.task_type, "stable");
outputs = strings(0, 1);
for task = tasks.'
    subset = summary(summary.task_type == task, :);
    [~, order] = sort(double(extractAfter(subset.bundle_name, "P")));
    subset = subset(order, :);
    figureHandle = figure("Visible", "off", "Color", "w", "Position", [100 100 1250 500]);
    tiledlayout(1, 2, "Padding", "compact", "TileSpacing", "compact");
    nexttile;
    bar(categorical(subset.bundle_name), subset.mean_pdp_nrmse, 0.65, "FaceColor", [0.12 0.39 0.72]);
    ylabel("PDP NRMSE (lower is better)");
    title(task + " — end-to-end CIR characteristic error");
    grid on;
    nexttile;
    bar(categorical(subset.bundle_name), subset.mean_parameter_nrmse, 0.65, "FaceColor", [0.91 0.48 0.12]);
    ylabel("parameter NRMSE (lower is better)");
    title(task + " — predicted/baseline parameter error");
    grid on;
    outputPath = fullfile(outputDirectory, "step11abc_" + task + "_review.png");
    exportgraphics(figureHandle, outputPath, "Resolution", 160);
    close(figureHandle);
    outputs(end + 1, 1) = outputPath; %#ok<AGROW>
end
end
