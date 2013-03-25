function checkStatusChannel

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


[bdfFileName, sessionDir, ~]    = uigetfile([dataDir '*.bdf'], 'MultiSelect', 'on');
if isnumeric(bdfFileName) && bdfFileName == 0
    return;
end
if ~iscell(bdfFileName)
    bdfFileName = {bdfFileName};
end

for iF = 1:numel(bdfFileName)

    %% CKECK STATUS CHANNEL
    
    %---------------------------------------------------------------------------------
    hdr                 = sopen( fullfile(sessionDir, bdfFileName{iF}) );
    statusChannel       = bitand(hdr.BDF.ANNONS, 255);    
    plotBitWise( statusChannel );
    set( gcf, 'name', bdfFileName{iF} );
    
    %---------------------------------------------------------------------------------
    paramFileName       = [bdfFileName{iF}(1:19) '.mat'];
    load( fullfile(sessionDir, paramFileName), 'labelList' );
    timeList = labelList(1,:)-labelList(1,1);
    markerList = labelList(2,:);
    seqDurationinMs = ceil(hdr.SampleRate*max(timeList));
    statChan        = nan(seqDurationinMs, 1);
    
    i = 1;
    for j = 2:numel(timeList)
        statChan(i) = markerList(j-1);
        while i < 1+hdr.SampleRate*timeList(j)
            statChan(i+1) = statChan(i);
            i = i+1;
        end
    end
    statChan(i) = markerList(j);
    statChan( isnan(statChan) ) = [];
    
    plotBitWise( statChan );
    set( gcf, 'name', paramFileName );

    
    %% CKECK EEG CHANNELS
    eegData = eegDataset(sessionDir, bdfFileName{iF});
    eegData.butterFilter(.5, 30, 4);
    eegData.plotContinuousSignal;
    
end




end