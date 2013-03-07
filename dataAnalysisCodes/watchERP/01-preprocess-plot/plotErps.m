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
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        %             dataDir2 = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\oddball\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        %             dataDir2= 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\oddball\';
    otherwise,
        error('host not recognized');
end

% ========================================================================================================
% ========================================================================================================

% TableName   = 'watchErpDataset.xlsx';
TableName   = 'watchErpDataset2.xlsx';
fileList    = dataset('XLSFile', TableName);

sub = unique( fileList.subjectTag );
cond = {'oddball', 'hybrid-8-57Hz', 'hybrid-10Hz', 'hybrid-12Hz', 'hybrid-15Hz'};
% cond = {'oddball', 'hybrid-12Hz', 'hybrid-15Hz'};
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

save('meanErpDataset2.mat', 'meanErpDataset');


%% ========================================================================================================
% =========================================================================================================

sub = unique(meanErpDataset.subject);
cond = {'oddball', 'hybrid-8-57Hz', 'hybrid-10Hz', 'hybrid-12Hz', 'hybrid-15Hz'};
% cond = {'oddball', 'hybrid-12Hz', 'hybrid-15Hz'};
tBeforeOnset = unique(meanErpDataset.tBeforeOnset);
nSubjects = numel(sub);
nCond = numel(cond);
nErpType = numel(unique(meanErpDataset.type));
% chanList = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};

chanList = {...
                 'Fp1',   'Fp2', ...               
               'AF3',       'AF4', ...
...              
      'F7',   'F3',   'Fz',   'F4',   'F8', ...
...     
        'FC5',   'FC1',   'FC2',   'FC6', ...
...        
    'T7',    'C3',    'Cz',    'C4',    'T8', ...
...    
        'CP5',   'CP1',   'CP2',   'CP6', ...
...
      'P7',   'P3',   'Pz',   'P4',   'P8', ...
...     
               'PO3',       'PO4', ...
                'O1', 'Oz', 'O2' ...
    };


LW = 2;
MS = 6;
FS = 9;
fWidth = 50;
fHeight = 31;

cmap = colormap; close(gcf);
nCmap = size(cmap, 1);
colorList = zeros(nCond, 3);
for i = 1:nCond
    colorList(i, :) = cmap( round((i-1)*(nCmap-1)/(nCond-1)+1) , : );
end
% colorList = [ ...    
%     0 0 1 ; ... % blue
%     1 0 0 ; ... % red
%     0 1 0 ;...  % green
%     1 1 0 ; ... % yellow
%     1 0 1 ...   % magenta
%     ];

%% ========================================================================================================
%  PLOT FOR EACH SUBJECT: TARGET VS. NON-TARGET, ONE CONDITION PER AXE
% =========================================================================================================
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
        'nMaxChanPerAx', 32, ...
        'scale', 8, ...
        'title', sprintf('subject %s', sub{iS}) ...
        );
    
    
    h = ImageSetup;
    h.I_Width       = fWidth; % cm
    h.I_High        = fHeight; % cm
    h.I_KeepColor   = 1;
    h.I_Box         = 'off';
    h.I_FontSize    = FS;
    h.I_LineWidth   = LW;
    h.I_AlignAxesTexts = 0;
    h.I_TitleInAxis = 1;
    h.OptimizeSpace = 0;
    
    h.prepareAllFigures;
    
    % set(findobj('parent', gcf, 'tag', 'legend'), 'Box', 'off');
    set(findobj(gcf,'Type','uicontrol'),'Visible','off');
    
    s.Format = 'tiff';
    s.Resolution = h.I_DPI;
    hgexport(gcf,fullfile(cd, [sprintf('allChan_subject%s', sub{iS}) '.png']),s);
    
    close(gcf);
    
    
end

%% ========================================================================================================
%  PLOT TARGET ERPs FOR ALL CONDITIONS ON THE SAME AXE, ONE SUBJECT PER AXE
% =========================================================================================================

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
colors = zeros(nCond*nSubjects, 3);
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
        colors(ind, :) = colorList(iC, :);
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
    'EventColors', colors, ...
    'title', 'target ERPs' ...
    );

h = ImageSetup;
h.I_Width       = fWidth; % cm
h.I_High        = fHeight; % cm
h.I_DPI         = 300;
h.I_KeepColor   = 1;
h.I_Box         = 'off';
h.I_Grid        = 'on';
h.I_FontSize    = FS;
h.I_LineWidth   = LW;
h.I_AlignAxesTexts = 0;
h.I_TitleInAxis = 1;
h.OptimizeSpace = 0;

h.prepareAllFigures;

set(findobj('parent', gcf, 'tag', 'legend'), 'Location', 'NorthWest');
set(findobj(gcf,'Type','uicontrol'),'Visible','off');

