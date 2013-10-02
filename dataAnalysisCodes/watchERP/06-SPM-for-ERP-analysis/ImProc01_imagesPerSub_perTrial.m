cl;

dataDir     = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP\';
[~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
resultsDir          = fullfile( resultsDir, folderName );
imResultsDir        = fullfile( resultsDir, 'images');
if ~exist( imResultsDir, 'dir' ), mkdir( imResultsDir ); end

TableName   = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\01-preprocess-plot\watchErpDataset2.xlsx';
fileList    = dataset('XLSFile', TableName);

subjects = unique( fileList.subjectTag );
conditions = unique( fileList.condition );
nSub = numel(subjects);
nCond = numel(conditions);
spm('defaults', 'eeg');

filenames = cellfun(@(x) fullfile(resultsDir, sprintf('sub%s_allConds_allTrials.mat', x)), subjects, 'UniformOutput', false);

D = cell(1, nSub);
Ss = cell(1, nSub);
Pout = cell(1, nSub);
for iS = 1:nSub
    
    fprintf('treating subject %s\n', subjects{iS});
    
    S = [];
    S.D = filenames{iS};
    S.interpolate_bad = 1;
    S.n = 32;
    
    [D{iS}, Ss{iS}, Pout{iS}] = spm_eeg_convert2images(S);
    
    sourceDir = fullfile(resultsDir, sprintf('sub%s_allConds_allTrials', subjects{iS}) );
    destDir = fullfile(imResultsDir, sprintf('sub%s_allConds_allTrials', subjects{iS}) );
    movefile(sourceDir, destDir);
    
end




