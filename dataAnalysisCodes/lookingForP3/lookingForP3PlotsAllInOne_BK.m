function lookingForP3PlotsAllInOne

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
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciData\lookingForP3\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciData\lookingForP3\';
    otherwise,
        error('host not recognized');
end

%%
% sessionName = '2012-11-19-adrien';
% recTime{1} = '2012-11-19-16-25-54';
% recTime{2} = '';
% recTime{3} = '';
% recTime{4} = '';
% recTime{5} = '';
% recTime{6} = '';
% recTime{7} = '';
% recTime{8} = '';
% 
% isSlow          = nan(numel(recTime), 1);
% isGap           = nan(numel(recTime), 1);
% isNarrow        = nan(numel(recTime), 1);
% ErpsTarget      = cell(numel(recTime), 1);
% ErpsNonTarget   = cell(numel(recTime), 1);
% titleStrList    = cell(numel(recTime), 1);
% chanList        = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};
% tBeforeOnset


sessionName = '2012-11-19-adrien';
bdfFileName = '2012-11-19-16-25-54-slow-gap-narrow.bdf';
paramFileName = '2012-11-19-16-25-54.mat';
scenarioFileName = '2012-11-19-16-25-54-unfolded-scenario.xml';
[sl, gp, nr, evt, evnt, titleStr] = getFromData(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, chanList);
isSlow(1)               = sl;
isGap(1)                = gp;
isNarrow(1)             = nr;
ErpsTarget{1}           = evt;
ErpsNonTarget{1}        = evnt;
titleStrList{1}         = titleStr;

bdfFileName = '2012-11-19-16-40-33-fast-noGap-narrow.bdf';
paramFileName = '2012-11-19-16-40-33.mat';
scenarioFileName = '2012-11-19-16-40-33-unfolded-scenario.xml';
[sl, gp, nr, evt, evnt, titleStr] = getFromData(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, chanList);
isSlow(2)               = sl;
isGap(2)                = gp;
isNarrow(2)             = nr;
ErpsTarget{2}           = evt;
ErpsNonTarget{2}        = evnt;
titleStrList{2}         = titleStr;

bdfFileName = '2012-11-19-16-52-05-slow-noGap-narrow.bdf';
paramFileName = '2012-11-19-16-52-05.mat';
scenarioFileName = '2012-11-19-16-52-05-unfolded-scenario.xml';
[sl, gp, nr, evt, evnt, titleStr] = getFromData(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, chanList);
isSlow(3)               = sl;
isGap(3)                = gp;
isNarrow(3)             = nr;
ErpsTarget{3}           = evt;
ErpsNonTarget{3}        = evnt;
titleStrList{3}         = titleStr;

bdfFileName = '2012-11-19-17-05-53-fast-noGap-spread.bdf';
paramFileName = '2012-11-19-17-05-53.mat';
scenarioFileName = '2012-11-19-17-05-53-unfolded-scenario.xml';
[sl, gp, nr, evt, evnt, titleStr] = getFromData(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, chanList);
isSlow(4)               = sl;
isGap(4)                = gp;
isNarrow(4)             = nr;
ErpsTarget{4}           = evt;
ErpsNonTarget{4}        = evnt;
titleStrList{4}         = titleStr;

bdfFileName = '2012-11-19-17-14-05-fast-gap-spread.bdf';
paramFileName = '2012-11-19-17-14-05.mat';
scenarioFileName = '2012-11-19-17-14-05-unfolded-scenario.xml';
[sl, gp, nr, evt, evnt, titleStr] = getFromData(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, chanList);
isSlow(5)               = sl;
isGap(5)                = gp;
isNarrow(5)             = nr;
ErpsTarget{5}           = evt;
ErpsNonTarget{5}        = evnt;
titleStrList{5}         = titleStr;

bdfFileName = '2012-11-19-17-21-36-fast-gap-narrow.bdf';
paramFileName = '2012-11-19-17-21-36.mat';
scenarioFileName = '2012-11-19-17-21-36-unfolded-scenario.xml';
[sl, gp, nr, evt, evnt, titleStr] = getFromData(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, chanList);
isSlow(6)               = sl;
isGap(6)                = gp;
isNarrow(6)             = nr;
ErpsTarget{6}           = evt;
ErpsNonTarget{6}        = evnt;
titleStrList{6}         = titleStr;

bdfFileName = '2012-11-19-17-33-20-slow-gap-spread.bdf';
paramFileName = '2012-11-19-17-33-20.mat';
scenarioFileName = '2012-11-19-17-33-20-unfolded-scenario.xml';
[sl, gp, nr, evt, evnt, titleStr] = getFromData(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, chanList);
isSlow(7)               = sl;
isGap(7)                = gp;
isNarrow(7)             = nr;
ErpsTarget{7}           = evt;
ErpsNonTarget{7}        = evnt;
titleStrList{7}         = titleStr;

