function make_first_second_panel_plot(S, bandsWanted, outBase)
    fig = figure('Color','w', 'Position',[100 100 1100 520]);
    tiledlayout(1, numel(bandsWanted), 'TileSpacing','compact', 'Padding','compact');

    for b = 1:numel(bandsWanted)
        band = bandsWanted(b);
        X = S(S.band == band, :);
        firstVals = X.firstHalfRatePerMinute;
        secondVals = X.secondHalfRatePerMinute;
        animals = X.animal;
        ok = isfinite(firstVals) & isfinite(secondVals);
        firstVals = firstVals(ok);
        secondVals = secondVals(ok);
        animals = animals(ok);
        p = exact_signflip_p(secondVals - firstVals);

        nexttile;
        hold on;
        for i = 1:numel(firstVals)
            plot([1 2], [firstVals(i) secondVals(i)], '-o', 'LineWidth', 1.4, 'MarkerSize', 5);
            text(2.05, secondVals(i), char(animals(i)), 'Interpreter','none', 'FontSize', 7);
        end
        plot([1 2], [mean(firstVals,'omitnan') mean(secondVals,'omitnan')], 'k-o', 'LineWidth', 3, 'MarkerFaceColor','k');
        errorbar([1 2], [mean(firstVals,'omitnan') mean(secondVals,'omitnan')], ...
            [sem_omitnan(firstVals) sem_omitnan(secondVals)], 'k', 'LineStyle','none', 'LineWidth', 1.4);
        xlim([0.75 2.45]);
        set(gca,'XTick',[1 2],'XTickLabel',{'First half','Second half'});
        ylabel('Burst frequency (bursts/min)');
        title(sprintf('%s first vs second half', band), 'Interpreter','none');
        grid on;

        yMax = max([firstVals; secondVals], [], 'omitnan');
        yMin = min([firstVals; secondVals], [], 'omitnan');
        yr = max(yMax-yMin, max(abs(yMax),1)*0.1);
        add_sig_bar(gca, 1, 2, yMax+0.12*yr, 0.04*yr, p_to_label(p));
    end

    save_figure(fig, outBase);
    close(fig);
end
