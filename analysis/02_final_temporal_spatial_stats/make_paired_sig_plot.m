function make_paired_sig_plot(valsA, valsB, labels, xLabels, yLabel, titleText, outBase, p)
    valsA = valsA(:);
    valsB = valsB(:);
    labels = string(labels(:));
    ok = isfinite(valsA) & isfinite(valsB);
    valsA = valsA(ok);
    valsB = valsB(ok);
    labels = labels(ok);

    fig = figure('Color','w', 'Position',[100 100 780 560]);
    hold on;

    if isempty(valsA)
        title([titleText ' (no paired data)'], 'Interpreter','none');
        save_figure(fig, outBase);
        close(fig);
        return;
    end

    for i = 1:numel(valsA)
        plot([1 2], [valsA(i) valsB(i)], '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
        text(2.05, valsB(i), char(labels(i)), 'Interpreter','none', 'FontSize', 8);
    end

    mA = mean(valsA, 'omitnan');
    mB = mean(valsB, 'omitnan');
    sA = sem_omitnan(valsA);
    sB = sem_omitnan(valsB);

    plot([1 2], [mA mB], 'k-o', 'LineWidth', 3, 'MarkerSize', 8, 'MarkerFaceColor','k');
    errorbar([1 2], [mA mB], [sA sB], 'k', 'LineStyle','none', 'LineWidth', 1.5);

    xlim([0.75 2.45]);
    set(gca, 'XTick', [1 2], 'XTickLabel', xLabels);
    ylabel(yLabel);
    title(titleText, 'Interpreter','none');
    grid on;

    yMax = max([valsA; valsB], [], 'omitnan');
    yMin = min([valsA; valsB], [], 'omitnan');
    yr = yMax - yMin;
    if ~isfinite(yr) || yr <= 0
        yr = max(abs(yMax), 1);
    end
    y = yMax + 0.12*yr;
    h = 0.04*yr;
    add_sig_bar(gca, 1, 2, y, h, p_to_label(p));

    save_figure(fig, outBase);
    close(fig);
end
