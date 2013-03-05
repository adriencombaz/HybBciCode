function showContinuousEEG
    
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

filter.fr_low_margin   = 1;
filter.fr_high_margin  = 30;
filter.order           = 4;
filter.type            = 'butter'; % Butterworth IIR filter

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

%%
sig(:, discardChanInd)  = [];
sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
end
[sig chanList] = reorderEEGChannels(sig, chanList);
sig = sig{1};

%%
temp        = diff(statusChannel);
eventLocs   = find( temp > 0 ) + 1;
eventType   = temp( eventLocs - 1);

%%
plotEEGChannels( ...
                sig, ...
                'eventLoc', eventLocs, ...
                'eventType', eventType, ...
                'samplingRate', fs, ...
                'chanLabels', chanList ...
                )


end
