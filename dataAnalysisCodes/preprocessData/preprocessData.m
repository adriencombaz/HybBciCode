function preprocessData

%% =====================================================================================
%                           INITIALIZE PARAMETERS

addpath(fullfile(cd, 'xmlRelatedFncts'));
expDir      = 'd:\KULeuven\PhD\Work\Hybrid-BCI\';
dataDir     = fullfile(expDir, 'HybBciData');
outputDir	= fullfile(expDir, 'HybBciProcessedData');
sessionName = '2012-10-29-Watermelon';

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
refChanNames    = {'EXG5', 'EXG6'};
discardChanNames= {'EXG7', 'EXG8'};
eogChan.Names   = {'EXG1', 'EXG2', 'EXG3', 'EXG4'};
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
%                    COMPUTER EOG CORRECTION PARAMETERS

if iEogFile
    
    % read eog calibration data file
    %--------------------------------------------------------------------------
    fprintf('\nLoading eog calibration data\n');
    hdr             = sopen( fullfile(folderName, eogCalibrationFile) );
    [sig hdr]       = sread(hdr);
    fsEogCal        = hdr.SampleRate;
    eventLoc        = hdr.EVENT.POS;
    eventType       = hdr.EVENT.TYP;
    chanListEogCal  = hdr.Label;
    chanListEogCal(strcmp(chanListEogCal, 'Status')) = [];
    
    
    % discard unused channels
    %--------------------------------------------------------------------------
    discardChanInd          = cell2mat( cellfun( @(x) find(strcmp(hdr.Label, x)), discardChanNames, 'UniformOutput', false ) );
    sig(:, discardChanInd)  = [];
    chanListEogCal(discardChanInd)= [];
    
    % re-reference EEG signals
    %--------------------------------------------------------------------------
    refChanInd  = cell2mat( cellfun( @(x) find(strcmp(hdr.Label, x)), refChanNames, 'UniformOutput', false ) );
    sig         = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
    
    % filter data
    %--------------------------------------------------------------------------
    [filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fsEogCal/2));
    sig = filtfilt( filter.a, filter.b, sig );
    
    % Compute EOG regression coefficients
    %--------------------------------------------------------------------------
    fprintf('Computing EOG regression coefficients\n');
    [Bv Bh Br]  = computeEogRegCoeff(sig, eventLoc, eventType, fsEogCal, eogChan, chanListEogCal);
    
end

%% =====================================================================================
%                               TREAT OTHER FILES



hdr = sopen( fullfile(folderName, dataFile) );

statusChannel   = bitand(hdr.BDF.ANNONS, 255);
hdr.BDF         = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...

for iF = 1:nBlocksTotal

% read data files
%--------------------------------------------------------------------------
fprintf('Loading data file %s (%d out of %d)\n', fileList{iF}, iF, numel(fileList));
expParams   = load( fullfile(folderName, parFileList{iF}) );
scenario    = xml2mat( fullfile(folderName, xmlFileList{iF}) );


% work on the status channel
%--------------------------------------------------------------------------

% onset and offset event values experiment start and stop (normally +1, -1)
onsetEventInd       = cellfun( @(x) strcmp(x, 'start event'), {scenario.events(:).desc} );
offsetEventInd      = cellfun( @(x) strcmp(x, 'end event'), {scenario.events(:).desc} );
expStartEventValue  = scenario.events( onsetEventInd ).id;
expStopEventValue   = scenario.events( offsetEventInd ).id;
if iF == 1
    expStartStopChan = logical( bitand(statusChannel, expStartEventValue) );
else
end



[sig hdr]   = sread(hdr);

% experiment paramters
%--------------------------------------------------------------------------
if strfind(scenario.description, 'SSVEP Baseline')
    p3On = 0;
    ssvepOn = 1;
else
    p3On = 1;
    ssvepOn = 1;
    if expParams.SSVEPStateSeq == 2
        ssvepOn = 0;
    end
