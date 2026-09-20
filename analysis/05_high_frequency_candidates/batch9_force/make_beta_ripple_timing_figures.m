function make_beta_ripple_timing_figures(T, C, P)
    if isempty(T), return; end

    bands = unique(string(T.betaBand), 'stable');
    for bi = 1:numel(bands)
        band = bands(bi);
        idx = string(T.betaBand) == band;
        f = figure('Color','w','Position',[100 100 760 560]);
        hold on;
        x = [1 2];
        for r = find(idx)'
            plot(x, [T.meanBetaBurstsPreRipple(r), T.meanBetaBurstsPostRipple(r)], '-o', 'LineWidth', 1.5);
        end
        set(gca,'XTick',[1 2],'XTickLabel',{'Pre-ripple','Post-ripple'});
        ylabel(sprintf('%s bursts per ripple', band), 'Interpreter','none');
        title(sprintf('%s bursts before versus after candidate awake ripples', band), 'Interpreter','none');
        grid on;
        exportgraphics(f, fullfile(P.outDir, safe_filename(sprintf('batch9_%s_pre_vs_post_ripple.png', band))), 'Resolution', P.saveDpi);
        close(f);
    end

    if ~isempty(C)
        bands = unique(string(C.betaBand), 'stable');
        for bi = 1:numel(bands)
            band = bands(bi);
            idx = string(C.betaBand) == band;
            if ~any(idx), continue; end
            G = groupsummary(C(idx,:), 'lagCenterS', 'mean', 'eventsPerRipple');
            f = figure('Color','w','Position',[100 100 850 560]);
            bar(G.lagCenterS, G.mean_eventsPerRipple, 1.0);
            xline(0, '--', 'Ripple peak');
            xlabel('Beta/beta2 lag from ripple peak (s)');
            ylabel('Events per ripple');
            title(sprintf('%s event timing around candidate awake ripples', band), 'Interpreter','none');
            grid on;
            exportgraphics(f, fullfile(P.outDir, safe_filename(sprintf('batch9_%s_crosscorr_around_ripples.png', band))), 'Resolution', P.saveDpi);
            close(f);
        end
    end
end
