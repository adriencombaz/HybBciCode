function preprocessDataSplitRead

%% =====================================================================================
%                           INITIALIZE PARAMETERS

addpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\preprocessData\xmlRelatedFncts\');
expDir      = 'd:\KULeuven\PhD\Work\Hybrid-BCI\';
dataDir     = fullfile(expDir, 'HybBciData');
outputDir	= fullfile(expDir, 'HybBciProcessedData');
sessionName = '2012-11-12-Adrien';

% file lists
%--------------------------------------------------------------------------
folderName  = fullfile(dataDir, sessionName);
fileList    = cellstr(ls(sprintf('%s\\*.bdf', folderName)));
parFileList = cellstr(ls(sprintf('%s\\*.mat', folderName)));
xmlFileList = cellstr(ls(sprintf('%s\\*unfolded-scenario.xml', folderName)));

% identify eog calibration file
%--------------------------------------------------------------------------
temp                = strfind(fileList, 'eog-calibration');
iEogFile            = sum( find ( cellfun(@(x) ~isempty(x), temp ) ) );
if iEogFile
    eogCalibrationFile  = fileList{iEogFile};
    fileList(iEogFile)  = [];
end

% identify main parameter file
%--------------------------------------------------------------------------
temp                = strfind(parFileList, 'ExperimentDetail');
iMainPar            = sum( find ( cellfun(@(x) ~isempty(x), temp ) ) );
if iMainPar
    mainParamFile           = parFileList{iMainPar};
    parFileList(iMainPar)   = [];
else
    error('main parameter file not found!!');
end
mainExpPars = load( fullfile(folderName, mainParamFile) );

% Check that only one bdf file is present
%--------------------------------------------------------------------------
if numel(fileList) ~= 1
    error('not only one bdf file!!');
end
dataFile = fileList{1};

% create output folders
%--------------------------------------------------------------------------
outputFolder        = fullfile(outputDir, sessionName);
rawOutputFolder     = fullfile(outputFolder, 'nonEogCorreted');
if ~exist( rawOutputFolder, 'dir' )
    mkdir(rawOutputFolder)
end

if iEogFile
    eogCorrOutputFolder = fullfile(outputFolder, 'eogCorrected');
    if ~exist( eogCorrOutputFolder, 'dir' )
        mkdir(eogCorrOutputFolder)
    end
end

% external channels
%--------------------------------------------------------------------------
refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG7', 'EXG8'};
eogChan.Names   = {'EXG3', 'EXG4', 'EXG5', 'EXG6'};
eogChan.Labels  = {'left', 'right', 'up', 'down'};
eogChan.HEch    = 'left - right';
eogChan.VEch    = 'up - down';
eogChan.REch    = '(up + down)/2';


% check the lists of files
%--------------------------------------------------------------------------

% check that the lists of .xml and .mat file are consistent 
tag = '-unfolded-scenario';
xmlLabels = cellfun(@(x) x( 1 : strfind(x, tag)-1 ), xmlFileList, 'UniformOutput', false);
tag = '.mat';
parLabels = cellfun(@(x) x( 1 : strfind(x, tag)-1 ), parFileList, 'UniformOutput', false);
if ~isequal(xmlLabels, parLabels)
    error('File list inconsistent')
end

% check that the number of blocks read from the main .mat file is consistent with the number of other .mat files
nBlocksTotal = numel(parFileList);
if nBlocksTotal ~= numel(mainExpPars.blockSequence)
    error('mismatch between number of blocks from the mainExpPars file and the list of parameter files');
end

% check that the order of the blocks is consistent
countBlock = zeros(1, numel(mainExpPars.conditions));
for iB = 1:nBlocksTotal
    
    iCond           = mainExpPars.blockSequence(iB);
    expectedCond    = strrep( mainExpPars.conditions{ iCond }, ' ', '-'  );
    tag             = sprintf( '%s-block-%.2d', expectedCond, countBlock(iCond)+1 );
    countBlock(iCond) = countBlock(iCond)+1;
    
    if ~strfind(parFileList{iB}, tag)
        error('block %d: expected condition/block: %s, found file: %s', iB, tag, parFileList{iB});
    end
    
