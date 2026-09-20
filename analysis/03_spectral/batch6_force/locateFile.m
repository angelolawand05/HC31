function filePath = locateFile(rootDir, candidateNames)
filePath = '';
if ischar(candidateNames)
    candidateNames = {candidateNames};
end
for c = 1:numel(candidateNames)
    name = candidateNames{c};
    direct = fullfile(rootDir, name);
    if exist(direct, 'file') == 2
        filePath = direct;
        return;
    end
    parts = strsplit(genpath(rootDir), pathsep);
    for p = 1:numel(parts)
        if isempty(parts{p}); continue; end
        candidate = fullfile(parts{p}, name);
        if exist(candidate, 'file') == 2
            filePath = candidate;
            return;
        end
    end
end
end
