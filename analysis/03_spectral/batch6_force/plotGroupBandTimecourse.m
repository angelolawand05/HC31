function plotGroupBandTimecourse(G, savePath)
fig = figure('Color','w', 'Visible','off', 'Position',[100 100 1100 650]);
ax = axes(fig);
hold(ax, 'on');
bands = unique(G.band, 'stable');
for b = 1:numel(bands)
    rows = strcmp(G.band, bands{b}) & G.nAnimals > 0;
    errorbar(ax, G.timeBinMidMin(rows), G.meanZPower(rows), G.semZPower(rows), '-o', ...
        'LineWidth', 1.2, 'MarkerSize', 3, 'DisplayName', bands{b});
end
xlabel(ax, 'time from Run1 start, minutes');
ylabel(ax, 'mean z-scored power');
title(ax, 'Group mean band z-power time courses from z-scored spectrograms', 'Interpreter','none');
legend(ax, 'Location','best', 'Interpreter','none');
grid(ax, 'on');
hold(ax, 'off');
saveFigure(fig, savePath);
end
