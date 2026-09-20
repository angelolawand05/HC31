function plotAllMovingSpectraOverlay(T, condName, plotHz, thetaBandHz, betaBandHz, beta2BandHz, gammaBandHz, figDir)
    animals = unique(T.animal(T.condition == string(condName)), 'stable');
    fig = figure('Color','w', 'Name', 'All-moving spectra overlay', 'Position', [100 100 1000 650]);
    hold on;
    for a = 1:numel(animals)
        rows = T.animal == animals(a) & T.condition == string(condName) & T.frequencyHz >= plotHz(1) & T.frequencyHz <= plotHz(2);
        if any(rows)
            f = T.frequencyHz(rows); y = T.powerDb(rows);
            [f, order] = sort(f); y = y(order);
            plot(f, y, 'LineWidth', 1.3, 'DisplayName', char(animals(a)));
        end
    end
    addBandPatch(thetaBandHz, 'theta');
    addBandPatch(betaBandHz, 'beta');
    addBandPatch(beta2BandHz, 'beta2');
    xline(gammaBandHz(1), ':', 'gamma start', 'LabelVerticalAlignment','bottom');
    hold off;
    xlabel('frequency, Hz'); ylabel('power, dB');
    title(sprintf('Per-animal spectra overlay (%s)', condName), 'Interpreter','none');
    legend('Location','best'); grid on; xlim(plotHz);
    saveas(fig, fullfile(figDir, 'batch5_all_moving_spectra_overlay_1_120Hz.png'));
end
