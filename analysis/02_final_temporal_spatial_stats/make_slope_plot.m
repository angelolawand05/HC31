function make_slope_plot(S, bandsWanted, outBase)
    fig = figure('Color','w', 'Position',[100 100 850 560]);
    hold on;
    xPos = 1:numel(bandsWanted);

    allY = [];
    for b = 1:numel(bandsWanted)
        band = bandsWanted(b);
        X = S(S.band == band, :);
        slopes = X.slopeBurstRatePerMinutePerMinute;
        slopes = slopes(isfinite(slopes));
        allY = [allY; slopes(:)]; %#ok<AGROW>

        x = xPos(b) * ones(size(slopes));
        plot(x, slopes, 'o', 'MarkerSize', 7, 'LineWidth', 1.2);
        m = mean(slopes, 'omitnan');
        se = sem_omitnan(slopes);
        errorbar(xPos(b), m, se, 'k', 'LineWidth', 2);
        p = exact_signflip_p(slopes);
        text(xPos(b), m + se + 0.05*max(abs(slopes)+1), p_to_label(p), ...
            'HorizontalAlignment','center', 'FontWeight','bold');
    end

    yline(0, 'k--');
    xlim([0.5 numel(bandsWanted)+0.5]);
    set(gca, 'XTick', xPos, 'XTickLabel', cellstr(bandsWanted));
    ylabel('Slope (bursts/min per minute)');
    title('Animal-level burst-rate slope over Run1');
    grid on;

    save_figure(fig, outBase);
    close(fig);
end
