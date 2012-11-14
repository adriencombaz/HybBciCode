function oddballPlots

%%

addpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\preprocessData\xmlRelatedFncts\');

dataDir = '';
bdfFileName = '';
% paramFileName = '';
scenarioFileName = '';

refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

filter.fr_low_margin   = .2;
filter.fr_high_margin  = 40;
filter.order           = 4;
filter.type            = 'butter'; % Butterworth IIR filter

tBeforeOnset    = 0.2; % lower time range in secs
tAfterOnset     = 0.8; % upper time range in secs

%%

% expParams       = load( fullfile(folderName, paramFileName) );
scenario        = xml2mat( fullfile(folderName, scenarioFileName) );

hdr             = sopen( fullfile(dataDir, bdfFileName) );
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

onsetEventInd   = cellfun( @(x) strcmp(x, 'rare on'), {scenario.events(:).desc} );
onsetEventValue = scenario.events( onsetEventInd ).id;
rareEventChan   = logical( bitand( statusChannel, onsetEventValue ) );

onsetEventInd   = cellfun( @(x) strcmp(x, 'frequent on'), {scenario.events(:).desc} );
onsetEventValue = scenario.events( onsetEventInd ).id;
freqEventChan   = logical( bitand( statusChannel, onsetEventValue ) );

%%

sig(:, discardChanInd)  = [];
sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
end

%%

rareOnsets = find( diff( rareEventChan ) == 1 ) + 1;
freqOnsets = find( diff( freqEventChan ) == 1 ) + 1;

rareErps = zeros(range, nChan);
for iE = 1:numel(rareOnsets)
    rareErps = rareErps + sig( (rareOnsets(iE)-nl) : (rareOnsets(iE)+nh), : );
end
rareErps = rareErps/numel(rareOnsets);

freqErps = zeros(range, nChan);
for iE = 1:numel(freqOnsets)
    freqErps = freqErps + sig( (freqOnsets(iE)-nl) : (freqOnsets(iE)+nh), : );
end
freqErps = freqErps/numel(freqOnsets);


[rareErps OrdChanList] = reorderEEGChannels(rareErps, chanList); %#ok<NASGU>
[freqErps OrdChanList] = reorderEEGChannels(freqErps, chanList);


plotERPsFromCutData2( ...
    {rareErps freqErps}, ...
    'samplingRate', fs, ...
    'chanLabels', OrdChanList, ...
    'timeBeforeOnset', tBeforeOnset, ...
    'nMaxChanPerAx', 10, ...
    'axisOfEvent', [1 1], ...
    'legendStr',  {'rare', 'frequent'} ...
    );


end