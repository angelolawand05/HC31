function save_figure(fig, outBase)
    pngPath = [char(outBase) '.png'];
    figPath = [char(outBase) '.fig'];
    try
        exportgraphics(fig, pngPath, 'Resolution', 220);
    catch
        saveas(fig, pngPath);
    end
    try
        savefig(fig, figPath);
    catch
    end
end
