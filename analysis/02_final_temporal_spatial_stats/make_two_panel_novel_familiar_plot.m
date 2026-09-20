function make_two_panel_novel_familiar_plot(NF, bandsWanted, outBase)
    fig = figure('Color','w', 'Position',[100 100 1100 520]);
    tiledlayout(1, numel(bandsWanted), 'TileSpacing','compact', 'Padding','compact');

    for b = 1:numel(bandsWanted)
        band = bandsWanted(b);
        nexttile;
        [animals, fam, nov] = paired_values_novel_familiar(NF, band, ...
            'familiarBurstRatePerMinute', 'novelBurstRatePerMinute');
        ok = isfinite(fam) & isfinite(nov);
        animals = animals(ok);
        fam = fam(ok);
        nov = nov(ok);
        p = exact_signflip_p(nov - fam);

        hold on;
        for i = 1:numel(fam)
            plot([1 2], [fam(i) nov(i)], '-o', 'LineWidth', 1.4, 'MarkerSize', 5);
            text(2.05, nov(i), char(animals(i)), 'Interpreter','none', 'FontSize', 7);
        end
        plot([1 2], [mean(fam,'omitnan') mean(nov,'omitnan')], 'k-o', 'LineWidth', 3, 'MarkerFaceColor','k');
        errorbar([1 2], [mean(fam,'omitnan') mean(nov,'omitnan')], [sem_omitnan(fam) sem_omitnan(nov)], ...
            'k', 'LineStyle','none', 'LineWidth', 1.4);
        xlim([0.75 2.45]);
        set(gca,'XTick',[1 2],'XTickLabel',{'Familiar','Novel'});
        ylabel('Burst frequency (bursts/min)');
        title(sprintf('%s novel vs familiar', band), 'Interpreter','none');
        grid on;

        yMax = max([fam; nov], [], 'omitnan');
        yMin = min([fam; nov], [], 'omitnan');
        yr = max(yMax-yMin, max(abs(yMax),1)*0.1);
        add_sig_bar(gca, 1, 2, yMax+0.12*yr, 0.04*yr, p_to_label(p));
    end

    save_figure(fig, outBase);
    close(fig);
end
