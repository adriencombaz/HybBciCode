function lookingForP3PlotsAllInOne
        
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
%             dataDir2 = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciData\oddball\';
        case 'neu-wrk-0158',
            addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
            dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciData\lookingForP3\';
%             dataDir2= 'd:\Adrien\Work\Hybrid-BCI\HybBciData\oddball\';
        otherwise,
            error('host not recognized');
    end
    
    %%
    chanList        = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};
    tBeforeOnset    = 0.2; % lower time range in secs
    tAfterOnset     = 0.8; % upper time range in secs
    refChanNames    = {'EXG1', 'EXG2'};
    discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};
    
    filter.fr_low_margin   = .5;
    filter.fr_high_margin  = 25;
    filter.order           = 3;
    filter.type            = 'butter'; % Butterworth IIR filter
    
    nChan = numel(chanList);
    
    %
    sessionName = '2012-11-19-adrien';
    recTime{1} = '2012-11-19-16-25-54';
    recTime{2} = '2012-11-19-16-40-33';
    recTime{3} = '2012-11-19-16-52-05';
    recTime{4} = '2012-11-19-17-05-53';
    recTime{5} = '2012-11-19-17-14-05';
    recTime{6} = '2012-11-19-17-21-36';
    recTime{7} = '2012-11-19-17-33-20';
    recTime{8} = '2012-11-19-17-45-42';
    
%     sessionName = '2012-11-20-nikolay';
%     recTime{1} = '2012-11-20-14-33-07';
%     recTime{2} = '2012-11-20-14-44-50';
%     recTime{3} = '2012-11-20-14-56-27';
%     recTime{4} = '2012-11-20-15-04-56';
%     recTime{5} = '2012-11-20-15-19-53';
%     recTime{6} = '2012-11-20-15-31-06';
%     recTime{7} = '2012-11-20-15-38-50';
%     recTime{8} = '2012-11-20-15-47-03';
% 
%     sessionName = '2012-11-22-nikolay';
%     recTime{1} = '2012-11-22-14-41-09';
%     recTime{2} = '2012-11-22-14-52-19';
%     recTime{3} = '2012-11-22-15-03-37';
%     recTime{4} = '2012-11-22-15-11-02';
%     recTime{5} = '2012-11-22-15-22-30';
%     recTime{6} = '2012-11-22-15-33-38';
%     recTime{7} = '2012-11-22-15-41-02';
%     recTime{8} = '2012-11-22-15-48-15';
% 
    nCond           = numel(recTime);
    isSlow          = nan(nCond, 1);
    isGap           = nan(nCond, 1);
    isNarrow        = nan(nCond, 1);
    ErpsTarget      = cell(nCond, 1);
    ErpsNonTarget   = cell(nCond, 1);
    titleStrList    = cell(nCond, 1);
    
    for iF = 1:nCond
        
        fprintf('reading from file %d out of %d\n', iF, nCond);
        bdfFileName         = ls( [fullfile(dataDir, sessionName, recTime{iF}) '*.bdf']);
        paramFileName       = ls( [fullfile(dataDir, sessionName, recTime{iF}) '*.mat']);
        scenarioFileName    = ls( [fullfile(dataDir, sessionName, recTime{iF}) '*.xml']);
        [sl, gp, nr, evt, evnt, titleStr] = getFromData();
        isSlow(iF)               = sl;
        isGap(iF)                = gp;
        isNarrow(iF)             = nr;
        ErpsTarget{iF}           = evt;
        ErpsNonTarget{iF}        = evnt;
        titleStrList{iF}         = titleStr;
        
    end
    
    
    %%
%     sessionName = '2012-11-19-adrien';
%     bdfFileName = 'oddball.bdf';
%     % paramFileName = '';
%     scenarioFileName = '2012-11-19-18-00-43-unfolded-scenario.xml';
%     
%     [rareErps freqErps] = getOddballErps();
%     
    %%
    
    p3CutsDataset = dataset( isNarrow, isSlow, isGap, ErpsTarget, ErpsNonTarget, titleStrList);
    [dum IX] = sort(p3CutsDataset.isGap);
    p3CutsDataset = p3CutsDataset(IX, :);
    [dum IX] = sort(p3CutsDataset.isSlow);
    p3CutsDataset = p3CutsDataset(IX, :);
    [dum IX] = sort(p3CutsDataset.isNarrow);
    p3CutsDataset = p3CutsDataset(IX, :);
    
