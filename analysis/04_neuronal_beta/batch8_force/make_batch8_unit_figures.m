function make_batch8_unit_figures(U, A, P)
    U.band = string(U.band);
    U.category = string(U.category);
    A.band = string(A.band);
    A.category = string(A.category);

    % Paired animal-level burst vs control unit firing rates.
    bandsToPlot = string(P.bandNames);
    for bi = 1:numel(bandsToPlot)
        band = bandsToPlot(bi);
        idx = A.band == band & A.category == "all";
        if nnz(idx) == 0, continue; end

        f = figure('Color','w','Position',[100 100 760 560]);
        hold on;
        x = [1 2];
        for r = find(idx)'
            y = [A.meanControlFiringRateHz(r), A.meanBurstFiringRateHz(r)];
            plot(x, y, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
        end
        xlim([0.7 2.3]);
        set(gca, 'XTick', [1 2], 'XTickLabel', {'Control windows','Burst windows'});
        ylabel('Mean unit firing rate (Hz)');
        title(sprintf('%s: unit firing during burst versus matched control windows', band), 'Interpreter','none');
        grid on;
        exportgraphics(f, fullfile(P.outDir, sprintf('batch8_%s_unit_firing_burst_vs_control.png', band)), 'Resolution', P.saveDpi);
        close(f);
    end

    % Beta2 novel/familiar participation difference.
    idx = U.band == "beta2_23_30Hz" & (U.category == "novel" | U.category == "familiar");
    if nnz(idx) > 0
        f = figure('Color','w','Position',[100 100 900 560]);
        hold on;
        cats = ["familiar", "novel"];
        for ci = 1:numel(cats)
            idc = idx & U.category == cats(ci);
            y = U.burstMinusControlParticipationFraction(idc);
            x = ci + (rand(sum(idc),1)-0.5)*0.20;
            scatter(x, y, 22, 'filled', 'MarkerFaceAlpha', 0.45);
            plot([ci-0.20 ci+0.20], [median(y,'omitnan') median(y,'omitnan')], 'k-', 'LineWidth', 2);
        end
        yline(0, '--');
        set(gca, 'XTick', 1:2, 'XTickLabel', cellstr(cats));
        ylabel('Burst minus control participation fraction');
        title('Beta2 unit participation: familiar versus novel burst windows');
        grid on;
        exportgraphics(f, fullfile(P.outDir, 'batch8_beta2_unit_participation_novel_vs_familiar.png'), 'Resolution', P.saveDpi);
        close(f);
    end

    % Beta2 novel-burst firing enrichment by novel place-field status.
    idx = U.band == "beta2_23_30Hz" & U.category == "novel";
    if nnz(idx) > 0 && any(U.hasNovelField(idx))
        f = figure('Color','w','Position',[100 100 860 560]);
        hold on;
        groups = [0 1];
        labels = {'No novel field','Has novel field'};
        for gi = 1:numel(groups)
            idg = idx & logical(U.hasNovelField) == logical(groups(gi));
            y = U.burstMinusControlFiringRateHz(idg);
            x = gi + (rand(sum(idg),1)-0.5)*0.20;
            scatter(x, y, 22, 'filled', 'MarkerFaceAlpha', 0.45);
            plot([gi-0.20 gi+0.20], [median(y,'omitnan') median(y,'omitnan')], 'k-', 'LineWidth', 2);
        end
        yline(0, '--');
        set(gca, 'XTick', 1:2, 'XTickLabel', labels);
        ylabel('Novel beta2 burst minus control firing rate (Hz)');
        title('Novel beta2 burst involvement by novel place-field status');
        grid on;
        exportgraphics(f, fullfile(P.outDir, 'batch8_beta2_novel_burst_diff_by_novel_field_status.png'), 'Resolution', P.saveDpi);
        close(f);
    end
end