end
if unique(countBlock) ~= mainExpPars.nBlocksPerCond
    error('error in the block count!!!');
end


% filter parameters (for eog correction)
%--------------------------------------------------------------------------
filter.fr_low_margin   = .2;
filter.fr_high_margin  = 40;
filter.order           = 4;
filter.type            = 'butter'; % Butterworth IIR filter


%% =====================================================================================
%                               TREAT OTHER FILES



hdr = sopen( fullfile(folderName, dataFile) );

statusChannel       = bitand(hdr.BDF.ANNONS, 255);
hdr.BDF             = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
expStartStopChan    = logical( bitand(statusChannel, 1) );
expStartSamples     = find( diff(expStartStopChan) == 1 ) + 1;
expStopSamples      = find( diff(expStartStopChan) == -1 ) + 1;
refChanInd          = cell2mat( cellfun( @(x) find(strcmp(hdr.Label, x)), refChanNames, 'UniformOutput', false ) );
discardChanInd      = cell2mat( cellfun( @(x) find(strcmp(hdr.Label, x)), discardChanNames, 'UniformOutput', false ) );

% sampling rate
fs = hdr.SampleRate;

% channel labels
chanList                 = hdr.Label;
chanList(strcmp(chanList, 'Status')) = [];
chanList(discardChanInd) = [];



% check the status channel
%--------------------------------------------------------------------------
if numel(expStartSamples) ~= nBlocksTotal, error('number of experiment onsets does not match the total number of blocks'); end

% add some more checks ...........




for iC = 1%%%%%%%%%%%%%%:numel(mainExpPars.conditions)
    
    fprintf('\nTreating condition %d out of %d (%s)\n', iC, numel(mainExpPars.conditions), mainExpPars.conditions{iC});
    
    block       = cell(1, mainExpPars.nBlocksPerCond);
    indBlocks   = find(mainExpPars.blockSequence == iC);
    
    % some parameters
    %--------------------------------------------------------------------------

    % condition
    p3On        = mainExpPars.p3OnScen(iC);
    ssvepFreq   = mainExpPars.SsvepFreqScen(iC);    
    
    for iB = 1:mainExpPars.nBlocksPerCond
        fprintf('\tTreating block %d out of %d\n', iB, mainExpPars.nBlocksPerCond);
        
        %
        %--------------------------------------------------------------------------
        iF = indBlocks(iB);
        expParams   = load( fullfile(folderName, parFileList{iF}) );
        scenario    = xml2mat( fullfile(folderName, xmlFileList{iF}) );
        
        %
        %--------------------------------------------------------------------------
        startSample = expStartSamples(iF) - 1;
        stopSample = min( expStopSamples( expStopSamples > startSample + 1) );
        
        [sig, ~] = sread( ...
            hdr, ...
            ( stopSample - startSample + 1 ) / hdr.SampleRate, ...  % Number of seconds to read
            ( startSample-1 ) / hdr.SampleRate ...                  % second after which to start
            );       
        
        % P3 parameters
        %--------------------------------------------------------------------------
        if p3On
            % P3 stimuli index sequence
            block{iB}.p3Params.p3StateSeq = expParams.realP3StateSeqOnsets;
            
            % target state sequence (normally values between 1 and 8 evenly interspersed with 9) (or 1 and 16 evenly interspersed with 17)
            block{iB}.p3Params.targetStateSeq = expParams.lookHereStateSeq( expParams.lookHereStateSeq ~= max( expParams.lookHereStateSeq ) ); % only keep onsets
                        
        end
        
        % Event Channels
        %--------------------------------------------------------------------------
        block{iB}.statusChannel = statusChannel(startSample:stopSample);
        
        % cue event channel
        onsetEventInd           = cellfun( @(x) strcmp(x, 'Cue on'), {scenario.events(:).desc} );
        onsetEventValue         = scenario.events( onsetEventInd ).id;
        block{iB}.eventChan.cue = logical( bitand( block{iB}.statusChannel, onsetEventValue ) );

        % P300 event channel
        if p3On
            onsetEventInd               = cellfun( @(x) strcmp(x, 'P300 stim on'), {scenario.events(:).desc} );
            onsetEventValue             = scenario.events( onsetEventInd ).id;
            block{iB}.eventChan.p3      = logical( bitand( block{iB}.statusChannel, onsetEventValue ) );
        end
        
        % SSVEP event channel
        if ssvepFreq
            onsetEventInd               = cellfun( @(x) strcmp(x, 'SSVEP stim on'), {scenario.events(:).desc} );
            onsetEventValue             = scenario.events( onsetEventInd ).id;
            block{iB}.eventChan.ssvep   = logical( bitand( block{iB}.statusChannel, onsetEventValue ) );
        end    
        
        
        % discard unused channels and Re-reference
        %--------------------------------------------------------------------------------------
        sig(:, discardChanInd)  = [];
        [filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fs/2));
        for i = 1:size(sig, 2)
            sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
        end
        block{iB}.sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
        
    end
    clear sig statusChannel
    %=============================================================================================
    %% CUT, AVERAGE AND PLOT ERPs
    
    tBeforeOnset    = 0.2; % lower time range in secs
    tAfterOnset     = 0.8; % upper time range in secs
    nl      = round(tBeforeOnset*fs);
    nh      = round(tAfterOnset*fs);
    range   = nh+nl+1;
    nChan = numel(chanList);
    
    nEvTot = 0;
    for iB = 1:numel(block), nEvTot = nEvTot + numel(block{iB}.p3Params.p3StateSeq); end

