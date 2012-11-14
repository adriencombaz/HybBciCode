function preprocessDataSingleRead

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
[sig hdr] = sread(hdr);

statusChannel       = bitand(hdr.BDF.ANNONS, 255);
hdr.BDF             = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
expStartStopChan    = logical( bitand(statusChannel, 1) );
expStartSamples     = find( diff(expStartStopChan) == 1 ) + 1;
expStopSamples      = find( diff(expStartStopChan) == -1 ) + 1;
refChanInd          = cell2mat( cellfun( @(x) find(strcmp(hdr.Label, x)), refChanNames, 'UniformOutput', false ) );
discardChanInd      = cell2mat( cellfun( @(x) find(strcmp(hdr.Label, x)), discardChanNames, 'UniformOutput', false ) );

% sampling rate
fs = hdr.SampleRate;
if iEogFile && fsEogCal~=fs, warning('preprocessData:fs', 'sampling rate of eog calibration file and data file are different!!'); end

% channel labels
chanList                 = hdr.Label;
chanList(strcmp(chanList, 'Status')) = [];
chanList(discardChanInd) = [];
if iEogFile && ~isequal(chanListEogCal, chanList), warning('preprocessData:chanList', 'channel list of eog calibration file and data file are different!!'); end



% check the status channel
%--------------------------------------------------------------------------
if numel(expStartSamples) ~= nBlocksTotal, error('number of experiment onsets does not match the total number of blocks'); end

% add some more checks ...........

p3On        = 1;
ssvepFreq   = 0;
indBlocks   = find(mainExpPars.blockSequence == 1);
p3Params.p3StateSeq = [];
p3Params.targetStateSeq = [];
for iB = 1:mainExpPars.nBlocksPerCond
    iF = indBlocks(iB);
    expParams   = load( fullfile(folderName, parFileList{iF}) );
    scenario    = xml2mat( fullfile(folderName, xmlFileList{iF}) );
    if p3On
        p3Params.p3StateSeq = [p3Params.p3StateSeq expParams.realP3StateSeqOnsets];
        p3Params.targetStateSeq = [p3Params.targetStateSeq expParams.lookHereStateSeq( expParams.lookHereStateSeq ~= max( expParams.lookHereStateSeq ) )];
    end
end

% cue event channel
onsetEventInd           = cellfun( @(x) strcmp(x, 'Cue on'), {scenario.events(:).desc} );
onsetEventValue         = scenario.events( onsetEventInd ).id;
eventChan.cue           = logical( bitand( statusChannel, onsetEventValue ) );

% P300 event channel
if p3On
    onsetEventInd               = cellfun( @(x) strcmp(x, 'P300 stim on'), {scenario.events(:).desc} );
    onsetEventValue             = scenario.events( onsetEventInd ).id;
    eventChan.p3                = logical( bitand( statusChannel, onsetEventValue ) );
end

% SSVEP event channel
if ssvepFreq
    onsetEventInd               = cellfun( @(x) strcmp(x, 'SSVEP stim on'), {scenario.events(:).desc} );
    onsetEventValue             = scenario.events( onsetEventInd ).id;
    eventChan.ssvep             = logical( bitand( statusChannel, onsetEventValue ) );
end


% discard unused channels and Re-reference
%--------------------------------------------------------------------------------------
sig(:, discardChanInd)  = [];
refChanInd = 1:32;
sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );


[filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fs/2));
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
end


%======================================================================================
%% CUT AND AVERAGE ERPs
locs    = find( diff(eventChan.p3) == 1 ) + 1;
stimId  = p3Params.p3StateSeq(:);
nItems  = numel( unique( p3Params.p3StateSeq ) );
temp    = repmat( p3Params.targetStateSeq, nItems*expParams.nRepetitions, 1);
targetId    = temp(:);
stimType    = double( stimId == targetId );
evLabels    = {'nonTarget', 'target'};
plotERPsFromContData( ...
    sig, ...
    locs, ...
    'eventType', stimType, ...
    'samplingRate', fs, ...
    'tl', 0.2, ...
    'th', 0.8, ...
    'chanLabels', chanList, ...
    'nMaxChanPerAx', 20 ...
    );

%     'eventLabel', evLabels, ...





end

