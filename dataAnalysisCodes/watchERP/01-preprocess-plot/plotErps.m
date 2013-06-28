function plotErps

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
        dataDir     = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP\01-preprocess-plot\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir     = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        resultsDir  = 'd:\Adrien\Work\Hybrid-BCI\HybBciResults\watchERP\01-preprocess-plot\';
    otherwise,
        error('host not recognized');
end

% ========================================================================================================
% ========================================================================================================

% [~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
% resultsDir          = fullfile( resultsDir, folderName );
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

load(fullfile(resultsDir, 'meanErpDataset.mat'))

% ========================================================================================================
% ========================================================================================================

sub             = unique(meanErpDataset.subject);
cond            = {'oddball', 'hybrid-8-57Hz', 'hybrid-10Hz', 'hybrid-12Hz', 'hybrid-15Hz'};
tBeforeOnset    = unique(meanErpDataset.tBeforeOnset);
nSubjects       = numel(sub);
nCond           = numel(cond);
nErpType        = numel(unique(meanErpDataset.type));

chanListMini{1} = {'P3', 'Pz', 'P4'};
chanListMini{2} = {'C3', 'Cz', 'C4'};
chanListMini{3} = {'Fz', 'Cz', 'Pz', 'Oz'};

chanListReduced = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};

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

%========================================================================================================
%========================================================================================================
%% PLOT FOR EACH SUBJECT: TARGET VS. NON-TARGET, ONE CONDITION PER AXE, ALL CHANNELS
%========================================================================================================
%========================================================================================================
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

    figName = fullfile(resultsDir, [sprintf('allChan_subject%s', sub{iS}) '.png']);
    fixAndSaveFigure;
    
end

%========================================================================================================
%========================================================================================================
%% GRAND AVERAGE: TARGET VS. NON-TARGET, ONE CONDITION PER AXE, ALL CHANNELS
%========================================================================================================
%========================================================================================================
avg = cell(1, nCond*nErpType);
axisOfEvent = zeros(1, nCond*nErpType);
legendStr = {'target', 'nonTarget'};
axisTitle = cell(1, nCond);
ind = 1;
for iC = 1:nCond
    
    temp = meanErpDataset( ...
        ismember( meanErpDataset.condition, cond{iC} ) ...
        & ismember( meanErpDataset.type, legendStr{1} ) ...
        , : );
    
    chanListInd = cell2mat( cellfun( @(x) find(strcmp(temp.chanList{:}, x)), chanList, 'UniformOutput', false ) );
    avg{ind}            = temp.meanERP{1}(:, chanListInd);
    axisOfEvent(ind)    = iC;
    
    temp = meanErpDataset( ...
        ismember( meanErpDataset.condition, cond{iC} ) ...
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
    'title', 'Grand average' ...
    );

figName = fullfile(resultsDir, 'allChan_grandMean.png');
fixAndSaveFigure;

%========================================================================================================
%========================================================================================================
%%  PLOT TARGET ERPs FOR ALL CONDITIONS ON THE SAME AXE, ONE SUBJECT PER AXE, REDUCED CHANNEL SET
%               ( can generate several figures depending on the number of subjects)
%========================================================================================================
%========================================================================================================
allFs = unique( meanErpDataset.fs );
if numel(allFs) ~= 1
    minFs = min(allFs);
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


nMaxSubjecPerAx = 4;
nFigs = 1;
subjectList{1} = 1:nSubjects;
if nSubjects > nMaxSubjecPerAx
    nFigs = ceil( nSubjects / nMaxSubjecPerAx );
    subjectList = cell(1, nFigs);
    indSubStart = 1;
    for iFig = 1:nFigs
        indSubEnd = min( indSubStart + nMaxSubjecPerAx - 1, nSubjects );
        subjectList{iFig} = indSubStart:indSubEnd;
        indSubStart = indSubEnd + 1;
    end
end

