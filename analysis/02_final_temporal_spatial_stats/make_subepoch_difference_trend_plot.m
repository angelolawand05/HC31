function make_subepoch_difference_trend_plot(NFS, bandsWanted, outBase)
    NFS.animal = string(NFS.animal);
    NFS.band = normalise_band_labels(string(NFS.band));

    subepochs = unique(NFS.subepoch);
    subepochs = subepochs(isfinite(subepochs));

    fig = figure('Color','w', 'Position',[100 100 900 580]);
    hold on;

    for b = 1:numel(bandsWanted)
        band = bandsWanted(b);
        means = nan(size(subepochs));
        sems = nan(size(subepochs));
        pVals = nan(size(subepochs));

        for si = 1:numel(subepochs)
            se = subepochs(si);
            X = NFS(NFS.band == band & NFS.subepoch == se, :);
            d = X.novelMinusFamiliarRate;
            d = d(isfinite(d));
            means(si) = mean(d, 'omitnan');
            sems(si) = sem_omitnan(d);
            pVals(si) = exact_signflip_p(d);
        end

        errorbar(subepochs, means, sems, '-o', 'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', char(band));

        for si = 1:numel(subepochs)
            if isfinite(means(si))
                text(subepochs(si), means(si) + sems(si) + 0.05*max(abs(means(isfinite(means)))+1), ...
                    p_to_label(pVals(si)), 'HorizontalAlignment','center', 'FontSize', 8);
            end
        end
    end

    yline(0, 'k--');
    xlabel('Run1 subepoch');
    ylabel('Novel minus familiar burst frequency (bursts/min)');
    title('Novel-familiar burst-rate difference by subepoch');
    legend('Location','best', 'Interpreter','none');
    grid on;

    save_figure(fig, outBase);
    close(fig);
end
