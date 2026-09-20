%% HC-31 Batch 11K: unblind completed manual ripple reviews
%
% Plain script version. No local functions.
%
% Run this only after the blinded review CSV has been completed.
%
% Recommended MATLAB workaround:
%
%   clear; clc; close all; rehash;
%   [scriptFile, scriptFolder] = uigetfile('*.m', ...
%       'Select hc31_batch11K_unblind_reviews_PLAIN_SCRIPT.m');
%   cd(scriptFolder);
%   txt = fileread(fullfile(scriptFolder, scriptFile));
%   eval(txt);

clear; clc; close all; rehash;

fprintf('\nHC-31 Batch 11K: unblind completed manual reviews\n');
fprintf('--------------------------------------------------\n');

[reviewFile,reviewFolder] = uigetfile('*.csv','Select the COMPLETED Batch 11K manual review CSV');
if isequal(reviewFile,0)
    error('No completed review CSV selected.');
end
reviewPath = fullfile(reviewFolder,reviewFile);

[keyFile,keyFolder] = uigetfile('*.csv','Select hc31_batch11K_BLINDING_KEY_DO_NOT_OPEN_DURING_REVIEW.csv');
if isequal(keyFile,0)
    error('No blinding-key CSV selected.');
end
keyPath = fullfile(keyFolder,keyFile);

Review = readtable(reviewPath);
Key = readtable(keyPath);

if ~any(strcmpi(Review.Properties.VariableNames,'blindID'))
    error('The completed review table does not contain blindID.');
end
if ~any(strcmpi(Key.Properties.VariableNames,'blindID'))
    error('The key table does not contain blindID.');
end

% Standardise exact variable-name case for join.
reviewBlindIdx = find(strcmpi(Review.Properties.VariableNames,'blindID'),1);
keyBlindIdx = find(strcmpi(Key.Properties.VariableNames,'blindID'),1);
reviewBlindCol = Review.Properties.VariableNames{reviewBlindIdx};
keyBlindCol = Key.Properties.VariableNames{keyBlindIdx};
if ~strcmp(reviewBlindCol,'blindID'); Review.Properties.VariableNames{reviewBlindIdx} = 'blindID'; end
if ~strcmp(keyBlindCol,'blindID'); Key.Properties.VariableNames{keyBlindIdx} = 'blindID'; end

Review.blindID = string(Review.blindID);
Key.blindID = string(Key.blindID);

Merged = join(Review,Key,'Keys','blindID');

outDir = keyFolder;
outFile = fullfile(outDir,'hc31_batch11K_UNBLINDED_MANUAL_REVIEWS.csv');
writetable(Merged,outFile);

% Classification summary.
if any(strcmpi(Merged.Properties.VariableNames,'primaryClassification'))
    classCol = Merged.Properties.VariableNames{find(strcmpi(Merged.Properties.VariableNames,'primaryClassification'),1)};
    classes = string(Merged.(classCol));
    classes(strlength(strtrim(classes))==0) = "Unclassified";
    uniqueClasses = unique(classes,'stable');
    summaryRows = {};
    for cc = 1:numel(uniqueClasses)
        mask = classes == uniqueClasses(cc);
        summaryRows(end+1,:) = {char(uniqueClasses(cc)),sum(mask),mean(mask)}; %#ok<SAGROW>
    end
    ClassificationSummary = cell2table(summaryRows,'VariableNames', ...
        {'primaryClassification','nEvents','fractionOfReviewedTable'});
    writetable(ClassificationSummary,fullfile(outDir,'hc31_batch11K_classification_summary.csv'));
end

% Animal/epoch likely-ripple proportions.
likelyCol = '';
for c = {'isLikelyPhysiologicalRipple','likelyPhysiologicalRipple','isLikelyRipple'}
    hit = find(strcmpi(Merged.Properties.VariableNames,c{1}),1);
    if ~isempty(hit); likelyCol = Merged.Properties.VariableNames{hit}; break; end
end

if ~isempty(likelyCol) && any(strcmpi(Merged.Properties.VariableNames,'animal')) && ...
        any(strcmpi(Merged.Properties.VariableNames,'epoch'))
    animalCol = Merged.Properties.VariableNames{find(strcmpi(Merged.Properties.VariableNames,'animal'),1)};
    epochCol = Merged.Properties.VariableNames{find(strcmpi(Merged.Properties.VariableNames,'epoch'),1)};
    animals = unique(string(Merged.(animalCol)),'stable');
    epochs = unique(string(Merged.(epochCol)),'stable');
    rows = {};
    for aa = 1:numel(animals)
        for ee = 1:numel(epochs)
            mask = string(Merged.(animalCol))==animals(aa) & string(Merged.(epochCol))==epochs(ee);
            if ~any(mask); continue; end
            vals = Merged.(likelyCol)(mask);
            if islogical(vals)
                vals = double(vals);
            elseif isnumeric(vals)
                vals = double(vals~=0);
            else
                vals = double(lower(string(vals))=="true" | string(vals)=="1" | lower(string(vals))=="yes");
            end
            rows(end+1,:) = {char(animals(aa)),char(epochs(ee)),sum(mask),sum(vals),mean(vals)}; %#ok<SAGROW>
        end
    end
    AnimalEpochSummary = cell2table(rows,'VariableNames', ...
        {'animal','epoch','nReviewed','nLikelyPhysiologicalRipple','likelyRippleFraction'});
    writetable(AnimalEpochSummary,fullfile(outDir,'hc31_batch11K_animal_epoch_manual_QC_summary.csv'));
end

% Review-completion check.
if any(strcmpi(Review.Properties.VariableNames,'reviewComplete'))
    completeCol = Review.Properties.VariableNames{find(strcmpi(Review.Properties.VariableNames,'reviewComplete'),1)};
    vals = Review.(completeCol);
    if islogical(vals)
        nComplete = sum(vals);
    elseif isnumeric(vals)
        nComplete = sum(vals~=0);
    else
        nComplete = sum(lower(string(vals))=="true" | string(vals)=="1" | lower(string(vals))=="yes");
    end
    fprintf('Completed rows: %d / %d\n',nComplete,height(Review));
    if nComplete < height(Review)
        warning('%d review rows are not marked complete.',height(Review)-nComplete);
    end
end

fprintf('\nSaved unblinded review table:\n  %s\n',outFile);
fprintf('Batch 11K unblinding complete.\n');