%     plotERPsFromCutData2( ...
%         [p3CutsDataset.ErpsTarget' p3CutsDataset.ErpsNonTarget' rareErps freqErps], ...
%         'samplingRate', fs, ...
%         'chanLabels', chanList, ...
%         'timeBeforeOnset', tBeforeOnset, ...
%         'nMaxChanPerAx', 12, ...
%         'axisOfEvent', [1:nCond 1:nCond nCond+1 nCond+1], ...
%         'legendStr',  {'target', 'nonTarget'}, ...
%         'scale', 8, ...
%         'axisTitles', [p3CutsDataset.titleStrList ; 'oddball']...
%         );
    
    plotERPsFromCutData2( ...
        [p3CutsDataset.ErpsTarget' p3CutsDataset.ErpsNonTarget'], ...
        'samplingRate', fs, ...
        'chanLabels', chanList, ...
        'timeBeforeOnset', tBeforeOnset, ...
        'nMaxChanPerAx', 12, ...
        'axisOfEvent', [1:nCond 1:nCond], ...
        'legendStr',  {'target', 'nonTarget'}, ...
        'scale', 12, ...
        'axisTitles', [p3CutsDataset.titleStrList]...
        );
    
    s.Format        = 'png';
    s.Resolution    = 300;
    set(findobj(gcf,'Type','uicontrol'),'Visible','off');
    % figName = strrep(titleStr, ' ', '-');
    figName = fullfile( dataDir, sessionName, 'pixAllErps' );
    hgexport(gcf, [figName '.png'], s);
    
    
    %%
    
%     function [rareErps freqErps] = getOddballErps()
% 
%         scenario        = xml2mat( fullfile(dataDir2, sessionName, scenarioFileName) );
%         hdr             = sopen( fullfile(dataDir2, sessionName, bdfFileName) );
%         [sig hdr]       = sread(hdr);
%         statusChannel   = bitand(hdr.BDF.ANNONS, 255);
%         hdr.BDF         = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
%         if ~exist('fs', 'var')
%             fs = hdr.SampleRate;
%         elseif hdr.SampleRate ~= fs
%             error('inconsistent sampling rate');
%         end
%         
%         fullChanList    = hdr.Label;
%         fullChanList(strcmp(fullChanList, 'Status')) = [];
%         discardChanInd  = cell2mat( cellfun( @(x) find(strcmp(fullChanList, x)), discardChanNames, 'UniformOutput', false ) );
%         fullChanList(discardChanInd) = [];
%         refChanInd      = cell2mat( cellfun( @(x) find(strcmp(fullChanList, x)), refChanNames, 'UniformOutput', false ) );
%         chanListInd     = cell2mat( cellfun( @(x) find(strcmp(fullChanList, x)), chanList, 'UniformOutput', false ) );
%         
%         [filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fs/2));
%         
%         nl      	= round(tBeforeOnset*fs);
%         nh          = round(tAfterOnset*fs);
%         range       = nh+nl+1;
%         
%         %%
%         
%         sig(:, discardChanInd)  = [];
%         sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
%         sig = sig(:, chanListInd);
%         for i = 1:size(sig, 2)
%             sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
%         end
%         
%         %%
%         
%         onsetEventInd   = cellfun( @(x) strcmp(x, 'rare on'), {scenario.events(:).desc} );
%         onsetEventValue = scenario.events( onsetEventInd ).id;
%         rareEventChan   = logical( bitand( statusChannel, onsetEventValue ) );
%         
%         onsetEventInd   = cellfun( @(x) strcmp(x, 'frequent on'), {scenario.events(:).desc} );
%         onsetEventValue = scenario.events( onsetEventInd ).id;
%         freqEventChan   = logical( bitand( statusChannel, onsetEventValue ) );
%     
%         %%
%         
%         rareOnsets = find( diff( rareEventChan ) == 1 ) + 1;
%         freqOnsets = find( diff( freqEventChan ) == 1 ) + 1;
%         
%         rareErps = zeros(range, nChan);
%         for iE = 1:numel(rareOnsets)
%             rareErps = rareErps + sig( (rareOnsets(iE)-nl) : (rareOnsets(iE)+nh), : );
%         end
%         rareErps = rareErps/numel(rareOnsets);
%         
%         freqErps = zeros(range, nChan);
%         for iE = 1:numel(freqOnsets)
%             freqErps = freqErps + sig( (freqOnsets(iE)-nl) : (freqOnsets(iE)+nh), : );
%         end
%         freqErps = freqErps/numel(freqOnsets);
%     
%     end
    
    
    
    %%
    
    function [sl, gp, nr, evt, evnt, titleStr] = getFromData()
                
        %%
        
        expParams       = load( fullfile(dataDir, sessionName, paramFileName) );
        scenario        = xml2mat( fullfile(dataDir, sessionName, scenarioFileName) );
        
        sl = strcmp(expParams.fastOrSlow, 'slow');
        gp = strcmp(expParams.gapOrNoGap, 'gap');
        nr = strcmp(expParams.narrowOrSpread, 'narrow');
        
        if sl, titleStr = 'slow'; else titleStr = 'fast'; end
        if gp, titleStr = [titleStr '-gap']; else titleStr = [titleStr '-noGap']; end
        if nr, titleStr = [titleStr '-narrow']; else titleStr = [titleStr '-spread']; end
        
        %%
        
        hdr             = sopen( fullfile(dataDir, sessionName, bdfFileName) );
        [sig hdr]       = sread(hdr);
        statusChannel   = bitand(hdr.BDF.ANNONS, 255);
        hdr.BDF         = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
        if ~exist('fs', 'var')
            fs = hdr.SampleRate;
        elseif hdr.SampleRate ~= fs
            error('inconsistent sampling rate');
        end
        
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
    
end

