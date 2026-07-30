function figureHandle = step6_generator_adapter_demo(options)
%STEP6_GENERATOR_ADAPTER_DEMO Standalone Step 6 review workbench.
%   This demo calls the real Step 6 Adapter API but remains isolated from
%   ChannelSimulatorApp. Formal UI integration remains Step 12.

arguments
    options.Visible (1, 1) string = "on"
    options.AutoRun (1, 1) logical = false
    options.Backend (1, 1) string = "mock"
    options.EngineRoot (1, 1) string = ""
end

root = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(root, "core")));

blue = [0.04, 0.29, 0.56];
green = [0.10, 0.58, 0.30];
orange = [0.93, 0.57, 0.10];
red = [0.78, 0.16, 0.16];
muted = [0.42, 0.46, 0.51];

figureHandle = uifigure( ...
    "Name", "ChanAI Pulse v3 - Step 6 Generator Adapter Demo", ...
    "Position", [40, 45, 1460, 850], ...
    "Color", [0.96, 0.97, 0.985], ...
    "Visible", options.Visible);
main = uigridlayout(figureHandle, [4, 1], ...
    "RowHeight", {54, 150, "1x", 30}, ...
    "Padding", [12, 10, 12, 10], "RowSpacing", 8);

header = uipanel(main, "BackgroundColor", [1, 1, 1], ...
    "BorderColor", [0.55, 0.70, 0.86]);
header.Layout.Row = 1;
headerGrid = uigridlayout(header, [1, 3], ...
    "ColumnWidth", {240, "1x", 340}, "Padding", [14, 4, 14, 4]);
uilabel(headerGrid, "Text", "◉ ChanAI Pulse", ...
    "FontSize", 18, "FontWeight", "bold", "FontColor", blue);
titleLabel = uilabel(headerGrid, ...
    "Text", "Step 6 · 共享信道生成服务", ...
    "HorizontalAlignment", "center", "FontSize", 18, ...
    "FontWeight", "bold", "FontColor", blue);
titleLabel.Layout.Column = 2;
uilabel(headerGrid, ...
    "Text", "独立功能 Demo · 不修改正式三模块 UI", ...
    "HorizontalAlignment", "right", "FontColor", muted);

controls = uipanel(main, "Title", "统一 GeneratorConfig", ...
    "FontWeight", "bold", "BackgroundColor", [1, 1, 1]);
controls.Layout.Row = 2;
controlsGrid = uigridlayout(controls, [3, 10], ...
    "RowHeight", {30, 30, 30}, ...
    "ColumnWidth", {70, 170, 58, 95, 74, 80, 48, 80, 95, "1x"}, ...
    "Padding", [12, 8, 12, 8], "ColumnSpacing", 7);

uilabel(controlsGrid, "Text", "生成器", "HorizontalAlignment", "right");
backendDrop = uidropdown(controlsGrid, ...
    "Items", ["Mock（测试）", "6GPCM-lite", "Full 6GPCM（外置）"], ...
    "ItemsData", ["mock", "lite_6gpcm", "full_6gpcm"], ...
    "Value", canonicalBackend(options.Backend), ...
    "ValueChangedFcn", @backendChanged);
uilabel(controlsGrid, "Text", "模式", "HorizontalAlignment", "right");
modeDrop = uidropdown(controlsGrid, "Items", ["Preview", "Formal"], ...
    "ItemsData", ["preview", "formal"], "Value", "preview");
uilabel(controlsGrid, "Text", "N_sample", "HorizontalAlignment", "right");
sampleField = uieditfield(controlsGrid, "numeric", ...
    "Limits", [1, 100], "RoundFractionalValues", "on");
uilabel(controlsGrid, "Text", "Nt", "HorizontalAlignment", "right");
timeField = uieditfield(controlsGrid, "numeric", ...
    "Limits", [1, 100], "RoundFractionalValues", "on");
ctfCheck = uicheckbox(controlsGrid, "Text", "同时生成 CTF", "Value", true);
ctfCheck.Layout.Column = [9, 10];

uilabel(controlsGrid, "Text", "外置路径", "HorizontalAlignment", "right");
rootField = uieditfield(controlsGrid, "text", ...
    "Value", options.EngineRoot, ...
    "Placeholder", "仅 Full 6GPCM 使用；不会写入导出 Manifest");
rootField.Layout.Column = [2, 8];
runButton = uibutton(controlsGrid, "push", "Text", "开始生成", ...
    "FontWeight", "bold", "BackgroundColor", blue, ...
    "FontColor", [1, 1, 1], "ButtonPushedFcn", @runGeneration);
runButton.Layout.Column = 9;
cancelButton = uibutton(controlsGrid, "push", "Text", "取消", ...
    "Enable", "off", "ButtonPushedFcn", @cancelGeneration);
cancelButton.Layout.Column = 10;

