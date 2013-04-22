function plotErps_runDetails_perSubject( iS )

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
cond = unique( fileList.condition );
nCond = numel(cond);
nErpType = 2; % target and non-target ERPs

chanListToPlot = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};


outputPath = fullfile( fileparts(mfilename('fullpath')), 'detailsPerRun' );
if ~exist(outputPath, 'dir'), mkdir(outputPath); end
tBeforeOnset    = 0.2; % lower time range in secs
tAfterOnset     = 0.8; % upper time range in secs
LW = 2;
MS = 6;
FS = 9;
fWidth = 50;
fHeight = 31;


for iC = 1:nCond,
    
    subset = fileList( ismember( fileList.subjectTag, sub{iS} ) & ismember( fileList.condition, cond{iC} ), : );
    if ~isequal(subset.run', 1:size(subset, 1))
        error('inconsistency between amount of runs and their numbering');
    end
    
    erps        = cell( 1, (size(subset, 1) + 1)*nErpType );
    axisOfEvent = zeros( 1, (size(subset, 1) + 1)*nErpType );
    axisTitle   = cell(1, (size(subset, 1) + 1));

    %--------------------------------------------------------------------------------------------
    for iR = 1:size(subset, 1)
        
        fprintf('\nsubject %s, condition %s (%d out of %d), run %d out of %d\n', ...
            sub{iS}, cond{iC}, iC, nCond, iR, size(subset, 1) );
        
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
%         erpData.markEpochsForRejection('minMax', 'proportion', .15);
    
        [sumCutTemp nCutsTemp] = erpData.getSumCut();
        if iR == 1
            sumCut  = sumCutTemp;
            nCuts   = nCutsTemp;
        else
            for i = 1:numel(eventLabels)
                sumCut{i}   = sumCut{i} + sumCutTemp{i};
                nCuts{i}    = nCuts{i} + nCutsTemp{i};
            end
        end
        
        chanListInd = cell2mat( cellfun( @(x) find(strcmp(erpData.chanList, x)), chanListToPlot, 'UniformOutput', false ) );
        for i = 1:nErpType
            erps{ (iR-1)*nErpType+i } = sumCutTemp{i}(:, chanListInd) / nCutsTemp{i};
            axisOfEvent( (iR-1)*nErpType+i ) = iR;
        end
        axisTitle{iR} = sprintf('run %d', subset.run(iR));
        
    end
    
    for i = 1:nErpType
        erps{ (size(subset, 1))*nErpType+i } = sumCut{i}(:, chanListInd) / nCuts{i};
        axisOfEvent( (size(subset, 1))*nErpType+i ) = size(subset, 1)+1;
    end
    axisTitle{size(subset, 1)+1} = 'All runs';
    
    legendStr = erpData.eventLabel;
        
    plotERPsFromCutData2( ...
        erps, ...
        'axisOfEvent', axisOfEvent, ...
        'axisTitle', axisTitle, ...
        'legendStr', legendStr, ...
        'samplingRate', samplingRate, ...
        'chanLabels', chanListToPlot, ...
        'timeBeforeOnset', unique(tBeforeOnset), ...
        'nMaxChanPerAx', 32, ...
        'scale', 8, ...
        'title', sprintf('condition %s', cond{iC}) ...
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
    
    set(findobj('parent', gcf, 'tag', 'legend'), 'Location', 'Best');
    set(findobj(gcf,'Type','uicontrol'),'Visible','off');
    
    s.Format = 'tiff';
    s.Resolution = h.I_DPI;
%     hgexport(gcf,fullfile(outputPath, sprintf('%s_%s.png', sub{iS}, cond{iC})),s);
    hgexport(gcf,fullfile(outputPath, sprintf('%s_noRejection_%s.png', sub{iS}, cond{iC})),s);
    
    close(gcf);
    
end

