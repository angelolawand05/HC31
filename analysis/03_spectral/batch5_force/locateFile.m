function p = locateFile(rootDir, fileNames)
    p = '';
    if ischar(fileNames)
        fileNames = {fileNames};
    end
    for k = 1:numel(fileNames)
        direct = fullfile(rootDir, fileNames{k});
        if exist(direct, 'file') == 2
            p = direct;
            return;
        end
        d = dir(fullfile(rootDir, '**', fileNames{k}));
        if ~isempty(d)
            % Prefer files inside known spectra/output folders if possible.
            scores = zeros(numel(d),1);
            for i = 1:numel(d)
                fp = fullfile(d(i).folder, d(i).name);
                if contains(lower(fp), 'power_spectra_spectrogram_outputs')
                    scores(i) = scores(i) + 10;
                end
                if contains(lower(fp), 'beta_burst_over_time_outputs_beta13_30')
                    scores(i) = scores(i) + 10;
                end
            end
            [~, idx] = max(scores);
            p = fullfile(d(idx).folder, d(idx).name);
            return;
        end
    end
end
