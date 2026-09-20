function add_sig_bar(ax, x1, x2, y, h, labelText)
    axes(ax); %#ok<LAXES>
    plot([x1 x1 x2 x2], [y y+h y+h y], 'k', 'LineWidth', 1.5);
    text(mean([x1 x2]), y+h, labelText, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontWeight','bold');

    yl = ylim;
    if y + 2*h > yl(2)
        ylim([yl(1), y + 4*h]);
    end
end
