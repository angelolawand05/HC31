function plotZSpecOnAxes(ax, F, timeMin, zPower, plotRangeHz, zLimits)
rows = F >= plotRangeHz(1) & F <= plotRangeHz(2);
imagesc(ax, timeMin, F(rows), zPower(rows,:));
set(ax, 'YDir','normal');
ylim(ax, plotRangeHz);
if ~isempty(zLimits) && numel(zLimits) == 2
    caxis(ax, zLimits);
end
try
    colormap(ax, 'parula');
catch
    colormap(ax, jet);
end
end
