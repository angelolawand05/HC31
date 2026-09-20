function make_sleep_ripple_qc_plot(animal, epochName, tUs, envZ, ripples, P)
    if isempty(tUs), return; end
    tMin = (tUs - min(tUs)) ./ 1e6 ./ 60;

    f = figure('Color','w','Position',[100 100 1100 520]);
    plot(tMin, envZ, 'k-', 'LineWidth', 0.8); hold on;
    yline(P.rippleEnvelopeLowZ, '--', 'low z');
    yline(P.rippleEnvelopePeakZ, '--', 'peak z');
    for r = 1:numel(ripples)
        x = (ripples(r).peakUs - min(tUs)) ./ 1e6 ./ 60;
        plot(x, ripples(r).peakZ, 'ro', 'MarkerSize', 4);
    end
    xlabel(sprintf('Time from %s epoch start (min)', char(epochName)));
    ylabel('Ripple envelope z');
    title(sprintf('%s %s candidate sleep/rest ripples', animal, char(epochName)), 'Interpreter','none');
    grid on;

    exportgraphics(f, fullfile(P.outDir, safe_filename(sprintf('batch10_%s_%s_sleep_ripple_qc.png', animal, char(epochName)))), 'Resolution', P.saveDpi);
    close(f);
end
