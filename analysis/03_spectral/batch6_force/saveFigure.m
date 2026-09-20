function saveFigure(fig, savePath)
[saveDir,~,~] = fileparts(savePath);
if exist(saveDir, 'dir') ~= 7; mkdir(saveDir); end
try
    exportgraphics(fig, savePath, 'Resolution', 200);
catch
    saveas(fig, savePath);
end
close(fig);
end
