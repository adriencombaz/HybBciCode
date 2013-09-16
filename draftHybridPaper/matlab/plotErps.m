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
        resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP\01-preprocess-plot\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
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



chanListMini = {'Fz', 'Cz', 'Pz'};
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


nChanMini   = numel(chanListMini);
avg         = cell(1, nCond*nChanMini);
axisOfEvent = zeros(1, nCond*nChanMini);
legendStr   = cond;
axisTitle   = chanListMini;
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
        
        chanListInd         = ismember(chanList, chanListMini{iCh});
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

figDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\draftHybridPaper\matlab\';
figName = fullfile(figDir, 'targetERPs.png');

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

s.Format = 'tiff';
s.Resolution = h.I_DPI;
hgexport(gcf, figName, s);

close(gcf);


end

