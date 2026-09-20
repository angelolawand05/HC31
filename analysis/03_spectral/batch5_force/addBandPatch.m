function addBandPatch(bandHz, labelText)
    yl = ylim;
    x1 = bandHz(1); x2 = bandHz(2);
    patch([x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], [0.8 0.8 0.8], ...
        'FaceAlpha', 0.12, 'EdgeColor','none', 'HandleVisibility','off');
    text(mean(bandHz), yl(2) - 0.04*(yl(2)-yl(1)), labelText, ...
        'HorizontalAlignment','center', 'VerticalAlignment','top', 'FontSize', 8, 'HandleVisibility','off');
    uistack(findobj(gca,'Type','line'),'top');
end
