function make_batch8_field_figures(F, P)
    if isempty(F), return; end
    animals = unique(string(F.animal), 'stable');
    nNovel = zeros(numel(animals),1);
    nFam = zeros(numel(animals),1);
    nNoField = zeros(numel(animals),1);
    for ai = 1:numel(animals)
        idx = string(F.animal) == animals(ai);
        nNovel(ai) = nnz(F.hasNovelField(idx));
        nFam(ai) = nnz(F.hasFamiliarField(idx));
        nNoField(ai) = nnz(F.nFields(idx) == 0);
    end

    f = figure('Color','w','Position',[100 100 950 560]);
    bar(categorical(cellstr(animals)), [nNovel nFam nNoField], 'grouped');
    ylabel('Number of units');
    title('Units with novel/familiar place-field annotations');
    legend({'Has novel field','Has familiar field','No field listed'}, 'Location','best');
    grid on;
    exportgraphics(f, fullfile(P.outDir, 'batch8_placefield_unit_counts_by_animal.png'), 'Resolution', P.saveDpi);
    close(f);
end
