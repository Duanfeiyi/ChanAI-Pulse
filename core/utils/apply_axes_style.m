function apply_axes_style(ax, titleText, xLabelText, yLabelText, textColor)
%APPLY_AXES_STYLE Apply title and label styling used by the App.

title(ax, titleText, 'FontName', 'Times New Roman', 'FontSize', 16, ...
    'FontWeight', 'bold', 'Color', textColor);
if nargin > 2
    xlabel(ax, xLabelText, 'FontWeight', 'bold', 'FontSize', 15, ...
        'FontName', 'Times New Roman', 'Color', textColor);
    ylabel(ax, yLabelText, 'FontWeight', 'bold', 'FontSize', 15, ...
        'FontName', 'Times New Roman', 'Color', textColor);
end
end

