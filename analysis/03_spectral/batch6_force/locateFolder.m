function folderPath = locateFolder(rootDir, folderName)
folderPath = '';
parts = strsplit(genpath(rootDir), pathsep);
for p = 1:numel(parts)
    if isempty(parts{p}); continue; end
    [~, nm] = fileparts(parts{p});
    if strcmpi(nm, folderName)
        folderPath = parts{p};
        return;
    end
end
end
