function plotErps2

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
        resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP\01-preprocess-plot\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        resultsDir  = 'd:\Adrien\Work\Hybrid-BCI\HybBciResults\watchERP\01-preprocess-plot\';
    otherwise,
        error('host not recognized');
end
figDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\draftHybridPaper\matlab\';

% ========================================================================================================
% ========================================================================================================

% [~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
% resultsDir          = fullfile( resultsDir, folderName );
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

load(fullfile(resultsDir, 'meanErpDataset.mat'))
meanErpDataset(ismember(meanErpDataset.subject, 'S08'), :) = [];
meanErpDataset.subject(ismember(meanErpDataset.subject, 'S09'), :) = {'S08'};
meanErpDataset.subject(ismember(meanErpDataset.subject, 'S10'), :) = {'S09'};
% ========================================================================================================
% ========================================================================================================

sub             = unique(meanErpDataset.subject);
cond            = {'oddball', 'hybrid-8-57Hz', 'hybrid-10Hz', 'hybrid-12Hz', 'hybrid-15Hz'};
tBeforeOnset    = unique(meanErpDataset.tBeforeOnset);
nSubjects       = numel(sub);
nCond           = numel(cond);
nErpType        = numel(unique(meanErpDataset.type));

chanListReduced = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};

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


nMaxSubjecPerAx = 5;
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
    
    figName = fullfile(figDir, sprintf('targetERPs_%d.png', iFig));
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
    
    legObj = findobj('parent', gcf, 'tag', 'legend');
    legUnits = get(legObj, 'Units');
    set(legObj, 'Units', 'centimeters');
    legPos = get(legObj, 'Position');
    legPosNew = legPos;
    legPosNew(1) = fWidth - legPos(3) - 1;
    legPosNew(2) = fHeight - legPos(4) - 1;
    set(legObj, 'Position', legPosNew);
    set(legObj, 'Units', legUnits);
    
    
    set(findobj(gcf,'Type','uicontrol'),'Visible','off');
    
    s.Format = 'png';
    s.Resolution = h.I_DPI;
    hgexport(gcf, figName, s);
    
    close(gcf);
end




end

