function [cscPath, info] = choose_csc_for_interval(cscFiles, animal, startUs, endUs)
    cscPath = '';
    info = struct('startUs',NaN,'endUs',NaN,'overlapS',0);

    animal = string(animal);
    paths = strings(numel(cscFiles), 1);
    for i = 1:numel(cscFiles)
        paths(i) = string(fullfile(cscFiles(i).folder, cscFiles(i).name));
    end

    % Same validated animal-to-CSC mapping used in the working Batches 6-9.
    expectedBase = "";
    switch char(animal)
        case 'ANM00190422'
            expectedBase = "CSC33.ncs";
        case 'ANM204878'
            expectedBase = "CSC33.ncs";
        case 'ANM212379'
            expectedBase = "CSC53.ncs";
        case 'ANM228899'
            expectedBase = "CSC45.ncs";
        case 'ANM228900'
            expectedBase = "CSC45.ncs";
    end

    cand = find(contains(lower(paths), lower(animal)));
    if isempty(cand)
        cand = 1:numel(cscFiles);
    end

    % Put mapped CSC files first when available, but still score by interval overlap.
    if strlength(expectedBase) > 0
        exact = find(contains(lower(paths), lower(animal)) & endsWith(lower(paths), lower(expectedBase)));
        cand = unique([exact(:); cand(:)], 'stable');
    end

    bestScore = -Inf;
    bestIdx = NaN;
    bestInfo = info;

    for ci = cand(:)'
        fpath = char(paths(ci));
        testInfo = try_get_csc_bounds(fpath, info, startUs, endUs);

        score = testInfo.overlapS;
        if contains(lower(string(fpath)), lower(animal))
            score = score + 1000;
        end
        if strlength(expectedBase) > 0 && endsWith(lower(string(fpath)), lower(expectedBase))
            score = score + 50;
        end
        if ~isfinite(score)
            score = 0;
        end

        if score > bestScore
            bestScore = score;
            bestIdx = ci;
            bestInfo = testInfo;
        end
    end

    if ~isnan(bestIdx)
        cscPath = char(paths(bestIdx));
        info = bestInfo;
    end
end
