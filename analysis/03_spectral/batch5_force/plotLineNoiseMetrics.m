function plotLineNoiseMetrics(M, figDir)
    if isempty(M); return; end
    fig = figure('Color','w', 'Name', 'Line-noise excess', 'Position', [100 100 900 550]);
    x = 1:height(M);
    bar(x, [M.line50ExcessDb, M.line60ExcessDb]);
    set(gca, 'XTick', x, 'XTickLabel', M.animal, 'XTickLabelRotation', 35);
    ylabel('line-noise excess over neighbours, dB');
    title('50/60 Hz line-noise excess by animal');
    legend({'50 Hz excess','60 Hz excess'}, 'Location','best'); grid on;
    saveas(fig, fullfile(figDir, 'batch5_line_noise_excess_by_animal.png'));
end
