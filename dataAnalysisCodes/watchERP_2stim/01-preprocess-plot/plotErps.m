clear;clc

%% ========================================================================================================
% =========================================================================================================

% init host name
%--------------------------------------------------------------------------
if isunix,
    envVarName = 'HOSTNAME';
else
    envVarName = 'COMPUTERNAME';
end
hostName = lower( strtok( getenv( envVarName ), '.') );

% init paths
%--------------------------------------------------------------------------
switch hostName,
    case 'kuleuven-24b13c',
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir     = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP_2stim\01-preprocess-plot\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir     = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resultsDir  = 'd:\Adrien\Work\Hybrid-BCI\HybBciResults\watchERP_2stim\01-preprocess-plot\';
    otherwise,
        error('host not recognized');
end

% ========================================================================================================
% ========================================================================================================

TableName   = 'watchErpDataset.xlsx';
fileList    = dataset('XLSFile', TableName);

[~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
resultsDir          = fullfile( resultsDir, folderName );
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end


sub         = unique( fileList.subjectTag );
nFreqs      = 2;
nErpType    = 2; % target and non-target ERPs
nRunMax     = 10;
nData       = nSubjects*nFreqs*nErpType*nRunMax;

subject     = cell( nData, 1 );
frequency   = zeros( nData, 1 );
type        = cell( nData, 1 );
run         = zeros( nData, 1 );
meanERP     = cell( nData, 1 );
fs          = zeros( nData, 1 );
nEpochs     = zeros( nData, 1 );
chanList    = cell( nData, 1 );
tBeforeOnset    = 0.2; % lower time range in secs
tAfterOnset     = 0.8; % upper time range in secs

iData = 1;
for iS = 1:nSubjects,
    
    subset = fileList( ismember( fileList.subjectTag, sub{iS} ), : );
    
    for iR = 1:size(subset, 1),
        
        fprintf('\nsubject %s (%d out of %d), run %d out of %d\n', ...
            sub{iS}, iS, nSubjects, iR, size(subset, 1) );
        
        %--------------------------------------------------------------------------
        sessionDir  = fullfile(dataDir, subset.sessionDirectory{iR});
        filename    = ls(fullfile(sessionDir, [subset.fileName{iR} '*.bdf']));
        paramFile   = ls(fullfile(sessionDir, [subset.fileName{iR} '*.mat']));
        pars        = load( fullfile(sessionDir,paramFile), 'nCuesToShow', 'nRepetitions', 'lookHereStateSeq', 'realP3StateSeqOnsets' );

        %--------------------------------------------------------------------------
        erpData     = eegDataset( sessionDir, filename );
        erpData.tBeforeOnset = tBeforeOnset;
        erpData.tAfterOnset = tAfterOnset;
        
        %--------------------------------------------------------------------------
        if iR == 1
            samplingRate    = erpData.fs;
            channels        = erpData.chanList( erpData.eegChanInd );
            eventLabels     = erpData.eventLabel;
            if numel( eventLabels ) ~= nErpType, error('was expecting %d event types (target/non-target)', nErpType); end
            
        else
            if erpData.fs ~= samplingRate
                error('runs were not recorded with the same sampling rate!!');
            end
            if ~isequal( channels, erpData.chanList( erpData.eegChanInd ))
                error('runs have different channels');
            end
            if ~isequal(eventLabels, erpData.eventLabel)
                error('runs have different event labels');
            end
            
        end
        
        %--------------------------------------------------------------------------
        erpData.butterFilter(1, 30, 3);
        erpData.markEpochsForRejection('minMax', 'proportion', .15);
        %             erpData.markEpochsForRejection('minMax', 'threshold', 60);

%         if iR == 1
%             [sumCut nCuts] = erpData.getSumCut();
%             
%         else
%             [sumCutTemp nCutsTemp] = erpData.getSumCut();
%             for i = 1:numel(eventLabels)
%                 sumCut{i}   = sumCut{i} + sumCutTemp{i};
%                 nCuts{i}    = nCuts{i} + nCutsTemp{i};
%             end
%             
%         end
        
        
        [sumCut nCuts] = erpData.getSumCut();
        
        %--------------------------------------------------------------------------------------------
        meanERP{iData}      = sumCut{1}(:, erpData.eegChanInd ) / nCuts{1};
        meanERP{iData+1}    = sumCut{2}(:, erpData.eegChanInd ) / nCuts{2};
        nEpochs(iData)      = nCuts{1};
        nEpochs(iData+1)    = nCuts{2};
        fs(iData)           = samplingRate;
        fs(iData+1)         = samplingRate;
        chanList{iData}     = channels;
        chanList{iData+1}   = channels;
        subject{iData}      = sub{iS};
        subject{iData+1}    = sub{iS};
        frequency{iData}    = cond{iC};
        frequency{iData+1}  = cond{iC};
        type{iData}         = eventLabels{1};
        type{iData+1}       = eventLabels{2};
        
        iData = iData+2;
        
    end
    
    
end