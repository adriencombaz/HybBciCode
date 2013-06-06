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
        resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP_2stim\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir     = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resultsDir  = 'd:\Adrien\Work\Hybrid-BCI\HybBciResults\watchERP_2stim\';
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
nSubjects   = numel(sub);
nFreqs      = 2; % left and rigth square
nErpType    = 2; % target and non-target ERPs
nRunMax     = max( fileList.run );
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
        paramFile   = ls(fullfile(sessionDir, [subset.fileName{iR}(1:19) '*.mat']));
        pars        = load( fullfile(sessionDir,paramFile), 'nCuesToShow', 'nRepetitions', 'lookHereStateSeq', 'realP3StateSeqOnsets', 'ssvepFreq', 'scenario' );

        pars.scenario = rmfield(pars.scenario, 'textures');
        
        onsetEventInd   = cellfun( @(x) strcmp(x, 'P300 stim on'), {pars.scenario.events(:).desc} );
        onsetEventValue = pars.scenario.events( onsetEventInd ).id;
        
        
        %--------------------------------------------------------------------------
        erpData     = eegDataset3( sessionDir, filename, 'onsetEventValue', onsetEventValue );
        erpData.tBeforeOnset = tBeforeOnset;
        erpData.tAfterOnset = tAfterOnset;

        %--------------------------------------------------------------------------
        

        %--------------------------------------------------------------------------
        if iR == 1
            samplingRate    = erpData.fs;
            channels        = erpData.chanList( erpData.eegChanInd );
            ssvepFreq       = pars.ssvepFreq;
            
        else
            if erpData.fs ~= samplingRate
                error('runs were not recorded with the same sampling rate!!');
            end
            if ~isequal( channels, erpData.chanList( erpData.eegChanInd ))
                error('runs have different channels');
            end
            if ~isequal(ssvepFreq, pars.ssvepFreq)
                error('runs have different target frequencies');
            end
            
        end

        for iFreq = 1:numel(ssvepFreq)
            if numel( pars.realP3StateSeqOnsets{iFreq} ) ~= numel( erpData.eventPos ),
                error('number of events read from the parameter file and from the bdf file do not match');
            end
        end        
        %--------------------------------------------------------------------------
        erpData.butterFilter(1, 30, 3);
        
        for iFreq = 1:numel(ssvepFreq)
            
            nItems          = numel( unique( pars.realP3StateSeqOnsets{iFreq} ) );
            stimId          = (iFreq-1)*nItems + pars.realP3StateSeqOnsets{iFreq};
            targetStateSeq  = pars.lookHereStateSeq( pars.lookHereStateSeq~=max(pars.lookHereStateSeq) );
            tempp           = repmat( targetStateSeq, nItems*pars.nRepetitions, 1);
            targetId        = tempp(:);
            
            indListTarget = find( stimId(:) == targetId(:) );
            indListNonTarget = find( stimId(:) ~= targetId(:) & ismember(targetId, (iFreq-1)*nItems+1:iFreq*nItems) );
                
            %--------------------------------------------------------------------------------------------
            erpData.markEpochsForRejection('minMax', 'proportion', .15, 'epochInds', indListTarget);
            [sumCut nCuts] = erpData.getSumCut('epochInds', indListTarget);
            
            meanERP{iData}      = sumCut(:, erpData.eegChanInd) / nCuts;
            nEpochs(iData)      = nCuts;
            fs(iData)           = samplingRate;
            chanList{iData}     = channels;
            subject{iData}      = sub{iS};
            frequency(iData)    = ssvepFreq(iFreq);
            run(iData)          = iR;
            type{iData}         = 'target';
            iData = iData+1;
            
            %--------------------------------------------------------------------------------------------
            erpData.markEpochsForRejection('minMax', 'proportion', .15, 'epochInds', indListNonTarget);
            [sumCut nCuts] = erpData.getSumCut('epochInds', indListNonTarget);
            
            meanERP{iData}      = sumCut(:, erpData.eegChanInd) / nCuts;
            nEpochs(iData)      = nCuts;
            fs(iData)           = samplingRate;
            chanList{iData}     = channels;
            subject{iData}      = sub{iS};
            frequency(iData)    = ssvepFreq(iFreq);
            run(iData)          = iR;
            type{iData}         = 'non-target';
            iData = iData+1;
            
        end % OF STIMULATION FREQUENCY LOOP
        
    end % OF RUN LOOP
    
end % OF SUBJECT LOOP

tBeforeOnset    = repmat( tBeforeOnset, iData-1, 1 );
tAfterOnset     = repmat( tAfterOnset, iData-1, 1 );
meanERP(iData:end)      = [];
nEpochs(iData:end)      = [];
fs(iData:end)           = [];
chanList(iData:end)     = [];
subject(iData:end)      = [];
frequency(iData:end)    = [];
run(iData:end)          = [];
type(iData:end)         = [];



meanErpDataset = dataset( ...
    subject, ...
    run, ...
    frequency, ...
    type, ...
    nEpochs, ...
    meanERP, ...
    chanList, ...
    tBeforeOnset, ...
    tAfterOnset, ...
    fs ...
    );

save(fullfile(resultsDir, 'meanErpDataset.mat'), 'meanErpDataset');
