cl;

dataDir     = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP\';
[~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
resultsDir          = fullfile( resultsDir, folderName );
imResultsDir        = fullfile( resultsDir, 'images');
smImResultsDir      = fullfile( resultsDir, 'imagesSmoothed');
if ~exist( smImResultsDir, 'dir' ), mkdir( smImResultsDir ); end

TableName   = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\01-preprocess-plot\watchErpDataset2.xlsx';
fileList    = dataset('XLSFile', TableName);

subjects = unique( fileList.subjectTag );
conditions = unique( fileList.condition );
nSub = numel(subjects);
nCond = numel(conditions);
spm('defaults', 'eeg');

foldername = cellfun(@(x) fullfile(imResultsDir, sprintf('sub%s_allConds_allTrials', x)), subjects, 'UniformOutput', false);
sFoldername = cellfun(@(x) fullfile(smImResultsDir, sprintf('sub%s_allConds_allTrials', x)), subjects, 'UniformOutput', false);

for iS = 9:nSub
    for iC = 1:nCond
        
        imDir    = fullfile(foldername{iS}, ['type_' subjects{iS} '-' conditions{iC}]);
        imList   = ls([imDir filesep '*.img']);
        
        fprintf('treating subject %s (%d out of %d), condition %s (%d out of %d), %d images\n', subjects{iS}, iS, nSub, conditions{iC}, iC, nCond, size(imList, 1));

        sImDir   = fullfile(sFoldername{iS}, ['type_' subjects{iS} '-' conditions{iC}]);
        if ~exist( sImDir, 'dir' ), mkdir( sImDir ); end
        
        for iIm = 1:size(imList, 1)
            
            imfile = fullfile(imDir, strtrim(imList(iIm,:)));
            smImfile = fullfile(sImDir, strtrim(imList(iIm,:)));
            s = [8 8 8];
            spm_smooth(imfile,smImfile,s);
            
        end
        
        
        
    end
end