bdfFileName = '2012-11-19-17-45-42-slow-noGap-spread.bdf';
paramFileName = '2012-11-19-17-45-42.mat';
scenarioFileName = '2012-11-19-17-45-42-unfolded-scenario.xml';
[sl, gp, nr, evt, evnt, titleStr] = getFromData(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, chanList);
isSlow(8)               = sl;
isGap(8)                = gp;
isNarrow(8)             = nr;
ErpsTarget{8}           = evt;
ErpsNonTarget{8}        = evnt;
titleStrList{8}         = titleStr;

p3CutsDataset = dataset( isNarrow, isSlow, isGap, ErpsTarget, ErpsNonTarget, titleStrList);
[dum IX] = sort(p3CutsDataset.isGap);
p3CutsDataset = p3CutsDataset(IX, :);
[dum IX] = sort(p3CutsDataset.isSlow);
p3CutsDataset = p3CutsDataset(IX, :);
[dum IX] = sort(p3CutsDataset.isNarrow);
p3CutsDataset = p3CutsDataset(IX, :);

plotERPsFromCutData2( ...
    [p3CutsDataset.ErpsTarget' p3CutsDataset.ErpsNonTarget'], ...
    'samplingRate', 1024, ...
    'chanLabels', chanList, ...
    'timeBeforeOnset', 0.2, ...
    'nMaxChanPerAx', 12, ...
    'axisOfEvent', [1:8 1:8], ...
    'legendStr',  {'target', 'nonTarget'}, ...
    'scale', 8, ...
    'axisTitles', p3CutsDataset.titleStrList ...
    );


end

function [sl, gp, nr, evt, evnt, titleStr] = getFromData(dataDir, sessionName, bdfFileName, paramFileName, scenarioFileName, chanList)


refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

filter.fr_low_margin   = .5;
filter.fr_high_margin  = 30;
filter.order           = 3;
filter.type            = 'butter'; % Butterworth IIR filter

tBeforeOnset    = 0.2; % lower time range in secs
tAfterOnset     = 0.8; % upper time range in secs

nChan = numel(chanList);

%%

expParams       = load( fullfile(dataDir, sessionName, paramFileName) );
scenario        = xml2mat( fullfile(dataDir, sessionName, scenarioFileName) );

sl = strcmp(expParams.fastOrSlow, 'slow');
gp = strcmp(expParams.gapOrNoGap, 'gap');
nr = strcmp(expParams.narrowOrSpread, 'narrow');

if sl, titleStr = 'slow'; else, titleStr = 'fast'; end
if gp, titleStr = [titleStr '-gap']; else titleStr = [titleStr '-noGap']; end
if nr, titleStr = [titleStr '-narrow']; else titleStr = [titleStr '-spread']; end

%%

hdr             = sopen( fullfile(dataDir, sessionName, bdfFileName) );
[sig hdr]       = sread(hdr);
statusChannel   = bitand(hdr.BDF.ANNONS, 255);
hdr.BDF         = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
fs              = hdr.SampleRate;

fullChanList    = hdr.Label;
fullChanList(strcmp(fullChanList, 'Status')) = [];
discardChanInd  = cell2mat( cellfun( @(x) find(strcmp(fullChanList, x)), discardChanNames, 'UniformOutput', false ) );
fullChanList(discardChanInd) = [];
refChanInd      = cell2mat( cellfun( @(x) find(strcmp(fullChanList, x)), refChanNames, 'UniformOutput', false ) );
chanListInd     = cell2mat( cellfun( @(x) find(strcmp(fullChanList, x)), chanList, 'UniformOutput', false ) );

[filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fs/2));

nl      	= round(tBeforeOnset*fs);
nh          = round(tAfterOnset*fs);
range       = nh+nl+1;

%%

sig(:, discardChanInd)  = [];
sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
sig = sig(:, chanListInd);
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
end

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


evt         = zeros(range, nChan);
targetInds  = find(stimType == 1);
for i = 1:numel(targetInds)
    iSampleEvent    = stimOnsets(targetInds(i));
    evt      = evt + sig( (iSampleEvent-nl) : (iSampleEvent+nh), : );
end
evt = evt / numel(targetInds);

evnt            = zeros(range, nChan);
nonTargetInds   = find(stimType == 0);
for i = 1:numel(nonTargetInds)
    iSampleEvent    = stimOnsets(nonTargetInds(i));
    evnt   = evnt + sig( (iSampleEvent-nl) : (iSampleEvent+nh), : );
end
evnt = evnt / numel(nonTargetInds);

end