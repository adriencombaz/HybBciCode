cl;

dataDir     = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP\';
[~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
resultsDir          = fullfile( resultsDir, folderName );
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

TableName   = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\01-preprocess-plot\watchErpDataset2.xlsx';
fileList    = dataset('XLSFile', TableName);
fileList(ismember(fileList.subjectTag, 'S08'), :) = [];
% fileList.subject(ismember(fileList.subject, 'S09'), :) = {'S08'};
% fileList.subject(ismember(fileList.subject, 'S10'), :) = {'S09'};

subjects = unique( fileList.subjectTag );
conditions = unique( fileList.condition );
nSub = numel(subjects);
nCond = numel(conditions);
spm('defaults', 'eeg');

filesToMerge = cellfun(@(x) fullfile(resultsDir, sprintf('sub%s_allConds_meanTrials.mat', x)), subjects, 'UniformOutput', false);

S = [];
S.D = char(filesToMerge);
for iS = 1:nSub
    S.recode(iS).file     = filesToMerge{iS};
    S.recode(iS).labelorg = '.*';
    S.recode(iS).labelnew = sprintf('#labelorg#-%s', subjects{iS});
end
% S.recode(1).file     = cellfun(@(x) sprintf('sub%s', x), subjects, 'UniformOutput', false);
% S.recode(1).labelorg = '.*';
% S.recode(1).labelnew = '#labelorg# #file#';
D = spm_eeg_merge(S);
close(gcf);
