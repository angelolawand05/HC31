function plotBetaFocusedFigure(F, timeMin, zPower, zLimits, R, run1IntervalUs, betaTimes, beta2Times, betaRugY, beta2RugY, maxDots, posTimeMin, linPos, figTitle, savePath)
fig = figure('Color','w', 'Visible','off', 'Position',[100 100 1150 760]);

ax1 = subplot(2,1,1, 'Parent', fig);
hold(ax1, 'on');
plotZSpecOnAxes(ax1, F, timeMin, zPower, [10 35], zLimits);
overlaySubepochLines(ax1, R, run1IntervalUs);

betaTimesPlot = downsampleEventTimes(betaTimes, maxDots);
beta2TimesPlot = downsampleEventTimes(beta2Times, maxDots);
if ~isempty(betaTimesPlot)
    scatter(ax1, betaTimesPlot, repmat(betaRugY, size(betaTimesPlot)), 8, 'filled', ...
        'MarkerFaceColor', [0.85 0.33 0.10], ...
        'MarkerEdgeColor', [0.85 0.33 0.10], ...
        'DisplayName','beta 13-30 burst times');
end
if ~isempty(beta2TimesPlot)
    scatter(ax1, beta2TimesPlot, repmat(beta2RugY, size(beta2TimesPlot)), 8, 'filled', ...
        'DisplayName','beta2 23-30 burst times');
end
legend(ax1, 'Location','northeastoutside', 'Interpreter','none');
title(ax1, figTitle, 'Interpreter','none');
ylabel(ax1, 'frequency, Hz');
cb = colorbar(ax1);
ylabel(cb, 'power z-score within frequency');
grid(ax1, 'on');
hold(ax1, 'off');

ax2 = subplot(2,1,2, 'Parent', fig);
hold(ax2, 'on');
plot(ax2, posTimeMin, linPos, 'k-', 'LineWidth', 0.8);
overlaySubepochLines(ax2, R, run1IntervalUs);
xlabel(ax2, 'time from Run1 start, minutes');
ylabel(ax2, 'linearised position');
title(ax2, 'Run1 position trace for alignment context', 'Interpreter','none');
grid(ax2, 'on');
hold(ax2, 'off');

linkaxes([ax1 ax2], 'x');
saveFigure(fig, savePath);
end
