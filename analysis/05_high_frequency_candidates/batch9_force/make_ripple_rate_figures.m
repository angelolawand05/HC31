function make_ripple_rate_figures(RT, AS, P)
    if isempty(AS), return; end
    f = figure('Color','w','Position',[100 100 820 560]);
    bar(categorical(AS.animal), AS.rippleRatePerMinute);
    ylabel('Candidate awake ripple rate/min during low-speed periods');
    title('Candidate awake ripple rate by animal');
    grid on;
    exportgraphics(f, fullfile(P.outDir, 'batch9_candidate_awake_ripple_rate_by_animal.png'), 'Resolution', P.saveDpi);
    close(f);

    if ~isempty(RT)
        f = figure('Color','w','Position',[100 100 850 560]);
        rows = string(RT.category) == "all";
        scatter(RT.subepoch(rows), RT.rippleRatePerMinute(rows), 55, 'filled'); hold on;
        xlabel('Run1 subepoch');
        ylabel('Ripple rate/min during low-speed periods');
        title('Candidate awake ripple rate by subepoch');
        xlim([0.5 4.5]);
        grid on;
        exportgraphics(f, fullfile(P.outDir, 'batch9_ripple_rate_by_subepoch.png'), 'Resolution', P.saveDpi);
        close(f);
    end
end
