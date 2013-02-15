% cl;
clear;clc
%% ========================================================================================================
% =========================================================================================================

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

% ========================================================================================================
% ========================================================================================================

TableName   = 'watchErpDataset.xlsx';
fileList    = dataset('XLSFile', TableName);

sub = unique( fileList.subjectTag );
cond = {'oddball', 'hybrid-12Hz', 'hybrid-15Hz'};
nSubjects = numel(sub);
nCond = numel(cond);
nErpType = 2; % target and non-target ERPs
nData = nSubjects*nCond*nErpType; 

subject     = cell( nData, 1 );
condition   = cell( nData, 1 );
type        = cell( nData, 1 );
meanERP     = cell( nData, 1 );
fs          = zeros( nData, 1 );
nEpochs     = zeros( nData, 1 );
chanList    = cell( nData, 1 );
tBeforeOnset    = 0.2; % lower time range in secs
tAfterOnset     = 0.8; % upper time range in secs

iData = 1;
for iS = 1:nSubjects,
    
    for iC = 1:nCond,
       
        subset = fileList( ismember( fileList.subjectTag, sub{iS} ) & ismember( fileList.condition, cond{iC} ), : );
        if ~isequal(subset.run', 1:size(subset, 1))
            error('inconsistency between amount of runs and their numbering');
        end
        
        %--------------------------------------------------------------------------------------------
        for iR = 1:size(subset, 1)
            
            fprintf('\nsubject %s (%d out of %d), condition %s (%d out of %d), run %d out of %d\n', ...
                sub{iS}, iS, nSubjects, cond{iC}, iC, nCond, iR, size(subset, 1) );
            
            sessionDir  = fullfile(dataDir, subset.sessionDirectory{iR});
            filename    = ls(fullfile(sessionDir, [subset.fileName{iR} '*.bdf']));
            erpData     = eegDataset( sessionDir, filename );
            erpData.tBeforeOnset = tBeforeOnset;
            erpData.tAfterOnset = tAfterOnset;
            
            if iR == 1
                samplingRate    = erpData.fs;
                channels        = erpData.chanList( erpData.eegChanInd );
                eventLabels     = erpData.eventLabel;
                if numel( eventLabels ) ~= nErpType, error('was expecting %d event types (target/non-target)', nErpType); end
                
            else
                if erpData.fs ~= samplingRate
                    error('runs were not recorded with the same sampling rate!!');
                end
                if ~isequal( channels, erpData.chanList( erpData.eegChanInd ))
                    error('runs have different channels');
                end
                if ~isequal(eventLabels, erpData.eventLabel)
                    error('runs have different event labels');
                end
                
            end
            
            erpData.butterFilter(1, 30, 3);
            erpData.markEpochsForRejection('minMax', 'proportion', .15);
%             erpData.markEpochsForRejection('minMax', 'threshold', 60);
            if iR == 1
                [sumCut nCuts] = erpData.getSumCut();
                
            else
                [sumCutTemp nCutsTemp] = erpData.getSumCut();
                for i = 1:numel(eventLabels)
                    sumCut{i}   = sumCut{i} + sumCutTemp{i};
                    nCuts{i}    = nCuts{i} + nCutsTemp{i};
                end
                
            end
        end
        
        %--------------------------------------------------------------------------------------------
        meanERP{iData}      = sumCut{1}(:, erpData.eegChanInd ) / nCuts{1};
        meanERP{iData+1}    = sumCut{2}(:, erpData.eegChanInd ) / nCuts{2};
        nEpochs(iData)      = nCuts{1};
        nEpochs(iData+1)    = nCuts{2};
        fs(iData)           = samplingRate;
        fs(iData+1)         = samplingRate;
        chanList{iData}     = channels;
        chanList{iData+1}   = channels;
        subject{iData}      = sub{iS};
        subject{iData+1}    = sub{iS};
        condition{iData}    = cond{iC};
        condition{iData+1}  = cond{iC};
        type{iData}         = eventLabels{1};
        type{iData+1}       = eventLabels{2};
        
        iData = iData+2;
        
    end
    
end

tBeforeOnset    = repmat( tBeforeOnset, nData, 1 );
tAfterOnset     = repmat( tAfterOnset, nData, 1 );


meanErpDataset = dataset( ...
    subject, ...
    condition, ...
    type, ...
    nEpochs, ...
    meanERP, ...
    chanList, ...
    tBeforeOnset, ...
    tAfterOnset, ...
    fs ...
    );

save('meanErpDataset.mat', 'meanErpDataset');


%%

chanList = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};

