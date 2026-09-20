function UnitSpikes = get_unit_spikes_for_epoch(R, epochCol)
    sp = R.spEpochSep;
    nUnits = size(sp, 1);
    UnitSpikes = cell(nUnits, 1);

    for u = 1:nUnits
        try
            st = double(sp(u, epochCol).timeStamps(:));
        catch
            st = [];
        end
        st = st(isfinite(st));
        if ~isempty(st) && median(abs(st), 'omitnan') < 1e6
            st = st .* 1e6;
        end
        UnitSpikes{u} = sort(st(:));
    end
end
