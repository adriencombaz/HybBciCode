function basicP3Plots

%%

%%
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
        addpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\preprocessData\xmlRelatedFncts\');
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciData\basicP3\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciData\basicP3\';
    otherwise,
        error('host not recognized');
end

%%

sessionName = '2012-11-14-test';
bdfFileName = '2012-11-14-17-07-51-watermelonP3Disappear.bdf';
paramFileName = '2012-11-14-17-07-51.mat';
scenarioFileName = '2012-11-14-17-07-51-unfolded-scenario.xml';

refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

filter.fr_low_margin   = .2;
filter.fr_high_margin  = 40;
filter.order           = 4;
filter.type            = 'butter'; % Butterworth IIR filter

tBeforeOnset    = 0.2; % lower time range in secs
tAfterOnset     = 0.8; % upper time range in secs

%%

expParams       = load( fullfile(dataDir, sessionName, paramFileName) );
scenario        = xml2mat( fullfile(dataDir, sessionName, scenarioFileName) );

hdr             = sopen( fullfile(dataDir, sessionName, bdfFileName) );
[sig hdr]       = sread(hdr);
statusChannel   = bitand(hdr.BDF.ANNONS, 255);
hdr.BDF         = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
fs              = hdr.SampleRate;

chanList        = hdr.Label;
chanList(strcmp(chanList, 'Status')) = [];
discardChanInd  = cell2mat( cellfun( @(x) find(strcmp(chanList, x)), discardChanNames, 'UniformOutput', false ) );
chanList(discardChanInd) = [];
refChanInd      = cell2mat( cellfun( @(x) find(strcmp(chanList, x)), refChanNames, 'UniformOutput', false ) );
nChan = numel(chanList);

[filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fs/2));

nl      	= round(tBeforeOnset*fs);
nh          = round(tAfterOnset*fs);
range       = nh+nl+1;

%%

sig(:, discardChanInd)  = [];
sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
end
[sig chanList] = reorderEEGChannels(sig, chanList);
sig = sig{1};

%%

onsetEventInd   = cellfun( @(x) strcmp(x, 'P300 stim on'), {scenario.events(:).desc} );
onsetEventValue = scenario.events( onsetEventInd ).id;
eventChan       = logical( bitand( statusChannel, onsetEventValue ) );

stimOnsets      = find( diff( eventChan ) == 1 ) + 1;

stimId          = expParams.realP3StateSeqOnsets;
nItems          = numel( unique( expParams.realP3StateSeqOnsets ) );
targetStateSeq  = expParams.lookHereStateSeq( expParams.lookHereStateSeq~=max(expParams.lookHereStateSeq) );
tempp           = repmat( targetStateSeq, nItems*expParams.nRepetitions, 1);
targetId        = tempp(:);
stimType        = double( stimId(:) == targetId(:) );


targetErps = zeros(range, nChan);
targetInds = find(stimType == 1);
for i = 1:numel(targetInds)
    iSampleEvent    = stimOnsets(targetInds(i));
    targetErps      = targetErps + sig( (iSampleEvent-nl) : (iSampleEvent+nh), : );
end
targetErps = targetErps / numel(targetInds);

nonTargetErps = zeros(range, nChan);
nonTargetInds = find(stimType == 0);
for i = 1:numel(nonTargetInds)
    iSampleEvent    = stimOnsets(nonTargetInds(i));
    nonTargetErps   = nonTargetErps + sig( (iSampleEvent-nl) : (iSampleEvent+nh), : );
end
nonTargetErps = nonTargetErps / numel(nonTargetInds);

plotERPsFromCutData2( ...
    {targetErps nonTargetErps}, ...
    'samplingRate', fs, ...
    'chanLabels', chanList, ...
    'timeBeforeOnset', tBeforeOnset, ...
    'nMaxChanPerAx', 10, ...
    'axisOfEvent', [1 1], ...
    'legendStr',  {'target', 'nonTarget'} ...
    );


end