for iS = 1:nSubjects
    
    avg = cell(1, nCond*nErpType);
    axisOfEvent = zeros(1, nCond*nErpType);
    legendStr = {'target', 'nonTarget'};
    axisTitle = cell(1, nCond);
    ind = 1;
    for iC = 1:nCond
               
        temp = meanErpDataset( ...
            ismember( meanErpDataset.subject, sub{iS} ) ...
            & ismember( meanErpDataset.condition, cond{iC} ) ...
            & ismember( meanErpDataset.type, legendStr{1} ) ...
            , : );
        
        chanListInd = cell2mat( cellfun( @(x) find(strcmp(temp.chanList{:}, x)), chanList, 'UniformOutput', false ) );        
        avg{ind}            = temp.meanERP{1}(:, chanListInd);
        axisOfEvent(ind)    = iC;
        
        temp = meanErpDataset( ...
            ismember( meanErpDataset.subject, sub{iS} ) ...
            & ismember( meanErpDataset.condition, cond{iC} ) ...
            & ismember( meanErpDataset.type, legendStr{2} ) ...
            , : );
        chanListInd = cell2mat( cellfun( @(x) find(strcmp(temp.chanList{:}, x)), chanList, 'UniformOutput', false ) );
        avg{ind+1}          = temp.meanERP{1}(:, chanListInd);
        axisOfEvent(ind+1)  = iC;

        axisTitle{iC} = cond{iC};
       
        ind = ind+2;
        
    end
    
    fs = unique( meanErpDataset.fs( ismember( meanErpDataset.subject, sub{iS} ) ) );
    if numel(fs) ~= 1, error('not all data were recorded with the same sampling rate for subject %s', subject{iS}); end
    
    plotERPsFromCutData2( ...
        avg, ...
        'axisOfEvent', axisOfEvent, ...
        'axisTitle', axisTitle, ...
        'legendStr', legendStr, ...
        'samplingRate', fs, ...
        'chanLabels', chanList, ...
        'timeBeforeOnset', unique(tBeforeOnset), ...
        'nMaxChanPerAx', 12, ...
        'scale', 8, ...
        'title', sprintf('subject %s', sub{iS}) ...
        );
    
end

%%

% % % % for iS = 1:nSubjects
% % % %    
% % % %     temp = meanErpDataset( ...
% % % %         ismember( meanErpDataset.subject, sub{iS} ) ...
% % % %         & ismember( meanErpDataset.type, 'target' ) ...
% % % %         , : );
% % % %     
% % % %     avg = temp.meanERP;
% % % %     legendStr = temp.condition;
% % % % 
% % % %     
% % % %     plotERPsFromCutData2( ...
% % % %         avg, ...
% % % %         'legendStr', legendStr, ...
% % % %         'axisOfEvent', [1 1 1], ...
% % % %         'samplingRate', unique(temp.fs), ...
% % % %         'chanLabels', temp.chanList{1}, ...
% % % %         'timeBeforeOnset', unique(temp.tBeforeOnset), ...
% % % %         'nMaxChanPerAx', 10, ...
% % % %         'scale', 8, ...
% % % %         'title', sprintf('subject %s', sub{iS}) ...
% % % %         );
% % % %     
% % % %     
% % % %     
% % % % end

