function make_ripple_qc_figures(animal, tUs, rippleFilt, envZ, speed, pos, ripples, sectInt, P)
    if isempty(tUs), return; end
    tMin = (tUs - min(tUs)) ./ 1e6 ./ 60;

    f = figure('Color','w','Position',[100 100 1200 760]);
    tiledlayout(3,1,'TileSpacing','compact','Padding','compact');

    nexttile;
    plot(tMin, pos, 'k-', 'LineWidth', 0.8);
    ylabel('Linearised position');
    title(sprintf('%s Run1 position and ripple candidates', animal), 'Interpreter','none');
    for s = 1:size(sectInt,1)
        xline((sectInt(s,1)-min(tUs))/1e6/60, '--');
    end
    grid on;

    nexttile;
    plot(tMin, speed, 'LineWidth', 0.8);
    yline(P.lowSpeedThresholdCmS, '--');
    ylabel('Speed (cm/s)');
    grid on;

    nexttile;
    plot(tMin, envZ, 'LineWidth', 0.8); hold on;
    yline(P.rippleEnvelopeLowZ, '--');
    yline(P.rippleEnvelopePeakZ, '--');
    for r = 1:numel(ripples)
        x = (ripples(r).peakUs - min(tUs))/1e6/60;
        plot(x, ripples(r).peakZ, 'ro', 'MarkerSize', 4);
    end
    xlabel('Time from Run1 start (min)');
    ylabel('Ripple envelope z');
    grid on;

    exportgraphics(f, fullfile(P.outDir, safe_filename(sprintf('batch9_%s_ripple_detection_qc.png', animal))), 'Resolution', P.saveDpi);
    close(f);
end
