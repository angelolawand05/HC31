function filePath = find_first_file(rootDir, fileName)
    d = dir(fullfile(rootDir, '**', fileName));
    if isempty(d)
        filePath = '';
    else
        filePath = fullfile(d(1).folder, d(1).name);
    end
end
