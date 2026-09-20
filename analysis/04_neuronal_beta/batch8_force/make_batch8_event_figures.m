function make_batch8_event_figures(AE, P)
    if isempty(AE), return; end
    AE.band = string(AE.band);
    AE.category = string(AE.category);

    idx = AE.band == "beta2_23_30Hz" & AE.category == "all";
    if nnz(idx) > 0
        f = figure('Color','w','Position',[100 100 760 560]);
        hold on;
        x = [1 2];
        for r = find(idx)'
            y = [AE.meanActiveUnitsControl(r), AE.meanActiveUnitsBurst(r)];
            plot(x, y, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
        end
        set(gca, 'XTick', [1 2], 'XTickLabel', {'Control windows','Beta2 burst windows'});
        xlim([0.7 2.3]);
        ylabel('Mean active units per event');
        title('Beta2 ensemble activity: burst versus matched control windows');
        grid on;
        exportgraphics(f, fullfile(P.outDir, 'batch8_beta2_event_ensemble_active_units_burst_vs_control.png'), 'Resolution', P.saveDpi);
        close(f);
    end
end
