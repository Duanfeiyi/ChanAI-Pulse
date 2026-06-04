function init_axes_style(ax, textDimColor)
%INIT_AXES_STYLE Apply the standard ChanAI Pulse axes baseline style.

ax.FontName = 'Times New Roman';
ax.FontSize = 14;
ax.LineWidth = 0.8;
ax.Box = 'on';
ax.Color = [1 1 1];
ax.XColor = textDimColor;
ax.YColor = textDimColor;
grid(ax, 'on');
ax.GridAlpha = 0.15;
ax.GridColor = [0.8 0.8 0.8];
ax.XMinorGrid = 'off';
ax.YMinorGrid = 'off';
ax.TickDir = 'in';
ax.TickLength = [0.01 0.01];
try
    ax.XLimitMethod = 'tight';
catch
end
hold(ax, 'on');
end

