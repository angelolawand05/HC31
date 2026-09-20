function make_batch10_figures(Beta2Tags, RippleRates, RP, Summary, P)
    if ~isempty(Beta2Tags)
        % Count beta2 tagged units by animal.
        animals = unique(string(Beta2Tags.animal), 'stable');
        nTagged = zeros(numel(animals),1);
        nNovelTagged = zeros(numel(animals),1);
        nTotal = zeros(numel(animals),1);
        for ai = 1:numel(animals)
            idx = string(Beta2Tags.animal) == animals(ai);
            nTotal(ai) = nnz(idx);
            nTagged(ai) = nnz(logical(Beta2Tags.isBeta2Tagged(idx)));
            nNovelTagged(ai) = nnz(logical(Beta2Tags.isNovelBeta2Tagged(idx)));
        end

        f = figure('Color','w','Position',[100 100 900 540]);
        bar(categorical(cellstr(animals)), [nTagged nNovelTagged nTotal]);
        ylabel('Number of units');
        title('Run1 beta2-tagged units by animal');
        legend({'Any beta2-tagged','Novel beta2-tagged','Total units'}, 'Location','best');
        grid on;
        exportgraphics(f, fullfile(P.outDir, 'batch10_beta2_tagged_unit_counts_by_animal.png'), 'Resolution', P.saveDpi);
        close(f);
    end

    if ~isempty(RippleRates)
        RippleRates.animal = string(RippleRates.animal);
        RippleRates.epochName = string(RippleRates.epochName);

        f = figure('Color','w','Position',[100 100 880 560]);
        hold on;
        epochOrder = ["PRE","REST","POST"];
        for a = unique(RippleRates.animal, 'stable')'
            y = nan(1,numel(epochOrder));
            for e = 1:numel(epochOrder)
                idx = RippleRates.animal == a & RippleRates.epochName == epochOrder(e);
                if any(idx)
                    y(e) = RippleRates.validRippleRatePerMinute(find(idx,1));
                end
            end
            plot(1:numel(epochOrder), y, '-o', 'LineWidth', 1.5);
        end
        set(gca, 'XTick', 1:numel(epochOrder), 'XTickLabel', cellstr(epochOrder));
        ylabel('Candidate ripple rate/min');
        title('Candidate sleep/rest ripple rate across epochs');
        grid on;
        exportgraphics(f, fullfile(P.outDir, 'batch10_candidate_sleep_ripple_rate_pre_rest_post.png'), 'Resolution', P.saveDpi);
        close(f);
    end

    if ~isempty(Summary)
        Summary.animal = string(Summary.animal);
        Summary.epochName = string(Summary.epochName);

        % POST tagged vs untagged.
        idx = Summary.epochName == "POST";
        if any(idx)
            f = figure('Color','w','Position',[100 100 760 560]);
            hold on;
            x = [1 2];
            for r = find(idx)'
                y = [Summary.meanRippleParticipationUntagged(r), Summary.meanRippleParticipationBeta2Tagged(r)];
                plot(x, y, '-o', 'LineWidth', 1.5);
            end
            set(gca, 'XTick', [1 2], 'XTickLabel', {'Untagged units','Run1 beta2-tagged units'});
            ylabel('POST ripple participation fraction');
            title('POST candidate ripple participation by Run1 beta2 tag');
            grid on;
            exportgraphics(f, fullfile(P.outDir, 'batch10_post_ripple_participation_beta2_tagged_vs_untagged.png'), 'Resolution', P.saveDpi);
            close(f);
        end

        % PRE vs POST for beta2-tagged.
        animals = unique(Summary.animal, 'stable');
        f = figure('Color','w','Position',[100 100 760 560]);
        hold on;
        madeAny = false;
        for a = animals'
            pre = Summary(Summary.animal == a & Summary.epochName == "PRE", :);
            post = Summary(Summary.animal == a & Summary.epochName == "POST", :);
            if height(pre)==1 && height(post)==1
                plot([1 2], [pre.meanRippleParticipationBeta2Tagged, post.meanRippleParticipationBeta2Tagged], '-o', 'LineWidth', 1.5);
                madeAny = true;
            end
        end
        if madeAny
            set(gca, 'XTick', [1 2], 'XTickLabel', {'PRE','POST'});
            ylabel('Ripple participation fraction in beta2-tagged units');
            title('Beta2-tagged unit participation in candidate ripples: PRE versus POST');
            grid on;
            exportgraphics(f, fullfile(P.outDir, 'batch10_beta2_tagged_pre_vs_post_ripple_participation.png'), 'Resolution', P.saveDpi);
        end
        close(f);

        % Novel beta2 tagged vs non-novel in POST.
        idx = Summary.epochName == "POST";
        if any(idx)
            f = figure('Color','w','Position',[100 100 760 560]);
            hold on;
            for r = find(idx)'
                y = [Summary.meanRippleParticipationNonNovelBeta2Tagged(r), Summary.meanRippleParticipationNovelBeta2Tagged(r)];
                plot([1 2], y, '-o', 'LineWidth', 1.5);
            end
            set(gca, 'XTick', [1 2], 'XTickLabel', {'Not novel-beta2 tagged','Novel-beta2 tagged'});
            ylabel('POST ripple participation fraction');
            title('POST candidate ripple participation by novel beta2 tag');
            grid on;
            exportgraphics(f, fullfile(P.outDir, 'batch10_post_ripple_participation_novel_beta2_tagged.png'), 'Resolution', P.saveDpi);
            close(f);
        end
    end
end
