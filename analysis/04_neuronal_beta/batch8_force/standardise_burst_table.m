function B = standardise_burst_table(T)
    B = table();

    B.animal = string(get_col(T, {'animal','Animal','animal_id','AnimalID','rat','subject'}));
    idxCol = find_var(T, {'resSaveIndex','res_save_index','index','resIndex'});
    if isempty(idxCol)
        B.resSaveIndex = nan(height(T), 1);
    else
        B.resSaveIndex = double(T.(idxCol));
    end

    B.band = string(get_col(T, {'band','Band','frequency_band','freq_band'}));

    peakCol = find_var(T, {'burstPeakUs','peakUs','peak_time_us','burst_peak_us','peak_timestamp_us','peak_time','peak_time_s'});
    if isempty(peakCol)
        error('Could not find burst peak time column in burst table.');
    end
    B.peakUs = double(T.(peakCol));
    if median(abs(B.peakUs), 'omitnan') < 1e6
        % Likely seconds; leave conversion to per-animal code only if needed.
        % Most HC-31 outputs use microseconds.
        warning('Burst peak time values look smaller than expected for microseconds. Check time units.');
    end

    startCol = find_var(T, {'burstStartUs','startUs','burst_start_us','start_time_us','burstStart','start_time'});
    endCol   = find_var(T, {'burstEndUs','endUs','burst_end_us','end_time_us','burstEnd','end_time'});
    durCol   = find_var(T, {'burstDurationS','durationS','duration_s','burst_duration_s','duration'});

    if isempty(startCol)
        B.startUs = nan(height(T), 1);
    else
        B.startUs = double(T.(startCol));
    end
    if isempty(endCol)
        B.endUs = nan(height(T), 1);
    else
        B.endUs = double(T.(endCol));
    end
    if isempty(durCol)
        B.durationS = nan(height(T), 1);
    else
        B.durationS = double(T.(durCol));
    end

    subCol = find_var(T, {'subepoch','subEpoch','subep','sub_epoch'});
    if isempty(subCol)
        B.subepoch = nan(height(T), 1);
    else
        B.subepoch = double(T.(subCol));
    end

    catCol = find_var(T, {'category','novelFamiliar','novel_familiar','condition','label'});
    if isempty(catCol)
        B.category = repmat("all", height(T), 1);
    else
        B.category = lower(string(T.(catCol)));
    end

    spdCol = find_var(T, {'peakSpeedCmS','peak_speed_cm_s','speedCmS','peakSpeed','speed'});
    if isempty(spdCol)
        B.peakSpeedCmS = nan(height(T), 1);
    else
        B.peakSpeedCmS = double(T.(spdCol));
    end

    incCol = find_var(T, {'includedInNovelFamiliarAnalysis','included','isIncluded'});
    if isempty(incCol)
        B.included = ones(height(T), 1);
    else
        B.included = double(T.(incCol));
    end

    artCol = find_var(T, {'excludedAsArtifact','excludedAsArtefact','artifact','artefact','isArtifact','isArtefact'});
    if isempty(artCol)
        B.isArtifact = zeros(height(T), 1);
    else
        v = T.(artCol);
        if islogical(v)
            B.isArtifact = double(v);
        elseif isnumeric(v)
            B.isArtifact = double(v ~= 0);
        else
            s = lower(string(v));
            B.isArtifact = double(s == "true" | s == "1" | s == "yes");
        end
    end
end