progress = uigauge(controlsGrid, "linear", "Limits", [0, 100], "Value", 0);
progress.Layout.Row = 3;
progress.Layout.Column = [1, 7];
statusBadge = uilabel(controlsGrid, "Text", "等待生成", ...
    "HorizontalAlignment", "center", "FontWeight", "bold", ...
    "BackgroundColor", [0.91, 0.93, 0.95], "FontColor", muted);
statusBadge.Layout.Row = 3;
statusBadge.Layout.Column = [8, 10];

body = uigridlayout(main, [1, 3], ...
    "ColumnWidth", {"1x", "1x", 390}, ...
    "Padding", [0, 0, 0, 0], "ColumnSpacing", 8);
body.Layout.Row = 3;
pdpPanel = uipanel(body, "Title", "生成 CIR · 平均 PDP", ...
    "BackgroundColor", [1, 1, 1]);
pdpAxes = uiaxes(pdpPanel, "Position", [48, 48, 420, 420]);
xlabel(pdpAxes, "时延 (ns)");
ylabel(pdpAxes, "归一化功率 (dB)");
grid(pdpAxes, "on");
renderEmpty(pdpAxes, "等待生成 CIR");

ctfPanel = uipanel(body, "Title", "可选 CTF · 频率/样本热力图", ...
    "BackgroundColor", [1, 1, 1]);
ctfAxes = uiaxes(ctfPanel, "Position", [52, 48, 420, 420]);
xlabel(ctfAxes, "样本");
ylabel(ctfAxes, "频率 (GHz)");
renderEmpty(ctfAxes, "等待生成 CTF");

detailPanel = uipanel(body, "Title", "状态、尺寸与后台事件", ...
    "BackgroundColor", [1, 1, 1]);
detailGrid = uigridlayout(detailPanel, [2, 1], ...
    "RowHeight", {190, "1x"}, "Padding", [8, 8, 8, 8]);
summaryArea = uitextarea(detailGrid, "Editable", "off", ...
    "FontName", "Microsoft YaHei UI", ...
    "Value", ["本 Demo 只验证统一接口和真实输出。"; ...
    "Mock 不代表物理信道，Full 缺失时不会自动改用 Lite。"]);
eventTable = uitable(detailGrid, ...
    "ColumnName", {"阶段", "进度", "消息"}, ...
    "ColumnWidth", {90, 55, 210}, "RowName", []);

footer = uilabel(main, ...
    "Text", "Step 6：模块二与模块三共用同一生成器接口；Grid Search/SA/预测模型尚未接入。", ...
    "BackgroundColor", [1, 1, 1], "FontColor", muted);
footer.Layout.Row = 4;

state = struct("cancel_requested", false);
backendChanged([], []);
if options.AutoRun
    drawnow;
    runGeneration([], []);
