clear;clc;

% folder = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciData\2012-11-12-Adrien2\';
% bdfFile = fullfile( folder, 'test12HzHybrid.bdf' );
folder = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciData\2012-11-12-Adrien\';
bdfFile = fullfile( folder, 'testP3baseline.bdf' );

hdr = sopen( bdfFile );
[sig hdr] = sread(hdr);
fs = hdr.SampleRate;
chanList = hdr.Label(1:size(sig, 2));

filter.fr_low_margin    = .2;
filter.fr_high_margin   = 40;
filter.order            = 4;
filter.type             = 'butter'; % Butterworth IIR filter
[filter.a filter.b]     = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fs/2));


eegChanInd = 1:32;
refChanInd = 33:34;

sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
end



statusChannel = bitand(hdr.BDF.ANNONS, 255);
p3chan  = logical( bitand( statusChannel, 8 ) );
locs    = find( diff(p3chan) == 1 ) + 1;
clear statusChannel hdr

plotEEGChannels(sig, 'eventLoc', locs, 'samplingRate', 1024, 'chanLabels', chanList );


%%
stimType = [];
% parFileList = {
%     '2012-11-12-14-06-19-12Hz-hybrid-block-01.mat', ...
%     '2012-11-12-14-08-15-12Hz-hybrid-block-02.mat', ...
%     '2012-11-12-14-10-28-12Hz-hybrid-block-03.mat', ...
%     '2012-11-12-14-12-22-12Hz-hybrid-block-04.mat' ...
%     };
parFileList = {
    '2012-11-12-12-56-45-0Hz-P300-baseline-block-01.mat', ...
    '2012-11-12-12-58-51-0Hz-P300-baseline-block-02.mat', ...
    '2012-11-12-13-00-47-0Hz-P300-baseline-block-03.mat', ...
    '2012-11-12-13-02-52-0Hz-P300-baseline-block-04.mat' ...
    };
for iB = 1:numel(parFileList)
    
    par = load( fullfile( folder, parFileList{iB} ) );
    
    stimId      = par.realP3StateSeqOnsets;
    nItems      = numel( unique( par.realP3StateSeqOnsets ) );
    targetStateSeq = par.lookHereStateSeq( par.lookHereStateSeq~=max(par.lookHereStateSeq) );
    tempp        = repmat( targetStateSeq, nItems*par.nRepetitions, 1);
    targetId    = tempp(:);
    stimType    = [ stimType ; double( stimId(:) == targetId(:) ) ];

    
end

evLabels    = {'nonTarget', 'target'};

plotERPsFromContData( ...
    sig, ...
    locs, ...
    'eventType', stimType, ...
    'eventLabel', evLabels, ...
    'samplingRate', fs, ...
    'tl', 0.2, ...
    'th', 0.8, ...
    'chanLabels', chanList, ...
    'nMaxChanPerAx', 20 ...
    );