%%

allFs = unique( meanErpDataset.fs );
if numel(allFs) ~= 1
    minFs = min(allFs);
    ii = find( meanErpDataset.fs == minFs, 1, 'first' );
    nTimePoints = size( meanErpDataset.meanERP{ii}, 1);
    
    for iD = 1:size(meanErpDataset, 1)
        if meanErpDataset.fs(iD) ~= minFs
            
            step = meanErpDataset.fs(iD) / minFs;
            if step == round(step)
                meanErpDataset.meanERP{iD} = meanErpDataset.meanERP{iD}(1:step:end, :);
                meanErpDataset.fs(iD) = minFs;
            else
                error('subsampling step is not a natural number');
            end
        
        end
    end    
end

chanList = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};

avg         = cell(1, nCond*nSubjects);
axisOfEvent = zeros(1, nCond*nSubjects);
% legendStr   = unique(meanErpDataset.condition);
legendStr   = cond;
axisTitle   = unique(meanErpDataset.subject);
ind = 1;
for iS = 1:nSubjects
    for iC = 1:nCond
        temp = meanErpDataset( ...
            ismember( meanErpDataset.subject, axisTitle{iS} ) ...
            & ismember( meanErpDataset.condition, legendStr{iC} ) ...
            & ismember( meanErpDataset.type, 'target' ) ...
            , : );
        
        chanListInd = cell2mat( cellfun( @(x) find(strcmp(temp.chanList{:}, x)), chanList, 'UniformOutput', false ) );
        avg{ind}            = temp.meanERP{1}(:, chanListInd);
        axisOfEvent(ind)    = iS;
        ind = ind+1;
    end
end

plotERPsFromCutData2( ...
    avg, ...
    'axisOfEvent', axisOfEvent, ...
    'axisTitle', axisTitle, ...
    'legendStr', legendStr, ...
    'samplingRate', unique( meanErpDataset.fs ), ...
    'chanLabels', chanList, ...
    'timeBeforeOnset', unique(tBeforeOnset), ...
    'nMaxChanPerAx', 12, ...
    'scale', 8, ...
    'title', 'target ERPs' ...
    );

%%
% % % chanList = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};
% % % 
% % % avg         = cell(1, nCond*nSubjects);
% % % axisOfEvent = zeros(1, nCond*nSubjects);
% % % % legendStr   = unique(meanErpDataset.condition);
% % % legendStr   = cond;
% % % axisTitle   = unique(meanErpDataset.subject);
% % % ind = 1;
% % % for iS = 1:nSubjects
% % %     for iC = 1:nCond
% % %         temp = meanErpDataset( ...
% % %             ismember( meanErpDataset.subject, axisTitle{iS} ) ...
% % %             & ismember( meanErpDataset.condition, legendStr{iC} ) ...
% % %             & ismember( meanErpDataset.type, 'nonTarget' ) ...
% % %             , : );
% % %         
% % %         chanListInd = cell2mat( cellfun( @(x) find(strcmp(temp.chanList{:}, x)), chanList, 'UniformOutput', false ) );
% % %         avg{ind}            = temp.meanERP{1}(:, chanListInd);
% % %         axisOfEvent(ind)    = iS;
% % %         ind = ind+1;
% % %     end
% % % end
% % % 
% % % plotERPsFromCutData2( ...
% % %     avg, ...
% % %     'axisOfEvent', axisOfEvent, ...
% % %     'axisTitle', axisTitle, ...
% % %     'legendStr', legendStr, ...
% % %     'samplingRate', unique( meanErpDataset.fs ), ...
% % %     'chanLabels', chanList, ...
% % %     'timeBeforeOnset', unique(tBeforeOnset), ...
% % %     'nMaxChanPerAx', 12, ...
% % %     'scale', 8, ...
% % %     'title', 'non-target ERPs' ...
% % %     );