end

    function backendChanged(~, ~)
        config = default_generator_config(string(backendDrop.Value));
        sampleField.Value = config.dimensions.N_sample;
        timeField.Value = config.dimensions.Nt;
        rootField.Enable = onOff(backendDrop.Value == "full_6gpcm");
        if backendDrop.Value == "full_6gpcm" && ...
                strlength(strtrim(string(rootField.Value))) == 0
            rootField.Value = config.engine_root;
        end
    end

    function runGeneration(~, ~)
        config = default_generator_config(string(backendDrop.Value));
        config.mode = string(modeDrop.Value);
        config.dimensions.N_sample = sampleField.Value;
        config.dimensions.Nt = timeField.Value;
        config.engine_root = string(rootField.Value);
        config.ctf.enabled = logical(ctfCheck.Value);
        if config.ctf.enabled
            halfBandwidth = config.scenario.bandwidth_hz / 2;
            config.ctf.frequency_hz = linspace( ...
                config.scenario.center_frequency_hz - halfBandwidth, ...
                config.scenario.center_frequency_hz + halfBandwidth, 48).';
        end

        state.cancel_requested = false;
        runButton.Enable = "off";
        cancelButton.Enable = "on";
        progress.Value = 0;
        setStatus("RUNNING", "后台生成中…");
        drawnow;
        try
            result = run_generator_adapter(config, struct( ...
                "progress_callback", @showProgress, ...
                "cancel_check", @() state.cancel_requested));
            renderResult(result);
            figureHandle.UserData = result;
        catch exception
            setStatus("FAIL", "Demo 错误");
            figureHandle.UserData = struct( ...
                "success", false, ...
                "exception_identifier", string(exception.identifier), ...
                "exception_message", string(exception.message), ...
                "exception_stack", exception.stack);
            summaryArea.Value = cellstr( ...
                "Demo 回调失败：" + string(exception.message));
        end
        restoreButtons();
    end

    function cancelGeneration(~, ~)
        state.cancel_requested = true;
        cancelButton.Text = "正在取消…";
        drawnow;
    end

    function showProgress(event)
        progress.Value = event.progress * 100;
        statusBadge.Text = event.message;
        drawnow;
    end

    function restoreButtons()
        if isvalid(runButton)
            runButton.Enable = "on";
            cancelButton.Enable = "off";
            cancelButton.Text = "取消";
        end
    end

    function renderResult(result)
        setStatus(result.status, result.outcome + " · " + result.backend);
        eventData = table('Size', [numel(result.events), 3], ...
            'VariableTypes', {'string', 'string', 'string'}, ...
            'VariableNames', {'Phase', 'Progress', 'Message'});
        for eventIndex = 1:numel(result.events)
            eventData.Phase(eventIndex) = ...
                string(result.events(eventIndex).phase);
            eventData.Progress(eventIndex) = string(sprintf("%.0f%%", ...
                100 * result.events(eventIndex).progress));
            eventData.Message(eventIndex) = ...
                string(result.events(eventIndex).message);
        end
        eventTable.Data = eventData;

        lines = strings(0, 1);
        lines(end + 1) = "后端：" + result.backend;
        lines(end + 1) = "状态：" + result.status + " / " + result.outcome;
        lines(end + 1) = sprintf("耗时：%.3f s", result.runtime.elapsed_s);
        if result.success
            d = result.dataset.dimensions;
            lines(end + 1) = sprintf( ...
                "CIR：[Tx=%d, Rx=%d, Npath=%d, Nt=%d, N_sample=%d]", ...
                d.Tx, d.Rx, d.Npath, d.Nt, d.N_sample);
            if ~isempty(fieldnames(result.ctf_dataset))
                c = result.ctf_dataset.dimensions;
                lines(end + 1) = sprintf( ...
                    "CTF：[Tx=%d, Rx=%d, Nf=%d, Nt=%d, N_sample=%d]", ...
                    c.Tx, c.Rx, c.Nf, c.Nt, c.N_sample);
            end
        end
        if ~isempty(result.warnings)
            lines(end + 1) = "";
            lines(end + 1) = "提示：";
            warningLines = compose("· %s", string(result.warnings(:)));
            lines = [lines(:); warningLines(:)];
        end
        if ~isempty(result.errors)
            lines(end + 1) = "";
            lines(end + 1) = "错误：";
            errorLines = compose("· %s", string(result.errors(:)));
            lines = [lines(:); errorLines(:)];
        end
        summaryArea.Value = cellstr(lines);
        if result.success
            renderPdp(result.dataset);
            renderCtf(result.ctf_dataset);
        else
            renderEmpty(pdpAxes, "没有生成可用 CIR");
            renderEmpty(ctfAxes, "没有生成可用 CTF");
        end
    end

    function renderPdp(dataset)
        coefficient = dataset.cir.coefficient;
        delay = dataset.cir.delay_s;
        power = squeeze(mean(abs(coefficient).^2, [1, 2, 4, 5]));
        delayNs = squeeze(mean(delay, [1, 2, 4, 5])) * 1e9;
        powerDb = 10 * log10(power / max(power) + eps);
        stem(pdpAxes, delayNs, powerDb, ".", ...
            "Color", blue, "LineWidth", 1);
        xlabel(pdpAxes, "时延 (ns)");
        ylabel(pdpAxes, "归一化功率 (dB)");
        title(pdpAxes, "生成 CIR 的平均 PDP");
        grid(pdpAxes, "on");
    end

    function renderCtf(dataset)
        if isempty(fieldnames(dataset))
            renderEmpty(ctfAxes, "本次未请求 CTF");
            return;
        end
        H = dataset.ctf.H;
        power = squeeze(mean(abs(H).^2, [1, 2, 4]));
        if isvector(power)
            power = power(:);
        end
        powerDb = 10 * log10(power / max(power(:)) + eps);
        imagesc(ctfAxes, 1:size(powerDb, 2), ...
            dataset.axes.frequency_hz / 1e9, powerDb);
        axis(ctfAxes, "xy");
        colorbar(ctfAxes);
        xlabel(ctfAxes, "样本");
        ylabel(ctfAxes, "频率 (GHz)");
        title(ctfAxes, "CTF 归一化功率");
    end

    function setStatus(status, textValue)
        statusBadge.Text = textValue;
        switch string(status)
            case "PASS"
                statusBadge.BackgroundColor = [0.86, 0.96, 0.89];
                statusBadge.FontColor = green;
            case "WARNING"
                statusBadge.BackgroundColor = [1.00, 0.95, 0.82];
                statusBadge.FontColor = orange;
            case "FAIL"
                statusBadge.BackgroundColor = [1.00, 0.88, 0.88];
                statusBadge.FontColor = red;
            otherwise
                statusBadge.BackgroundColor = [0.90, 0.94, 0.99];
                statusBadge.FontColor = blue;
        end
    end
end

function renderEmpty(axesHandle, message)
cla(axesHandle);
axis(axesHandle, "off");
text(axesHandle, 0.5, 0.5, message, "Units", "normalized", ...
    "HorizontalAlignment", "center", "Color", [0.45, 0.48, 0.52]);
end

function value = onOff(condition)
if condition
    value = "on";
else
    value = "off";
end
end

function backend = canonicalBackend(value)
value = lower(string(value));
if contains(value, "full")
    backend = "full_6gpcm";
elseif contains(value, "lite")
    backend = "lite_6gpcm";
else
    backend = "mock";
end
end