%     epochs      = zeros(range, nChan, nEvTot, 'single');
%     epochs      = zeros(range, nChan, nEvTot);
%     stimType    = zeros(nEvTot, 1);
%     iEv         = 1;
    ErpTarget   = zeros(range, nChan);
    nTarget     = 0;
    ErpNonTarget= zeros(range, nChan);
    nNonTarget  = 0;
    for iB = 1:numel(block)
        
        %
        no = find( diff( block{iB}.eventChan.p3 ) == 1 ) + 1;
        if numel(no) ~= numel(block{iB}.p3Params.p3StateSeq),
            error('mismatch in the number of events and onsets found')
        end
        epochs      = zeros(range, nChan, numel(no));
        
        
%         evInds = iEv:iEv+numel(no)-1;
        
                
        %
        for iE = 1:numel(no)%numel(evInds)
            epochs(:,:,iE) = block{iB}.sig( no(iE)-nl : no(iE)+nh, : );
        end
        
        %
        stimId = block{iB}.p3Params.p3StateSeq;
        
        %
        nItems  = numel( unique( block{1}.p3Params.p3StateSeq ) );
        temp    = repmat( block{iB}.p3Params.targetStateSeq, nItems*expParams.nRepetitions, 1);
        targetId = temp(:);
        
        %
%         stimType(evInds) = ( stimId(:) == targetId(:) );
        stimType = ( stimId(:) == targetId(:) );
        
        %
        ErpTarget       = ErpTarget + sum( epochs( :, :, stimType == 1 ), 3 );
        nTarget         = nTarget + sum(stimType==1);
        ErpNonTarget    = ErpNonTarget + sum( epochs( :, :, stimType == 0 ), 3 );
        nNonTarget      = nNonTarget + sum(stimType==0);

    end
    
    clear block
%     ErpTarget = mean( epochs( :, :, stimType == 1 ), 3 );
%     ErpNonTarget = mean( epochs( :, :, stimType == 0 ), 3 );

%     epochs( :, :, stimType == 1 ) = [];
%     ErpNonTarget = mean( epochs, 3 );

    ErpTarget = ErpTarget / nTarget;
    ErpNonTarget = ErpNonTarget / nNonTarget;

    plotERPsFromCutData2( ...
        {ErpNonTarget, ErpTarget}, ...
        'samplingRate', fs, ...
        'chanLabels', chanList, ...
        'timeBeforeOnset', 0.2, ...
        'nMaxChanPerAx', 20, ...
        'axisOfEvent', [1 2] ...
        );
end

end

