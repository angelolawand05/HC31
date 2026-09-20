function overlaySubepochLines(ax, R, run1IntervalUs)
if ~isfield(R, 'sectInt') || isempty(R.sectInt)
    return;
end
yl = ylim(ax);
for s = 1:size(R.sectInt,1)
    xStart = (R.sectInt(s,1) - run1IntervalUs(1)) ./ 60e6;
    xEnd = (R.sectInt(s,2) - run1IntervalUs(1)) ./ 60e6;
    line(ax, [xStart xStart], yl, 'Color',[0.1 0.1 0.1], 'LineStyle','--', 'LineWidth',0.8, 'HandleVisibility','off');
    if s == size(R.sectInt,1)
        line(ax, [xEnd xEnd], yl, 'Color',[0.1 0.1 0.1], 'LineStyle','--', 'LineWidth',0.8, 'HandleVisibility','off');
    end
end
ylim(ax, yl);
end