for iFig = 1:nFigs
    nSubsInFig  = numel( subjectList{iFig} );
    avg         = cell(1, nCond*nSubsInFig);
    axisOfEvent = zeros(1, nCond*nSubsInFig);
    legendStr   = cond;
    axisTitle   = sub( subjectList{iFig} );
    colors      = zeros(nCond*nSubsInFig, 3);
    ind = 1;
    for iS = 1:nSubsInFig
        for iC = 1:nCond
            temp = meanErpDataset( ...
                ismember( meanErpDataset.subject, axisTitle{iS} ) ...
                & ismember( meanErpDataset.condition, legendStr{iC} ) ...
                & ismember( meanErpDataset.type, 'target' ) ...
                , : );
            
            chanListInd = cell2mat( cellfun( @(x) find(strcmp(temp.chanList{:}, x)), chanListReduced, 'UniformOutput', false ) );
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
        'chanLabels', chanListReduced, ...
        'timeBeforeOnset', unique(tBeforeOnset), ...
        'nMaxChanPerAx', 12, ...
        'scale', 8, ...
        'EventColors', colors, ...
        'title', 'target ERPs' ...
        );
    
    figName = fullfile(resultsDir, sprintf('targetERPs_%d.png', iFig));
    fixAndSaveFigure;
end

%========================================================================================================
%========================================================================================================
%%  PLOT TARGET ERPs FOR ALL CONDITIONS ON THE SAME AXE, ONE SUBJECT PER AXE, MINIMAL CHANNEL SET
%========================================================================================================
%========================================================================================================

for iPlot = 3%1:numel( chanListMini )
    
    nChanMini   = numel(chanListMini{iPlot});
    avg         = cell(1, nCond*nChanMini);
    axisOfEvent = zeros(1, nCond*nChanMini);
    legendStr   = cond;
    axisTitle   = chanListMini{iPlot};
    colors      = zeros(nCond*nChanMini, 3);
    subjects    = unique(meanErpDataset.subject);
    nSub        = numel(subjects);
    ind = 1;
    for iCh = 1:nChanMini
        for iC = 1:nCond
            temp = meanErpDataset( ...
                ismember( meanErpDataset.condition, legendStr{iC} ) ...
                & ismember( meanErpDataset.type, 'target' ) ...
                , : );
            
            chanListInd         = ismember(chanList, chanListMini{iPlot}{iCh});
            avg{ind}            = cell2mat(  cellfun(@(x) x(:,chanListInd), temp.meanERP, 'UniformOutput', false)' );
            axisOfEvent(ind)    = iCh;
            colors(ind, :)      = colorList(iC, :);
            ind = ind+1;
        end
    end
    
    plotERPsFromCutData2( ...
        avg, ...
        'axisOfEvent', axisOfEvent, ...
        'axisTitle', axisTitle, ...
        'legendStr', legendStr, ...
        'samplingRate', unique( meanErpDataset.fs ), ...
        'chanLabels', subjects, ...
        'timeBeforeOnset', unique(tBeforeOnset), ...
        'nMaxChanPerAx', 12, ...
        'scale', 10, ...
        'EventColors', colors, ...
        'title', 'target ERPs' ...
        );
    
    figName = fullfile(resultsDir, sprintf('targetERPs-fewChannels%d.png', iPlot));
    fixAndSaveFigure;
    

end

%========================================================================================================
%========================================================================================================
%%  PLOT GRAND AVERAGE ERPs FOR ALL CONDITIONS ON THE SAME AXE, FULL CHANNEL SET
%========================================================================================================
%========================================================================================================
avg         = cell(1, nCond);
% legendStr   = unique(meanErpDataset.condition);
legendStr   = cond;
colors = zeros(nCond, 3);
ind = 1;
for iC = 1:nCond
    temp = meanErpDataset( ...
        ismember( meanErpDataset.condition, legendStr{iC} ) ...
        & ismember( meanErpDataset.type, 'target' ) ...
        , : );
    
    avg{ind}            = temp.meanERP{1};
    colors(ind, :) = colorList(iC, :);
    ind = ind+1;
end


plotERPsFromCutData2( ...
    avg, ...
    'axisOfEvent', ones(1, nCond), ...
    'legendStr', legendStr, ...
    'samplingRate', unique( meanErpDataset.fs ), ...
    'chanLabels', chanList, ...
    'timeBeforeOnset', unique(tBeforeOnset), ...
    'nMaxChanPerAx', 8, ...
    'scale', 8, ...
    'EventColors', colors, ...
    'title', 'target ERPs' ...
    );

figName = fullfile(resultsDir, 'targetERPs_grandMean.png');
fixAndSaveFigure;

%========================================================================================================
%========================================================================================================
%%  PLOT NON-TARGET ERPs FOR ALL CONDITIONS ON THE SAME AXE, ONE SUBJECT PER AXE, REDUCED CHANNEL SET
%========================================================================================================
%========================================================================================================
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
        
        chanListInd = cell2mat( cellfun( @(x) find(strcmp(temp.chanList{:}, x)), chanListReduced, 'UniformOutput', false ) );
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
    'chanLabels', chanListReduced, ...
    'timeBeforeOnset', unique(tBeforeOnset), ...
    'nMaxChanPerAx', 12, ...
    'scale', 8, ...
    'EventColors', colors, ...
    'title', 'non-target ERPs' ...
    );

