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
        dataDir     = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP_2stim\01-preprocess-plot\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir     = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resultsDir  = 'd:\Adrien\Work\Hybrid-BCI\HybBciResults\watchERP_2stim\01-preprocess-plot\';
    otherwise,
        error('host not recognized');
end

load(fullfile(resultsDir, 'meanErpDataset.mat'))

%% ========================================================================================================
% ========================================================================================================

sub             = unique(meanErpDataset.subject);
freq            = unique(meanErpDataset.frequency);
type            = unique(meanErpDataset.type);
tBeforeOnset    = unique(meanErpDataset.tBeforeOnset);
nSubjects       = numel(sub);
nFreq           = numel(freq);
nErpType        = numel(type);

chanListReduced = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};
chanListFull    = {...
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

%========================================================================================================
%========================================================================================================
%%                                        PER SUBJECT PLOTS
%========================================================================================================
%========================================================================================================
for iS = 6%1:nSubjects
    
    meanErpDataset_iS = meanErpDataset( ismember(meanErpDataset.subject, sub{iS}), : );    
    
    %====================================================================================================
    %% All in one
    %====================================================================================================
    avg = cell(1, nFreq*nErpType);
    legendStr = cell(1, nFreq*nErpType);
    ind = 1;
    for iF = 1:nFreq
        
        subDataset = meanErpDataset_iS( ismember(meanErpDataset_iS.frequency, freq(iF)), : );
        
        
        for iT = 1:nErpType
            
            temp = subDataset( ismember(subDataset.type, type(iT)), : );
            legendStr{ind} = sprintf('%s %dHz', type{iT}, freq(iF));

            nn      = temp.nEpochs(1);
            avg{ind} = temp.nEpochs(1)*temp.meanERP{1};
            for i=2:size(temp,1),
                avg{ind} = avg{ind} + temp.nEpochs(i)*temp.meanERP{i};
                nn = nn + temp.nEpochs(i);
            end
            avg{ind} = avg{ind} / nn;
            ind = ind + 1;
        end
        
    end
    
    fs = unique( meanErpDataset_iS.fs );
    if numel(fs) ~= 1, error('not all data were recorded with the same sampling rate for subject %s', sub{iS}); end
    
    plotERPsFromCutData2( ...
        avg, ...
        'axisOfEvent', ones(1, nFreq*nErpType), ...
        'legendStr', legendStr, ...
        'samplingRate', fs, ...
        'chanLabels', chanListFull, ...
        'timeBeforeOnset', tBeforeOnset, ...
        'nMaxChanPerAx', 8, ...
        'scale', 8, ...
        'title', sprintf('subject %s', sub{iS}) ...
        );
    
    figName = fullfile(resultsDir, [sprintf('erps_subject%s', sub{iS}) '.png']);
    fixAndSaveFigure;
    
    %====================================================================================================
    %% one plot for each run
    %====================================================================================================
    allRuns = unique( meanErpDataset_iS.run );
    if ~isequal( allRuns(:), (1:max(allRuns))' ), error('something wrong with the runs'); end
    
    for iRun = allRuns'
        
        meanErpDataset_iS_iR = meanErpDataset_iS( ismember(meanErpDataset_iS.run, iRun), : );
        
        avg = cell(1, nFreq*nErpType);
        legendStr = cell(1, nFreq*nErpType);
        ind = 1;
        for iF = 1:nFreq
            
            subDataset = meanErpDataset_iS_iR( ismember(meanErpDataset_iS_iR.frequency, freq(iF)), : );
            
            for iT = 1:nErpType
                
                temp = subDataset( ismember(subDataset.type, type(iT)), : );
                legendStr{ind} = sprintf('%s %dHz', type{iT}, freq(iF));
                
                nn      = temp.nEpochs(1);
                avg{ind} = temp.nEpochs(1)*temp.meanERP{1};
                for i=2:size(temp,1),
                    avg{ind} = avg{ind} + temp.nEpochs(i)*temp.meanERP{i};
                    nn = nn + temp.nEpochs(i);
                end
                avg{ind} = avg{ind} / nn;
                ind = ind + 1;
            end
            
        end
        
        plotERPsFromCutData2( ...
            avg, ...
            'axisOfEvent', ones(1, nFreq*nErpType), ...
            'legendStr', legendStr, ...
            'samplingRate', fs, ...
            'chanLabels', chanListFull, ...
            'timeBeforeOnset', tBeforeOnset, ...
            'nMaxChanPerAx', 8, ...
            'scale', 8, ...
            'title', sprintf('subject %s run %d', sub{iS}, iRun) ...
            );
        
        figDir = fullfile( resultsDir, sprintf('details_subject%s', sub{iS}) );
        if ~exist(figDir, 'dir'), mkdir(figDir); end
        figName = fullfile( figDir, [sprintf('erps_run%d', iRun) '.png'] );
        fixAndSaveFigure;
                
    end
    
end % OF SUBJECT LOOP


%========================================================================================================
%========================================================================================================
%%                                        NESTED FUNCTION
%========================================================================================================
%========================================================================================================

    function fixAndSaveFigure

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
        hgexport(gcf, figName, s);
        
        close(gcf); 
    
    end





end






