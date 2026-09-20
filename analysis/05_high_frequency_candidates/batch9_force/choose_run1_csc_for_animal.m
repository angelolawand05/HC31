function [cscPath, info] = choose_run1_csc_for_animal(cscFiles, animal, runStartUs, runEndUs)
    cscPath = '';
    info = struct('startUs',NaN,'endUs',NaN,'overlapS',0);

    animal = string(animal);
    paths = strings(numel(cscFiles), 1);
    for i = 1:numel(cscFiles)
        paths(i) = string(fullfile(cscFiles(i).folder, cscFiles(i).name));
    end

    % Same validated animal-to-CSC mapping used in the working Batch 6/7 runners.
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

    if strlength(expectedBase) > 0
        exact = find(contains(lower(paths), lower(animal)) & endsWith(lower(paths), lower(expectedBase)), 1);
        if ~isempty(exact)
            cscPath = char(paths(exact));
            info = try_get_csc_bounds(cscPath, info, runStartUs, runEndUs);
            return;
        end
    end

    cand = find(contains(lower(paths), lower(animal)));
    if isempty(cand)
        cand = 1:numel(cscFiles);
    end

    bestScore = -Inf;
    bestIdx = NaN;
    bestInfo = info;

    for ci = cand(:)'
        fpath = char(paths(ci));
        testInfo = try_get_csc_bounds(fpath, info, runStartUs, runEndUs);

        score = testInfo.overlapS;
        if contains(lower(string(fpath)), lower(animal))
            score = score + 1000;
        end
        if strlength(expectedBase) > 0 && endsWith(lower(string(fpath)), lower(expectedBase))
            score = score + 50;
        end

        % Even if timestamp probing fails, keep the expected animal file as candidate.
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
