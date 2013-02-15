function watchErpPlots

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
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciData\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciData\watchERP\';
    otherwise,
        error('host not recognized');
end

%%


[bdfFileName, sessionDir, ~]    = uigetfile([dataDir '*.bdf'], 'MultiSelect', 'on');
if isnumeric(bdfFileName) && bdfFileName == 0
    return;
end
bdfFileName = {bdfFileName};


for iF = 1:numel(bdfFileName)
    paramFileName                   = [bdfFileName{iF}(1:19) '.mat'];
    scenarioFileName                = [bdfFileName{iF}(1:19) '-unfolded-scenario.xml'];
    title                           = bdfFileName{iF}(20:end-4);
    
    showPlot(sessionDir, bdfFileName{iF}, paramFileName, scenarioFileName, title);
end
end

function showPlot(sessionDir, bdfFileName, paramFileName, scenarioFileName, titleStr)

refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

filter.fr_low_margin   = 1;
filter.fr_high_margin  = 30;
filter.order           = 3;
filter.type            = 'butter'; % Butterworth IIR filter

tBeforeOnset    = 0.2; % lower time range in secs
tAfterOnset     = 0.8; % upper time range in secs

%% load data, define parameters

expParams       = load( fullfile(sessionDir, paramFileName) );
scenario        = xml2mat( fullfile(sessionDir, scenarioFileName) );

hdr             = sopen( fullfile(sessionDir, bdfFileName) );
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

%% preprocess (discard unused channels, remove baseline, filter, reorder)

sig(:, discardChanInd)  = [];
sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
end
[sig chanList] = reorderEEGChannels(sig, chanList);
sig = sig{1};

%% cut and average target and non-target responses

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


minThreshold = -1000;
maxThreshold = 1000;
targetErps = zeros(range, nChan);
targetInds = find(stimType == 1);
nEpochs = 0;
for i = 1:numel(targetInds)
    iSampleEvent    = stimOnsets(targetInds(i));
    cut             = sig( (iSampleEvent-nl) : (iSampleEvent+nh), : );
    if min(cut(:)) > minThreshold && max(cut(:)) < maxThreshold
        targetErps  = targetErps + cut;
        nEpochs     = nEpochs + 1;
    end
end
targetErps  = targetErps / nEpochs;
nRejected   = numel(targetInds) - nEpochs;
fprintf('%d epochs rejected\n', nRejected);
% targetErps = targetErps / numel(targetInds);

nonTargetErps = zeros(range, nChan);
nonTargetInds = find(stimType == 0);
nEpochs = 0;
for i = 1:numel(nonTargetInds)
    iSampleEvent    = stimOnsets(nonTargetInds(i));
    cut             = sig( (iSampleEvent-nl) : (iSampleEvent+nh), : );
    if min(cut(:)) > minThreshold && max(cut(:)) < maxThreshold
        nonTargetErps   = nonTargetErps + cut;
        nEpochs         = nEpochs + 1;
    end
end
nonTargetErps   = nonTargetErps / nEpochs;
nRejected       = numel(nonTargetInds) - nEpochs;
fprintf('%d epochs rejected\n', nRejected);

%% Plot mean ERPs

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

% s.Format        = 'png';
% s.Resolution    = 300;
% fh = findobj('Name', titleStr);
% set(findobj(fh,'Type','uicontrol'),'Visible','off');
% figName = fullfile( sessionDir, ['erp-' bdfFileName(1:end-4)]);
% % figName = fullfile( sessionDir, ['erp-' bdfFileName(1:end-4) '-noRejection']);
% hgexport(gcf, [figName '.png'], s);
% close(fh);

end