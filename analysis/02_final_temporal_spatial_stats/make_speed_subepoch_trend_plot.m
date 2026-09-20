function make_speed_subepoch_trend_plot(SPS, outBase)
    SPS.animal = string(SPS.animal);
    subepochs = unique(SPS.subepoch);
    subepochs = subepochs(isfinite(subepochs));

    means = nan(size(subepochs));
    sems = nan(size(subepochs));
    pVals = nan(size(subepochs));

    for si = 1:numel(subepochs)
        se = subepochs(si);
        X = SPS(SPS.subepoch == se, :);
        d = X.novelMinusFamiliarMovingSpeedCmS;
        d = d(isfinite(d));
        means(si) = mean(d, 'omitnan');
        sems(si) = sem_omitnan(d);
        pVals(si) = exact_signflip_p(d);
    end

    fig = figure('Color','w', 'Position',[100 100 850 560]);
    errorbar(subepochs, means, sems, '-o', 'LineWidth', 1.8, 'MarkerSize', 6);
    hold on;
    yline(0, 'k--');
    for si = 1:numel(subepochs)
        if isfinite(means(si))
            text(subepochs(si), means(si) + sems(si) + 0.1, p_to_label(pVals(si)), ...
                'HorizontalAlignment','center', 'FontSize', 8);
        end
    end
    xlabel('Run1 subepoch');
    ylabel('Novel minus familiar moving speed (cm/s)');
    title('Movement-speed control by subepoch');
    grid on;
    save_figure(fig, outBase);
    close(fig);
end