end

% SSVEP parameters
%--------------------------------------------------------------------------
if ssvepOn
    % stimulation frequencies (1st -> left square, 2nd -> right square)
    ssvepParams.frequencies         = expParams.stimFreq;
    
    % onset and offset event values for SSVEP stimuli (normally +4, -4)
    onsetEventInd                   = cellfun( @(x) strcmp(x, 'SSVEP stim on'), {scenario.events(:).desc} );
    offsetEventInd                  = cellfun( @(x) strcmp(x, 'SSVEP stim off'), {scenario.events(:).desc} );
    ssvepParams.onsetEventValue     = scenario.events( onsetEventInd ).id;
    ssvepParams.offsetEventValue    = scenario.events( offsetEventInd ).id;
    
    if ~p3On % ssvep baseline case
        % target state sequence (normally values between 1 and 2 evenly interspersed with 3)
        % (assumed here that 1 is for the left square and 2 for the right square)
        ssvepParams.targetStateSeq = expParams.lookHereStateSeq( expParams.lookHereStateSeq ~= max( expParams.lookHereStateSeq ) ); % only keep onsets
    end
    
end

% P3 parameters
%--------------------------------------------------------------------------
if p3On
    % P3 stimuli index sequence (normally values between 1 and 4 evenly interspersed with 5) (or 1 and 6 evenly interspersed with 7)
    p3Params.p3StateSeq = expParams.realP3StateSeqOnsets( expParams.realP3StateSeqOnsets ~= max( expParams.realP3StateSeqOnsets ) ); % only keep onsets
    
    % target state sequence (normally values between 1 and 8 evenly interspersed with 9) (or 1 and 16 evenly interspersed with 17)
    p3Params.targetStateSeq = expParams.lookHereStateSeq( expParams.lookHereStateSeq ~= max( expParams.lookHereStateSeq ) ); % only keep onsets
    
    % find to which square each target belongs to (1 -> left, 2 -> right, to be mapped with ssvepParams.frequencies)
    targetList = unique(p3Params.targetStateSeq);
    p3Params.targetInSquare = zeros(size(targetList))';
        
                        % first find the x-position for each stimuli
    iSSVEPStimuli = find( cellfun( @(x) strcmp(x, 'SSVEP stimulus'), {scenario.stimuli(:).description} ) );
    if numel(iSSVEPStimuli) ~= 2, error('error in the number of SSVEP stimuli read from the xml file'); end
    xposFreq    = zeros(numel(iSSVEPStimuli), 2);
    for i = 1:numel(iSSVEPStimuli)
        for iState = 1:numel(scenario.stimuli(i).states)
            if scenario.stimuli(i).states(iState).views.iTexture ~= 0
                xposFreq(i,:) = scenario.stimuli(i).desired.position([1, 3]);
            end
        end
    end
                        % then check to which square each target belongs 
                        % (it is assumed here that indice 1 corresponds to the left square 
                        % and 2 to the right square, as it was the case for ssvepParams.frequencies)
    iCueStim = cellfun( @(x) strcmp(x, 'Look here stimulus'), {scenario.stimuli(:).description} );
    for iT = targetList
        xposCue = scenario.stimuli(iCueStim).states(iT).position([1 3]);
        for iSQ = 1:numel(iSSVEPStimuli)
            if ( xposCue(1) > xposFreq(iSQ,1) && xposCue(2) < xposFreq(iSQ,2) )
                p3Params.targetInSquare(iT) = iSQ;
            end
        end
        if p3Params.targetInSquare(iT) == 0
            error('error reading cue positions: they don''t seem to be contained by any of the SSVEP stimuli');
        end
    end    
        
    % onset event values for P300 stimuli (normally +8, -8)
    onsetEventInd                = cellfun( @(x) strcmp(x, 'P300 stim on'), {scenario.events(:).desc} );
    p3Params.onsetEventValue     = scenario.events( onsetEventInd ).id;
