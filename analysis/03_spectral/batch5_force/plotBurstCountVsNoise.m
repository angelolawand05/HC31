function plotBurstCountVsNoise(C, figDir)
    if isempty(C); return; end
    fig = figure('Color','w', 'Name', 'Beta2 burst count vs noise score', 'Position', [100 100 800 600]);
    scatter(C.combinedNoiseScore, C.beta2ValidBurstCount, 80, 'filled');
    hold on;
    for i = 1:height(C)
        text(C.combinedNoiseScore(i), C.beta2ValidBurstCount(i), ['  ' C.animal{i}], 'FontSize', 8);
    end
    if height(C) >= 3 && numel(unique(C.combinedNoiseScore)) >= 2
        coeff = polyfit(C.combinedNoiseScore, C.beta2ValidBurstCount, 1);
        xx = linspace(min(C.combinedNoiseScore), max(C.combinedNoiseScore), 50);
        yy = polyval(coeff, xx);
        plot(xx, yy, 'k--', 'LineWidth', 1.3);
    end
    hold off;
    xlabel('combined spectral noise score');
    ylabel('valid beta2 burst count');
    title('Beta2 burst count versus spectral noise score');
    grid on;
    saveas(fig, fullfile(figDir, 'batch5_beta2_burst_count_vs_noise_score.png'));
end
