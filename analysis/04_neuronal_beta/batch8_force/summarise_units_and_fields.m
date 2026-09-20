function unitInfo = summarise_units_and_fields(R, nUnits, runEpoch, sectInt)
    unitInfo = repmat(struct('spikeTimesUs', [], 'run1SpikeCount', 0, 'run1RateHz', NaN, ...
        'nFields', 0, 'nNovelFields', 0, 'nFamiliarFields', 0, ...
        'hasNovelField', false, 'hasFamiliarField', false), nUnits, 1);

    runStart = min(sectInt(:));
    runEnd = max(sectInt(:));
    runDurS = (runEnd - runStart) / 1e6;

    for u = 1:nUnits
        st = [];
        try
            st = double(R.spEpochSep(u, runEpoch).timeStamps(:));
        catch
        end
        if isempty(st) && size(R.spEpochSep,2) >= 1
            try
                st = double(R.spEpochSep(u, 1).timeStamps(:));
            catch
            end
        end
        st = st(isfinite(st));
        if ~isempty(st) && median(abs(st), 'omitnan') < 1e6
            st = st .* 1e6;
        end
        unitInfo(u).spikeTimesUs = sort(st(:));
        unitInfo(u).run1SpikeCount = numel(st);
        unitInfo(u).run1RateHz = numel(st) / max(runDurS, eps);

        if isfield(R, 'fieldInfoC') && ~isempty(R.fieldInfoC) && size(R.fieldInfoC,1) >= u
            nSe = min(4, size(R.fieldInfoC,2));
            for se = 1:nSe
                try
                    fieldsTemp = R.fieldInfoC{u,se};
                catch
                    fieldsTemp = [];
                end
                if isempty(fieldsTemp), continue; end

                for j = 1:numel(fieldsTemp)
                    unitInfo(u).nFields = unitInfo(u).nFields + 1;

                    isnov = false;
                    if isstruct(fieldsTemp) && isfield(fieldsTemp, 'isnov')
                        try
                            isnov = logical(fieldsTemp(j).isnov);
                        catch
                            isnov = false;
                        end
                    end

                    if isnov
                        unitInfo(u).nNovelFields = unitInfo(u).nNovelFields + 1;
                        unitInfo(u).hasNovelField = true;
                    else
                        unitInfo(u).nFamiliarFields = unitInfo(u).nFamiliarFields + 1;
                        unitInfo(u).hasFamiliarField = true;
                    end
                end
            end
        end
    end
end