figName = fullfile(resultsDir, 'nonTargetERPs.png');
fixAndSaveFigure;

%=================================================================================================================
%=================================================================================================================
%%  PLOT TARGET MINUS NON-TARGET ERPs FOR ALL CONDITIONS ON THE SAME AXE, ONE SUBJECT PER AXE, REDUCED CHANNEL SET
%=================================================================================================================
%=================================================================================================================
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

        chanListInd = cell2mat( cellfun( @(x) find(strcmp(temp.chanList{:}, x)), chanListReduced, 'UniformOutput', false ) );
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
    'chanLabels', chanListReduced, ...
    'timeBeforeOnset', unique(tBeforeOnset), ...
    'nMaxChanPerAx', 12, ...
    'scale', 8, ...
    'EventColors', colors, ...
    'title', 'non-target ERPs' ...
    );

figName = fullfile(resultsDir, 'TminusNTERPs.png');
fixAndSaveFigure;

%========================================================================================================
%========================================================================================================
%%                                        NESTED FUNCTION
%========================================================================================================
%========================================================================================================

% % % % % % % % % %     function fixAndSaveFigure
% % % % % % % % % %         
% % % % % % % % % %         h = ImageSetup;
% % % % % % % % % %         h.I_Width       = fWidth; % cm
% % % % % % % % % %         h.I_High        = fHeight; % cm
% % % % % % % % % %         h.I_KeepColor   = 1;
% % % % % % % % % %         h.I_Box         = 'off';
% % % % % % % % % %         h.I_FontSize    = FS;
% % % % % % % % % %         h.I_LineWidth   = LW;
% % % % % % % % % %         h.I_AlignAxesTexts = 0;
% % % % % % % % % %         h.I_TitleInAxis = 1;
% % % % % % % % % %         h.OptimizeSpace = 0;
% % % % % % % % % %         
% % % % % % % % % %         h.prepareAllFigures;
% % % % % % % % % %         
% % % % % % % % % %         % set(findobj('parent', gcf, 'tag', 'legend'), 'Box', 'off');
% % % % % % % % % %         set(findobj(gcf,'Type','uicontrol'),'Visible','off');
% % % % % % % % % %         
% % % % % % % % % %         s.Format = 'tiff';
% % % % % % % % % %         s.Resolution = h.I_DPI;
% % % % % % % % % %         hgexport(gcf, figName, s);
% % % % % % % % % %         
% % % % % % % % % %         close(gcf);
% % % % % % % % % %         
% % % % % % % % % %     end
% % % % % % % % % % 



end

