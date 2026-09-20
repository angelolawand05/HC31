function Stats = make_batch10_stats_summary(Summary)
    if isempty(Summary), Stats = table(); return; end

    Summary.animal = string(Summary.animal);
    Summary.epochName = string(Summary.epochName);
    epochs = unique(Summary.epochName, 'stable');

    rows = {};
    for ei = 1:numel(epochs)
        ep = epochs(ei);
        idx = Summary.epochName == ep;

        vals = Summary.beta2TaggedMinusUntaggedParticipation(idx);
        rows(end+1,:) = {char(ep), 'beta2_tagged_minus_untagged_ripple_participation', ...
            nnz(isfinite(vals)), mean(vals,'omitnan'), median(vals,'omitnan'), ...
            nnz(vals > 0), nnz(vals < 0), exact_sign_flip_p(vals)}; %#ok<AGROW>

        vals2 = Summary.novelBeta2TaggedMinusNonNovelParticipation(idx);
        rows(end+1,:) = {char(ep), 'novel_beta2_tagged_minus_non_novel_tagged_ripple_participation', ...
            nnz(isfinite(vals2)), mean(vals2,'omitnan'), median(vals2,'omitnan'), ...
            nnz(vals2 > 0), nnz(vals2 < 0), exact_sign_flip_p(vals2)}; %#ok<AGROW>
    end

    % POST minus PRE within beta2-tagged units.
    animals = unique(Summary.animal, 'stable');
    postMinusPre = [];
    novelPostMinusPre = [];
    for ai = 1:numel(animals)
        pre = Summary(Summary.animal == animals(ai) & Summary.epochName == "PRE", :);
        post = Summary(Summary.animal == animals(ai) & Summary.epochName == "POST", :);
        if height(pre) == 1 && height(post) == 1
            postMinusPre(end+1,1) = post.meanRippleParticipationBeta2Tagged - pre.meanRippleParticipationBeta2Tagged; %#ok<AGROW>
            novelPostMinusPre(end+1,1) = post.meanRippleParticipationNovelBeta2Tagged - pre.meanRippleParticipationNovelBeta2Tagged; %#ok<AGROW>
        end
    end

    if ~isempty(postMinusPre)
        vals = postMinusPre;
        rows(end+1,:) = {'POST_minus_PRE', 'beta2_tagged_ripple_participation_change', ...
            nnz(isfinite(vals)), mean(vals,'omitnan'), median(vals,'omitnan'), ...
            nnz(vals > 0), nnz(vals < 0), exact_sign_flip_p(vals)}; %#ok<AGROW>
    end
    if ~isempty(novelPostMinusPre)
        vals = novelPostMinusPre;
        rows(end+1,:) = {'POST_minus_PRE', 'novel_beta2_tagged_ripple_participation_change', ...
            nnz(isfinite(vals)), mean(vals,'omitnan'), median(vals,'omitnan'), ...
            nnz(vals > 0), nnz(vals < 0), exact_sign_flip_p(vals)}; %#ok<AGROW>
    end

    Stats = cell2table(rows, 'VariableNames', { ...
        'epochOrComparison','metric','nAnimals','meanValue','medianValue', ...
        'nPositive','nNegative','twoSidedExactSignFlipP'});
end
