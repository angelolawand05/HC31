function B = standardise_burst_table(T)
    B = table();
    B.animal = string(get_col(T, {'animal','Animal','animal_id','AnimalID','rat','subject'}));
    idxCol = find_var(T, {'resSaveIndex','res_save_index','index','resIndex'});
    if isempty(idxCol), B.resSaveIndex = nan(height(T),1); else, B.resSaveIndex = double(T.(idxCol)); end
    B.band = string(get_col(T, {'band','Band','frequency_band','freq_band'}));

    peakCol = find_var(T, {'burstPeakUs','peakUs','peak_time_us','burst_peak_us','peak_timestamp_us','peak_time','peak_time_s'});
    if isempty(peakCol), error('Could not find burst peak time column.'); end
    B.peakUs = double(T.(peakCol));
    if median(abs(B.peakUs), 'omitnan') < 1e6
        B.peakUs = B.peakUs .* 1e6; % likely seconds
    end

    incCol = find_var(T, {'includedInNovelFamiliarAnalysis','included','isIncluded'});
    if isempty(incCol), B.included = ones(height(T),1); else, B.included = double(T.(incCol)); end

    artCol = find_var(T, {'excludedAsArtifact','excludedAsArtefact','artifact','artefact','isArtifact','isArtefact'});
    if isempty(artCol)
        B.isArtifact = zeros(height(T),1);
    else
        v = T.(artCol);
        if islogical(v), B.isArtifact = double(v);
        elseif isnumeric(v), B.isArtifact = double(v ~= 0);
        else
            s = lower(string(v));
            B.isArtifact = double(s == "true" | s == "1" | s == "yes");
        end
    end
end