s.Format = 'tiff';
s.Resolution = h.I_DPI;
hgexport(gcf,fullfile(cd, 'targetERPs.png'),s);

close(gcf);


%% ========================================================================================================
%  PLOT NON-TARGET ERPs FOR ALL CONDITIONS ON THE SAME AXE, ONE SUBJECT PER AXE
% =========================================================================================================
chanList = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};

avg         = cell(1, nCond*nSubjects);
axisOfEvent = zeros(1, nCond*nSubjects);
% legendStr   = unique(meanErpDataset.condition);
legendStr   = cond;
axisTitle   = unique(meanErpDataset.subject);
colors = zeros(nCond*nSubjects, 3);
ind = 1;
for iS = 1:nSubjects
    for iC = 1:nCond
        temp = meanErpDataset( ...
            ismember( meanErpDataset.subject, axisTitle{iS} ) ...
            & ismember( meanErpDataset.condition, legendStr{iC} ) ...
            & ismember( meanErpDataset.type, 'nonTarget' ) ...
            , : );
        
        chanListInd = cell2mat( cellfun( @(x) find(strcmp(temp.chanList{:}, x)), chanList, 'UniformOutput', false ) );
        avg{ind}            = temp.meanERP{1}(:, chanListInd);
        axisOfEvent(ind)    = iS;
        colors(ind, :) = colorList(iC, :);
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
    'EventColors', colors, ...
    'title', 'non-target ERPs' ...
    );

h = ImageSetup;
h.I_Width       = fWidth; % cm
h.I_High        = fHeight; % cm
h.I_DPI         = 300;
h.I_KeepColor   = 1;
h.I_Box         = 'off';
h.I_Grid        = 'on';
h.I_FontSize    = FS;
h.I_LineWidth   = LW;
h.I_AlignAxesTexts = 0;
h.I_TitleInAxis = 1;
h.OptimizeSpace = 0;

h.prepareAllFigures;

set(findobj('parent', gcf, 'tag', 'legend'), 'Location', 'NorthWest');
set(findobj(gcf,'Type','uicontrol'),'Visible','off');

s.Format = 'tiff';
s.Resolution = h.I_DPI;
hgexport(gcf,fullfile(cd, 'nonTargetERPs.png'),s);

close(gcf);

%% ========================================================================================================
%  PLOT TARGET MINUS NON-TARGET ERPs FOR ALL CONDITIONS ON THE SAME AXE, ONE SUBJECT PER AXE
% =========================================================================================================
chanList = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};

avg         = cell(1, nCond*nSubjects);
axisOfEvent = zeros(1, nCond*nSubjects);
% legendStr   = unique(meanErpDataset.condition);
legendStr   = cond;
axisTitle   = unique(meanErpDataset.subject);
colors = zeros(nCond*nSubjects, 3);
ind = 1;
for iS = 1:nSubjects
    for iC = 1:nCond
        temp = meanErpDataset( ...
            ismember( meanErpDataset.subject, axisTitle{iS} ) ...
            & ismember( meanErpDataset.condition, legendStr{iC} ) ...
            & ismember( meanErpDataset.type, 'target' ) ...
            , : );
        
        temp2 = meanErpDataset( ...
            ismember( meanErpDataset.subject, axisTitle{iS} ) ...
            & ismember( meanErpDataset.condition, legendStr{iC} ) ...
            & ismember( meanErpDataset.type, 'nonTarget' ) ...
            , : );

        chanListInd = cell2mat( cellfun( @(x) find(strcmp(temp.chanList{:}, x)), chanList, 'UniformOutput', false ) );
        avg{ind}            = temp.meanERP{1}(:, chanListInd) - temp2.meanERP{1}(:, chanListInd);
        axisOfEvent(ind)    = iS;
        colors(ind, :) = colorList(iC, :);
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
    'EventColors', colors, ...
    'title', 'non-target ERPs' ...
    );

h = ImageSetup;
h.I_Width       = fWidth; % cm
h.I_High        = fHeight; % cm
h.I_DPI         = 300;
h.I_KeepColor   = 1;
h.I_Box         = 'off';
h.I_Grid        = 'on';
h.I_FontSize    = FS;
h.I_LineWidth   = LW;
h.I_AlignAxesTexts = 0;
h.I_TitleInAxis = 1;
h.OptimizeSpace = 0;

h.prepareAllFigures;

set(findobj('parent', gcf, 'tag', 'legend'), 'Location', 'NorthWest');
set(findobj(gcf,'Type','uicontrol'),'Visible','off');

s.Format = 'tiff';
s.Resolution = h.I_DPI;
hgexport(gcf,fullfile(cd, 'TminusNTERPs.png'),s);

close(gcf);

