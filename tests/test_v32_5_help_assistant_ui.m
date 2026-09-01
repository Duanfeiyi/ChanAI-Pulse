% v3.2-5 Help Assistant UI regression (headless), mirroring repo test style:
% UI controls are located through findall because app properties/methods
% are private by design; user actions are simulated via callback handles.
clearvars;
repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, "core")));

fprintf("== Help Assistant UI smoke test ==\n");

app = ChannelSimulatorV3App(Visible="off");
cleanup = onCleanup(@() delete(app));
fprintf("[PASS] app constructed\n");

% 1) The floating ? button exists.
helpButton = findButton(app.UIFigure, "?");
assert(~isempty(helpButton), "floating help button not found");
fprintf("[PASS] floating help button found\n");

% 2) Click it -> panel opens, button turns into X.
feval(helpButton.ButtonPushedFcn, helpButton, struct());
helpPanel = findPanelWithTitle(app.UIFigure, "帮助");
assert(~isempty(helpPanel), "help panel not found after toggle");
assert(strcmp(helpPanel.Visible, "on"), "panel must be visible");
assert(strcmp(helpButton.Text, "✕"), "button text must become X");
fprintf("[PASS] toggle open works (panel visible)\n");

% 3) Question list holds 10 zh items; answer area has content.
questionList = findListBox(app.UIFigure);
assert(~isempty(questionList), "question listbox not found");
assert(numel(questionList.Items) == 10, ...
    "expected 10 questions, got %d", numel(questionList.Items));
assert(contains(questionList.Items{1}, "导入"), ...
    "first question should be Chinese by default: %s", questionList.Items{1});
answerArea = findTextArea(app.UIFigure);
assert(~isempty(answerArea) && strlength(string(answerArea.Value)) > 0, ...
    "answer area must show content");
fprintf("[PASS] 10 zh questions + answer rendered\n");

% 4) Select question 2 -> answer updates.
questionList.Value = 2;
feval(questionList.ValueChangedFcn, questionList, struct());
assert(contains(string(answerArea.Value), "任务类型"), ...
    "answer for question 2 must mention task type");
fprintf("[PASS] answer updates on selection\n");

% 5) Language switch to English via the public dropdown.
langDropdown = findDropdown(app.UIFigure, "中文");
assert(~isempty(langDropdown), "language dropdown not found");
langDropdown.Value = "English";
feval(langDropdown.ValueChangedFcn, langDropdown, struct());
assert(contains(questionList.Items{1}, "How do I import"), ...
    "questions must switch to English: %s", questionList.Items{1});
assert(strcmp(helpPanel.Title, "❓ Operation Help"), ...
    "panel title must switch to English: %s", helpPanel.Title);
fprintf("[PASS] language switch updates questions + panel title\n");

% 6) Close via the close button (English label after language switch).
closeButton = findButton(app.UIFigure, "✕ Close");
assert(~isempty(closeButton), "close button not found");
feval(closeButton.ButtonPushedFcn, closeButton, struct());
assert(strcmp(helpPanel.Visible, "off"), "panel must hide after close");
assert(strcmp(helpButton.Text, "?"), "button text must revert to ?");
fprintf("[PASS] toggle close works\n");

% 7) Layout anchoring: button stays inside the figure.
fp = app.UIFigure.Position;
bp = helpButton.Position;
assert(bp(1) >= 0 && bp(2) >= 0 && ...
    bp(1) + bp(3) <= fp(3) && bp(2) + bp(4) <= fp(4), ...
    "help button must stay inside the figure (button=[%d,%d] fig=[%d,%d])", ...
    round(bp(1)), round(bp(2)), round(fp(3)), round(fp(4)));
% Bottom-right anchor: button right edge near figure right edge, bottom near bottom.
margin = 24; buttonSize = 54;
assert(abs((bp(1) + bp(3)) - (fp(3) - margin)) < 5, ...
    "button right edge must sit at figure right minus margin");
assert(abs(bp(2) - margin) < 5, ...
    "button bottom must sit at margin");
fprintf("[PASS] layout anchoring (button=[%d,%d], fig=%dx%d)\n", ...
    round(bp(1)), round(bp(2)), round(fp(3)), round(fp(4)));

fprintf("ALL HELP ASSISTANT UI SMOKE TESTS PASSED\n");

function btn = findButton(fig, text)
btn = [];
allButtons = findall(fig, "Type", "uibutton");
for i = 1:numel(allButtons)
    if strcmp(allButtons(i).Text, text)
        btn = allButtons(i);
        return;
    end
end
end

function p = findPanelWithTitle(fig, keyword)
p = [];
allPanels = findall(fig, "Type", "uipanel");
for i = 1:numel(allPanels)
    if contains(string(allPanels(i).Title), keyword)
        p = allPanels(i);
        return;
    end
end
end

function lb = findListBox(fig)
lb = [];
allLists = findall(fig, "Type", "uilistbox");
if ~isempty(allLists)
    lb = allLists(1);
end
end

function ta = findTextArea(fig)
ta = [];
allAreas = findall(fig, "Type", "uitextarea");
for i = 1:numel(allAreas)
    if strcmp(allAreas(i).Editable, "off")
        ta = allAreas(i);
        return;
    end
end
end

function dd = findDropdown(fig, itemText)
dd = [];
allDrops = findall(fig, "Type", "uidropdown");
for i = 1:numel(allDrops)
    if any(strcmp(string(allDrops(i).Items), itemText))
        dd = allDrops(i);
        return;
    end
end
end
