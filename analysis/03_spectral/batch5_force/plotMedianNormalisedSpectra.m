function plotMedianNormalisedSpectra(T, condName, plotHz, figDir)
    animals = unique(T.animal(T.condition == string(condName)), 'stable');
    fig = figure('Color','w', 'Name', 'Median-normalised spectra', 'Position', [100 100 1000 650]);
    hold on;
    for a = 1:numel(animals)
        rows = T.animal == animals(a) & T.condition == string(condName) & T.frequencyHz >= plotHz(1) & T.frequencyHz <= plotHz(2);
        if any(rows)
            f = T.frequencyHz(rows); y = T.powerDb(rows);
            [f, order] = sort(f); y = y(order);
            yNorm = y - median(y, 'omitnan');
            plot(f, yNorm, 'LineWidth', 1.3, 'DisplayName', char(animals(a)));
        end
    end
    hold off;
    xlabel('frequency, Hz'); ylabel('power relative to animal median, dB');
    title(sprintf('Median-normalised spectra (%s)', condName), 'Interpreter','none');
    legend('Location','best'); grid on; xlim(plotHz);
    saveas(fig, fullfile(figDir, 'batch5_all_moving_spectra_median_normalised.png'));
end
