function make_subepoch_grid_plot(NFS, bandsWanted, outBase)
    NFS.animal = string(NFS.animal);
    NFS.band = normalise_band_labels(string(NFS.band));

    subepochs = unique(NFS.subepoch);
    subepochs = subepochs(isfinite(subepochs));
    % Subepoch 1 usually has no familiar comparison; keep 2-4 if available.
    subepochs = subepochs(subepochs >= 2);

    if isempty(subepochs)
        return;
    end

    fig = figure('Color','w', 'Position',[100 100 1350 760]);
    tiledlayout(numel(bandsWanted), numel(subepochs), 'TileSpacing','compact', 'Padding','compact');

    for b = 1:numel(bandsWanted)
        band = bandsWanted(b);
        for si = 1:numel(subepochs)
            se = subepochs(si);
            nexttile;
            X = NFS(NFS.band == band & NFS.subepoch == se, :);
            [animals, fam, nov] = paired_values_novel_familiar(X, band, ...
                'familiarBurstRatePerMinute', 'novelBurstRatePerMinute');
            ok = isfinite(fam) & isfinite(nov);
            animals = animals(ok);
            fam = fam(ok);
            nov = nov(ok);
            p = exact_signflip_p(nov - fam);

            hold on;
            if isempty(fam)
                title(sprintf('%s subepoch %d: no paired data', band, se), 'Interpreter','none');
                axis off;
                continue;
            end
            for i = 1:numel(fam)
                plot([1 2], [fam(i) nov(i)], '-o', 'LineWidth', 1.2, 'MarkerSize', 5);
            end
            plot([1 2], [mean(fam,'omitnan') mean(nov,'omitnan')], 'k-o', 'LineWidth', 2.5, 'MarkerFaceColor','k');
            errorbar([1 2], [mean(fam,'omitnan') mean(nov,'omitnan')], [sem_omitnan(fam) sem_omitnan(nov)], ...
                'k', 'LineStyle','none', 'LineWidth', 1.2);
            xlim([0.75 2.35]);
            set(gca, 'XTick', [1 2], 'XTickLabel', {'Fam','Nov'});
            ylabel('Bursts/min');
            title(sprintf('%s | subepoch %d', band, se), 'Interpreter','none');
            grid on;

            yMax = max([fam; nov], [], 'omitnan');
            yMin = min([fam; nov], [], 'omitnan');
            yr = max(yMax-yMin, max(abs(yMax),1)*0.1);
            add_sig_bar(gca, 1, 2, yMax+0.12*yr, 0.04*yr, p_to_label(p));
        end
    end

    save_figure(fig, outBase);
    close(fig);
end
