function watchErpFftPlots


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
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
    otherwise,
        error('host not recognized');
end

%%

[bdfFileName, sessionDir, ~]    = uigetfile([dataDir '*.bdf']);
if bdfFileName == 0
    return;
end
paramFileName                   = [bdfFileName(1:19) '.mat'];
scenarioFileName                = [bdfFileName(1:19) '-unfolded-scenario.xml'];
title                           = bdfFileName(20:end-4);

showPlot(sessionDir, bdfFileName, paramFileName, scenarioFileName, title);

end

function showPlot(sessionDir, bdfFileName, paramFileName, scenarioFileName, titleStr)

refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

filter.fr_low_margin   = .2;
filter.fr_high_margin  = 40;
filter.order           = 4;
filter.type            = 'butter'; % Butterworth IIR filter

% tBeforeOnset    = 0.2; % lower time range in secs
% tAfterOnset     = 0.8; % upper time range in secs

%%

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

% nl      	= round(tBeforeOnset*fs);
% nh          = round(tAfterOnset*fs);
% range       = nh+nl+1;

%%

sig(:, discardChanInd)  = [];
sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
end
[sig chanList] = reorderEEGChannels(sig, chanList);
sig = sig{1};

%%
onsetEventInd   = cellfun( @(x) strcmp(x, 'SSVEP stim on'), {scenario.events(:).desc} );
onsetEventValue = scenario.events( onsetEventInd ).id;
eventChan       = logical( bitand( statusChannel, onsetEventValue ) );

stimOnsets      = find( diff( eventChan ) == 1 ) + 1;
stimOffsets     = find( diff( eventChan ) == -1 ) + 1;
epochLenghts    = stimOffsets - stimOnsets + 1;
epochLenght     = min( epochLenghts );
startSamples    = stimOnsets + round( ( epochLenghts - epochLenght ) / 2 );
endSamples      = startSamples + epochLenght - 1;

%%
NFFT    = 2^nextpow2(epochLenght);
f       = fs/2*linspace(0,1,NFFT/2+1);
ampSpec = zeros(numel(f), nChan, numel( startSamples ));
for iE = 1:numel( startSamples )
    
    epoch   = sig( startSamples(iE):endSamples(iE), : );
    for iCh = 1:nChan
        Y = fft(epoch(:, iCh), NFFT)/epochLenght;
        ampSpec(:, iCh, iE) = 2 * abs( Y( 1:NFFT/2+1 ) );
    end
end

%%
meanAmpSpec = mean(ampSpec, 3);
minFreq = 1;
maxFreq = 35;
ff = f( f>=minFreq & f<=maxFreq );
meanAmpSpec = meanAmpSpec( f>=minFreq & f<=maxFreq, :);

plotFfts2( ...
    ff, ...
    meanAmpSpec, ...
    'chanLabels', chanList, ...
    'nMaxChanPerAx', 7, ...
    'title', titleStr, ...
    'scale', 2 ...
    );

s.Format        = 'png';
s.Resolution    = 300;
fh = findobj('Name', titleStr);
set(findobj(fh,'Type','uicontrol'),'Visible','off');
% figName = strrep(titleStr, ' ', '-');
figName = fullfile( sessionDir, ['fft-'  bdfFileName(1:end-4)] );
hgexport(gcf, [figName '.png'], s);
close(fh);








end