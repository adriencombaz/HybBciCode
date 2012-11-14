%%
% cl;
clear;clc;
dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\';

session = '2012-11-08-Adrien';

% eogTag = 'eogCorrected';
eogTag = 'nonEogCorreted';

doFiltering = 1;
% doFiltering = 0;

stimType = '0Hz-P300-baseline';
% stimType = '12Hz-hybrid';
% stimType = '';
% stimType = '';
% stimType = '';

% iBlock = 1;
% iBlock = 2;
% iBlock = 3;
iBlock = 4;

load( [ fullfile(dataDir, session, eogTag, stimType) '.mat' ] );

%%
filter.fr_low_margin    = .2;
filter.fr_high_margin   = 40;
filter.order            = 4;
filter.type             = 'butter'; % Butterworth IIR filter
[filter.a filter.b]     = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fs/2));


signal = zeros( size(block{iBlock}.sig) );
if doFiltering
    for i = 1:size(block{iBlock}.sig, 2)
        signal(:,i) = filtfilt( filter.a, filter.b, block{iBlock}.sig(:,i) );
    end
end

%%
eventChanNames = fieldnames(block{1}.eventChan);
nEventChan = numel(eventChanNames);

evL = [];
evT = [];
eventLabel = {};
for iCh = 1:nEventChan
    
    evLa = find( diff(block{1}.eventChan.(eventChanNames{iCh})) == 1 ) + 1;
    evTa = (2*iCh-1)*ones(size(evLa));
    eventLabel = [ eventLabel [eventChanNames{iCh} ' on'] ];
    evLb = find( diff(block{1}.eventChan.(eventChanNames{iCh})) == -1 ) + 1;
    evTb = 2*iCh*ones(size(evLb));
    eventLabel = [ eventLabel [eventChanNames{iCh} ' off'] ];
    
    evL = [evL ; evLa ; evLb];
    evT = [evT ; evTa ; evTb];
    
end

[eventLoc IX]  = sort(evL);
eventType      = evT(IX);


%%
plotEEGChannels(signal, 'eventLoc', eventLoc, 'eventType', eventType, 'samplingRate', fs, 'chanLabels', chanList)

%%

locs        = find( diff(block{1}.eventChan.p3) == 1 ) + 1;
stimId      = block{iBlock}.p3Params.p3StateSeq(:);
nItems      = numel( unique( block{iBlock}.p3Params.p3StateSeq ) );
temp        = repmat( block{iBlock}.p3Params.targetStateSeq, nItems*expParams.nRepetitions, 1);
targetId    = temp(:);
stimType    = double( stimId == targetId );
evLabels    = {'nonTarget', 'target'};

plotERPsFromContData( ...
    signal, ...
    locs, ...
    'eventType', stimType, ...
    'eventLabel', evLabels, ...
    'samplingRate', fs, ...
    'tl', 0.2, ...
    'th', 0.8, ...
    'chanLabels', chanList, ...
    'nMaxChanPerAx', 20 ...
    );















