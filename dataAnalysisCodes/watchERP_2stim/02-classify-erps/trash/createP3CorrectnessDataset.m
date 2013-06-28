function createP3CorrectnessDataset

% init host name
%--------------------------------------------------------------------------
if isunix,
    envVarName = 'HOSTNAME';
else
    envVarName = 'COMPUTERNAME';
end
hostName = lower( strtok( getenv( envVarName ), '.') );

switch hostName,
    case 'kuleuven-24b13c',
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP_2stim\';
        codeDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP_2stim\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resDir  = 'd:\Adrien\Work\Hybrid-BCI\HybBciProcessedData\watchERP_2stim\';
        codeDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP_2stim\';
    case {'sunny', 'solaris', ''}
        addpath( genpath( '~/PhD/hybridBCI-stuffs/deps/' ) );
        rmpath( genpath('~/PhD/hybridBCI-stuffs/deps/eeglab10_0_1_0b/external/SIFT_01_alpha') );
        dataDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/data/';
        resDir  = '~/PhD/hybridBCI-stuffs/watchERP_2stim/results/';
        codeDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/code/';
    otherwise,
        error('host not recognized');
end

if isunix,
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset.csv');
    fileList    = dataset('File', TableName, 'Delimiter', ',');
else
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset.xlsx');
    fileList    = dataset('XLSFile', TableName);
end

run = unique( fileList.run );
if ~isequal(run(:), (1:max(run))'), error('wrong run numbering'); end
listRunsForTrain = {1 2 3, [1 2], [2 3], [3 4]};
listTestRun      = cellfun(@(x) run( run > max(x) ), listRunsForTrain, 'UniformOutput', false );

%% ========================================================================================================

%--------------------------------------------------------------------------
sub                 = unique( fileList.subjectTag );
nSub                = numel(sub);
[~, folderName, ~]  = fileparts( fileparts( mfilename('fullpath') ) );
resDirOut           = fullfile( resDir, folderName );
if ~exist( resDirOut, 'dir' ), mkdir( resDirOut ); end


for ii = 1:numel( listRunsForTrain )
    
    %---------------------------------------------------------------------------------------------------------------
    fprintf('Treating case %d out of %d (train on runs %d', ii, numel( listRunsForTrain ), listRunsForTrain{ii}(1));
    for iRunTrain = 2:numel(listRunsForTrain{ii}), fprintf(', %d', listRunsForTrain{ii}(iRunTrain)); end
    fprintf(') test on runs %d', listTestRun{ii}(1) );
    for iRunTest = 2:numel(listTestRun{ii}), fprintf(', %d', listTestRun{ii}(iRunTest)); end
    fprintf('\n');
    
    %---------------------------------------------------------------------------------------------------------------
    filename = 'train';
    for iTr = 1:numel(listRunsForTrain{ii}), filename = sprintf('%s%d', filename, listRunsForTrain{ii}(iTr)); end
    filename = sprintf('%s_test', filename);
    for iTest = 1:numel(listTestRun{ii}), filename = sprintf('%s%d', filename, listTestRun{ii}(iTest)); end
    filename = sprintf('%s.txt', filename);
    fid = fopen( fullfile( resDirOut, filename ),'wt' );
    fprintf(fid, 'subject, run, roundNb, nRep, targetFrequency, correctness\n');

    
    %---------------------------------------------------------------------------------------------------------------
    for iS = 1:nSub
        
        fprintf('\ttreating subject %s (%d out of %d)\n', sub{iS}, iS, nSub);
        
        %% LOAD P3 DATASET
        p3File = fullfile( resDir, '02-classify-erps' ...
            , sprintf('linSvm_%dRunsForTrain', numel( listRunsForTrain{ii} )) ...
            , sprintf('subject_%s', sub{iS}) ...
            , 'Results_forLogisiticRegression.txt' ...
            );
        
        p3Dataset = dataset('File', p3File, 'Delimiter', ',');
        
        temp = p3Dataset;
        for iRunTrain = 1:numel(listRunsForTrain{ii})
            fieldName = sprintf('trainingRun_%d', iRunTrain);
            temp = temp( ismember(temp.(fieldName), listRunsForTrain{ii}(iRunTrain)), : );
        end
        
        subP3Dataset = [];
        for iRunTest = 1:numel(listTestRun{ii})
            subP3Dataset = [subP3Dataset ; temp( ismember(temp.testingRun, listTestRun{ii}(iRunTest)), : )];
        end
        
    runs = unique(subP3Dataset.testingRun);
    nRuns = numel( runs );
    rounds = unique(subP3Dataset.roundNb);
    nRounds = numel( rounds );
    reps = unique(subP3Dataset.nAverages);
    nReps = numel( reps );
        for iRun = 1:nRuns
            for iRound = 1:nRounds
                for iRep = 1:nReps
                    
                    dataP3 = subP3Dataset( ...
                        ismember(subP3Dataset.testingRun, runs(iRun)) ...
                        & ismember(subP3Dataset.roundNb, rounds(iRound)) ...
                        & ismember(subP3Dataset.nAverages, reps(iRep)) ...
                        , : );
                    if size(dataP3, 1) ~= 1, error('too many observations!'); end

                    fprintf(fid, '%s, %d, %d, %d, %.2g, %d\n' ...
                        , sub{iS} ...
                        , runs(iRun) ...
                        , rounds(iRound) ...
                        , reps(iRep) ...
                        , dataP3.targetFrequency ...
                        , dataP3.correctness ...
                        );
                    
                end % OF iRep LOOP
            end % OF iRound LOOP
        end % OF iRun LOOP                
    end % OF iSub LOOP
end


end