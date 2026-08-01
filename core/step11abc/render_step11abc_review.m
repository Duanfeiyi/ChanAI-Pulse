function outputs = render_step11abc_review(validationDirectory, outputDirectory)
%RENDER_STEP11ABC_REVIEW Render validation selection and frozen test result.

arguments
    validationDirectory (1, 1) string
    outputDirectory (1, 1) string
end
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
validationPath = fullfile(validationDirectory, ...
    "step11abc_validation_summary.csv");
testPath = fullfile(validationDirectory, "step11abc_test_summary.csv");
validation = readtable(validationPath, "TextType", "string");
test = table();
if isfile(testPath)
    test = readtable(testPath, "TextType", "string");
end
tasks = unique(validation.task_type, "stable");
outputs = strings(0, 1);
for task = tasks.'
    subset = validation(validation.task_type == task, :);
    [~, order] = sort(double(extractAfter(subset.bundle_name, "P")));
    subset = subset(order, :);
    figureHandle = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 1320 500]);
    tiledlayout(1, 2, "Padding", "compact", "TileSpacing", "compact");
    nexttile;
    bar(categorical(subset.bundle_name), subset.mean_pdp_nrmse, ...
        0.65, "FaceColor", [0.12 0.39 0.72]);
    ylabel("Validation PDP NRMSE (lower is better)");
    title(task + " — validation-only P-bundle selection");
    grid on;
    nexttile;
    if isempty(test)
        axis off;
        text(0.5, 0.5, "Final test not run yet", ...
            "HorizontalAlignment", "center", "FontSize", 15);
    else
        final = test(test.task_type == task, :);
        bar(categorical(final.bundle_name), final.mean_pdp_nrmse, ...
            0.45, "FaceColor", [0.18 0.62 0.36]);
        ylabel("Final test PDP NRMSE (lower is better)");
        title(task + " — frozen bundle, final test only");
        grid on;
    end
    outputPath = fullfile(outputDirectory, ...
        "step11abc_" + task + "_review.png");
    exportgraphics(figureHandle, outputPath, "Resolution", 160);
    close(figureHandle);
    outputs(end + 1, 1) = outputPath; %#ok<AGROW>
end
end
