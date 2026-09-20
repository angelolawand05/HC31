function plotThetaBeta2PeakSummary(M, figDir)
    if isempty(M); return; end
    fig = figure('Color','w', 'Name', 'Theta and beta2 peaks', 'Position', [100 100 900 550]);
    x = 1:height(M);
    plot(x, M.thetaPeakHz, 'o-', 'LineWidth', 1.5, 'MarkerSize', 7, 'DisplayName','theta peak Hz');
    hold on;
    plot(x, M.beta2PeakHz, 's-', 'LineWidth', 1.5, 'MarkerSize', 7, 'DisplayName','beta2 peak Hz');
    hold off;
    set(gca, 'XTick', x, 'XTickLabel', M.animal, 'XTickLabelRotation', 35);
    ylabel('peak frequency, Hz');
    title('Theta and beta2 peak frequencies by animal');
    legend('Location','best'); grid on;
    saveas(fig, fullfile(figDir, 'batch5_theta_beta2_peak_summary.png'));
end
