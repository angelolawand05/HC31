function plotHighFrequencyMetrics(M, figDir)
    if isempty(M); return; end
    fig = figure('Color','w', 'Name', 'High-frequency noise metrics', 'Position', [100 100 900 550]);
    x = 1:height(M);
    yyaxis left;
    bar(x, M.highFreqExcessDb);
    ylabel('high-frequency excess, dB');
    yyaxis right;
    plot(x, M.spectralRoughnessMadDb, 'ko-', 'LineWidth', 1.5, 'MarkerFaceColor','k');
    ylabel('spectral roughness, median abs diff');
    set(gca, 'XTick', x, 'XTickLabel', M.animal, 'XTickLabelRotation', 35);
    title('High-frequency excess and spectral roughness');
    grid on;
    saveas(fig, fullfile(figDir, 'batch5_high_frequency_noise_metrics.png'));
end
