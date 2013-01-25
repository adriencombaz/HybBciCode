% function createErpDataset

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
%             dataDir2 = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciData\oddball\';
        case 'neu-wrk-0158',
            addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
            dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciData\watchERP\';
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
    
    tBeforeOnset    = 0.2; % lower time range in secs
    tAfterOnset     = 0.8; % upper time range in secs

    %%
    TableName   = 'watchErpDataset.xlsx';
    fileList    = dataset('XLSFile', TableName);
    
    subjects = unique( fileList.subjectTag );
    conditions = {'oddball', 'hybrid-12Hz', 'hybrid-15Hz'};
    
    for iS = 1:numel(subjects) 
        subset = fileList( ismember( fileList.subjectTag, subjects{iS} ), : );
        for iC = 1:numel(conditions)
            
            subset = subset( ismember( subset.condition, conditions{iC} ), : );
            
            for iR = 1:numel(subset)
               
                dataRun = subset(iR,:);
                
                hdr = sopen( ...
                    fullfile( ...
                    dataDir, ...
                    dataRun.sessionDirectory{1}, ...
                    [dataRun.fileName{1} '-' dataRun.condition{1} '.bdf']) );
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

            end
            
        end
    end
    
% end