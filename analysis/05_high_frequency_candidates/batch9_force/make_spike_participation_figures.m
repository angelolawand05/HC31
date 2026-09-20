function make_spike_participation_figures(SP, P)
    if isempty(SP), return; end
    f = figure('Color','w','Position',[100 100 850 560]);
    scatter(SP.beta2ParticipationFraction, SP.rippleParticipationFraction, 30, 'filled', 'MarkerFaceAlpha', 0.55);
    xlabel('Beta2 burst participation fraction');
    ylabel('Ripple participation fraction');
    title('Unit participation in beta2 bursts versus candidate awake ripples');
    grid on;
    exportgraphics(f, fullfile(P.outDir, 'batch9_unit_beta2_vs_ripple_participation_scatter.png'), 'Resolution', P.saveDpi);
    close(f);
end