end

% other parameters
%--------------------------------------------------------------------------

% sampling rate
fs = hdr.SampleRate;
if fsEogCal~=fs, warning('sampling rate of eog calibration file and data file are different!!'); end

% channel labels
chanList                 = hdr.Label;
discardChanInd           = cell2mat( cellfun( @(x) find(strcmp(hdr.Label, x)), discardChanNames, 'UniformOutput', false ) );
chanList(strcmp(chanList, 'Status')) = [];
chanList(discardChanInd) = [];
if ~isequal(chanListEogCal, chanList), warning('channel list of eog calibration file and data file are different!!'); end


% onset and offset event values for cue stimuli (normally +2, -2)
onsetEventInd       = cellfun( @(x) strcmp(x, 'Cue on'), {scenario.events(:).desc} );
offsetEventInd      = cellfun( @(x) strcmp(x, 'Cue off'), {scenario.events(:).desc} );
cueOnEventValue     = scenario.events( onsetEventInd ).id;
cueOffEventValue    = scenario.events( offsetEventInd ).id;


% status channel per event type
%--------------------------------------------------------------------------
if statusChannel(1) ~= 0
    fprintf('\tfile %s: status channel does not start with 0 (probably markers were not cleared before starting the experiment\n', fileList{iF});
    iSt = find( statusChannel == 0, 1 );
    statusChannel(1:iSt-1) = 0;
%     statusChannel(1:iSt-1) = [];
end

% % % % % % % % % % % % % % % eventChan.experiment = logical( bitand(statusChannel, expStartEventValue) );
eventChan.cue = logical( bitand(statusChannel, cueOnEventValue) );
if p3On
    eventChan.p3 = logical( bitand(statusChannel, p3Params.onsetEventValue) );
end
if ssvepOn
    eventChan.ssvep = logical( bitand(statusChannel, ssvepParams.onsetEventValue) );
end


%--------------------------------------------------------------------------------------
% discard unused channels and Re-reference
sig(:, discardChanInd)  = [];
sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );

%--------------------------------------------------------------------------------------
% save raw re-referenced data
rawFileName = fullfile( rawOutputFolder, [fileLabels{iF} '.mat']);
fprintf('   Saving raw data to file %s\n', rawFileName); 
listOfVariablesToSave = { ...
    'sig', ...
    'hdr', ...          % normally, not necessary
    'scenario', ...     % normally, not necessary
    'expParams', ...    % normally, not necessary
    'fs', ...
    'p3On', ...
    'ssvepOn', ...
    'chanList', ...
    'statusChannel', ...
    'eventChan', ...
    'expStartEventValue', ...
    'expStopEventValue', ...
    'cueOnEventValue', ...
    'cueOffEventValue' ...
    };

if p3On, listOfVariablesToSave = [listOfVariablesToSave, 'p3Params']; end
if ssvepOn, listOfVariablesToSave = [listOfVariablesToSave, 'ssvepParams']; end

save( rawFileName, listOfVariablesToSave{:} );

if iEogFile
    
    %--------------------------------------------------------------------------------------
    % Preliminary filtering
    [filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fs/2));
    % sig = filtfilt( filter.a, filter.b, sig );
    for i = 1:size(sig, 2)
        sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
    end
    
    
    %--------------------------------------------------------------------------------------
    % Apply EOG correction
    sig = applyEogCorrection(sig, Bv, Br, Bh, eogChan, chanListEogCal);
    
    %--------------------------------------------------------------------------------------
    % save eog corrected data
    eogCorrFileName = fullfile( eogCorrOutputFolder, [fileLabels{iF} '-eog-corrected.mat']);
    fprintf('   Saving eog corrected data to file %s\n', eogCorrFileName);
    save( eogCorrFileName, listOfVariablesToSave{:} );
    
    clear(listOfVariablesToSave{:})
    
end

end

end

