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
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciData\basicP3\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciData\basicP3\';
    otherwise,
        error('host not recognized');
end

%%

sessionName = '2012-11-15-adrien';
bdfFileName = '2012-11-15-15-25-47-p3Disappear.bdf';
paramFileName = '2012-11-15-15-25-47.mat';
scenarioFileName = '2012-11-15-15-25-47-unfolded-scenario.xml';
title = 'disappear';
showPlot(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, title);

sessionName = '2012-11-15-adrien';
bdfFileName = '2012-11-15-15-41-06-redDisk.bdf';
paramFileName = '2012-11-15-15-41-06.mat';
scenarioFileName = '2012-11-15-15-41-06-unfolded-scenario.xml';
title = 'red disk';
showPlot(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, title);

sessionName = '2012-11-15-adrien';
bdfFileName = '2012-11-15-16-07-39-disappear-fixedStimDur.bdf';
paramFileName = '2012-11-15-16-07-39.mat';
scenarioFileName = '2012-11-15-16-07-39-unfolded-scenario.xml';
title = 'disappear';
showPlot(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, title);

sessionName = '2012-11-15-adrien';
bdfFileName = '2012-11-15-16-18-47-redDisk-fixedStimDur.bdf';
paramFileName = '2012-11-15-16-18-47.mat';
scenarioFileName = '2012-11-15-16-18-47-unfolded-scenario.xml';
title = 'red disk';
showPlot(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, title);

sessionName = '2012-11-15-adrien';
bdfFileName = '2012-11-15-16-44-53-disappear-fixedStimDur-nonzeroFixedGapDur.bdf';
paramFileName = '2012-11-15-16-44-53.mat';
scenarioFileName = '2012-11-15-16-44-53-unfolded-scenario.xml';
title = 'disappear';
showPlot(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, title);

sessionName = '2012-11-15-adrien';
bdfFileName = '2012-11-15-16-55-50-redDisk-fixedStimDur-nonzeroFixedGapDur.bdf';
paramFileName = '2012-11-15-16-55-50.mat';
scenarioFileName = '2012-11-15-16-55-50-unfolded-scenario.xml';
title = 'red disk';
showPlot(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, title);

sessionName = '2012-11-15-adrien';
bdfFileName = '2012-11-15-17-07-17-disappear-fixedStimDur-nonzeroRandomGapDur.bdf';
paramFileName = '2012-11-15-17-07-17.mat';
scenarioFileName = '2012-11-15-17-07-17-unfolded-scenario.xml';
title = 'disappear';
showPlot(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, title);


sessionName = '2012-11-15-adrien';
bdfFileName = '2012-11-15-17-18-13-redDisk-fixedStimDur-nonzeroRandomGapDur.bdf';
paramFileName = '2012-11-15-17-18-13.mat';
scenarioFileName = '2012-11-15-17-18-13-unfolded-scenario.xml';
title = 'red disk';
showPlot(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, title);

end

function showPlot(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, titleStr)

refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

filter.fr_low_margin   = .5;
filter.fr_high_margin  = 20;
filter.order           = 3;
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

%%
if numel(unique(expParams.stimDurationInSec)) ~= 1
    titleStr  = [titleStr sprintf(' random stim dur [%g-%g sec]', min(expParams.stimDurationInSec), max(expParams.stimDurationInSec))];
else
    titleStr  = [titleStr sprintf(' fixed stim dur [%g sec]', unique(expParams.stimDurationInSec))];
end
if expParams.gapDurationInSec == 0
    titleStr  = [titleStr ' no gap'];
else
    if numel(unique(expParams.gapDurationInSec)) ~= 1
        titleStr  = [titleStr sprintf(' random gap dur [%g-%g sec]', min(expParams.gapDurationInSec), max(expParams.gapDurationInSec))];
    else
        titleStr  = [titleStr sprintf(' fixed gap dur [%g sec]', unique(expParams.gapDurationInSec))];
    end
end

plotERPsFromCutData2( ...
    {targetErps nonTargetErps}, ...
    'samplingRate', fs, ...
    'chanLabels', chanList, ...
    'timeBeforeOnset', tBeforeOnset, ...
    'nMaxChanPerAx', 10, ...
    'axisOfEvent', [1 1], ...
    'legendStr',  {'target', 'nonTarget'}, ...
    'scale', 8, ...
    'title', titleStr ...
    );

s.Format        = 'png';
s.Resolution    = 300;
fh = findobj('Name', titleStr);
set(findobj(fh,'Type','uicontrol'),'Visible','off');
figName = strrep(titleStr, ' ', '-');
hgexport(gcf, [figName '.png'], s);
close(fh);

end