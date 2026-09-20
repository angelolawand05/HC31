function filePath = locate_first_file(rootDir, candidates)
    filePath = '';
    if ischar(candidates) || isstring(candidates)
        candidates = cellstr(candidates);
    end
    for i = 1:numel(candidates)
        cand = candidates{i};
        if isempty(cand), continue; end

        direct = fullfile(rootDir, cand);
        if exist(direct, 'file') == 2
            filePath = direct;
            return;
        end

        if exist(cand, 'file') == 2
            filePath = cand;
            return;
        end

        [~, name, ext] = fileparts(cand);
        if isempty(ext)
            pattern = cand;
        else
            pattern = [name ext];
        end
        d = dir(fullfile(rootDir, '**', pattern));
        if ~isempty(d)
            % Prefer allresults, then the shortest path.
            scores = zeros(numel(d),1);
            for k = 1:numel(d)
                fp = lower(fullfile(d(k).folder, d(k).name));
                if contains(fp, [filesep 'allresults' filesep])
                    scores(k) = scores(k) + 100;
                end
                scores(k) = scores(k) - numel(fp)/10000;
            end
            [~, idx] = max(scores);
            filePath = fullfile(d(idx).folder, d(idx).name);
            return;
        end
    end
end
