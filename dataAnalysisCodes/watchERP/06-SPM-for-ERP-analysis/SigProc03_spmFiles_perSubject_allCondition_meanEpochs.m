cl;

dataDir     = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP\';
[~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
resultsDir          = fullfile( resultsDir, folderName );
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

TableName   = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\01-preprocess-plot\watchErpDataset2.xlsx';
fileList    = dataset('XLSFile', TableName);

subjects = unique( fileList.subjectTag );
conditions = unique( fileList.condition );
% conditionValues = 1000*(1:numel(conditions));
nSub = numel(subjects);
nCond = numel(conditions);
spm('defaults', 'eeg');

for iS = 7%1:nSub


    %--------------------------------------------------------------------------------------------------------------------------------
    % average epochs
    %--------------------------------------------------------------------------------------------------------------------------------
    fprintf('\naverage epochs\n');
    S = [];
    S.D = fullfile(resultsDir, sprintf('sub%s_allConds_allTrials.mat', subjects{iS}));
    S.robust = false;
    D = spm_eeg_average(S);

    %--------------------------------------------------------------------------------------------------------------------------------
    % rename and move the .mat and .dat spm file
    %--------------------------------------------------------------------------------------------------------------------------------
    tempFilename = D.fname;
  
    [~, oldFileName, ~] = fileparts( tempFilename );
    newFileName = sprintf('sub%s_allConds_meanTrials', subjects{iS});
    spm_changepath( fullfile(resultsDir, tempFilename), oldFileName, newFileName );
    movefile( ...
        fullfile( resultsDir, tempFilename ) ...
        , fullfile( resultsDir, sprintf('%s.mat', newFileName) )...
        );
    movefile( ...
        fullfile( resultsDir, [tempFilename(1:end-4) '.dat'] ) ...
        , fullfile( resultsDir, sprintf('%s.dat', newFileName) ) ...
        );
    delete( fullfile( resultsDir, [tempFilename '.old'] ) );
    
end