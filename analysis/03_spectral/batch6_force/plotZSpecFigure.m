function plotZSpecFigure(F, timeMin, zPower, plotRangeHz, zLimits, R, run1IntervalUs, betaTimes, beta2Times, rugYVals, figTitle, savePath)
fig = figure('Color','w', 'Visible','off', 'Position',[100 100 1100 650]);
ax = axes(fig);
hold(ax, 'on');
plotZSpecOnAxes(ax, F, timeMin, zPower, plotRangeHz, zLimits);
overlaySubepochLines(ax, R, run1IntervalUs);
if ~isempty(betaTimes)
    scatter(ax, betaTimes, repmat(rugYVals(1), size(betaTimes)), 8, 'filled', 'DisplayName','beta burst times');
end
if ~isempty(beta2Times)
    scatter(ax, beta2Times, repmat(rugYVals(2), size(beta2Times)), 8, 'filled', 'DisplayName','beta2 burst times');
end
title(ax, figTitle, 'Interpreter','none');
xlabel(ax, 'time from Run1 start, minutes');
ylabel(ax, 'frequency, Hz');
cb = colorbar(ax);
ylabel(cb, 'power z-score within frequency');
grid(ax, 'on');
hold(ax, 'off');
saveFigure(fig, savePath);
end
