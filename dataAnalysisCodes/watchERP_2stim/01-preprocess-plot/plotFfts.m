function plotFfts()

%% ==================================================================================================
%====================================================================================================

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
        resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP_2stim\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir     = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resultsDir  = 'd:\Adrien\Work\Hybrid-BCI\HybBciResults\watchERP_2stim\';
    otherwise,
        error('host not recognized');
end

%% ==================================================================================================
%====================================================================================================

TableName   = 'watchErpDataset.xlsx';
fileList    = dataset('XLSFile', TableName);

[~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
resultsDir          = fullfile( resultsDir, folderName );
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end


sub         = unique( fileList.subjectTag );
nSubs       = numel(sub);

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


for iS = 8%1:nSubs

    load( fullfile( resultsDir, sprintf('fftDataset_sub%s.mat', sub{iS}) ) )
    
    time = max( fftDataset.timeInSec );
    frequencies = unique(fftDataset.frequency);
    % One plot per frequency
    for iF = 1:numel(frequencies)
    
        subDataset = fftDataset( ismember(fftDataset.timeInSec, time) & ismember(fftDataset.frequency, frequencies(iF)), : );
        
        %====================================================================================================
        %====================================================================================================
        %%                                 MEAN PER SUBJECT
        %====================================================================================================
        %====================================================================================================
        
        
        %--------------------------------------------------------------------------
        ff = subDataset.ff{1};
        chanList = subDataset.chanList{1};
        for i=2:size(subDataset, 1),
            if ~isequal(ff, subDataset.ff{i})
                error('ffs are different!!');
            end
            if ~isequal(chanList, subDataset.chanList{i})
                error('channels are different!!');
            end
        end

        %--------------------------------------------------------------------------
        meanFft = subDataset.fftVals{1};
        for i=2:size(subDataset, 1),
            meanFft = meanFft + subDataset.fftVals{i};
        end
        meanFft = meanFft/size(subDataset, 1);
        
        %--------------------------------------------------------------------------
        figfilename = fullfile(resultsDir, [sprintf('ffts_frequency%dHz_subject%s', frequencies(iF), sub{iS}) '.png']);
        plotAndSaveMeanFft;

        
        %====================================================================================================
        %====================================================================================================
        %%                          DETAIL RUN FOR EACH SUBJECT
        %====================================================================================================
        %====================================================================================================
        detailDir = fullfile( resultsDir, sprintf('details_subject%s', sub{iS}) );
        if ~exist( detailDir, 'dir' ), mkdir( detailDir ); end
        allRuns = unique( subDataset.run );
        for iR = 1:numel(allRuns)
            
            runDataset = subDataset( ismember( subDataset.run, allRuns(iR) ), : );
            
            %--------------------------------------------------------------------------
            meanFft = runDataset.fftVals{1};
            for i=2:size(runDataset, 1),
                meanFft = meanFft + runDataset.fftVals{i};
            end
            meanFft = meanFft/size(runDataset, 1);
            
            %--------------------------------------------------------------------------
            figfilename = fullfile(detailDir, [sprintf('ffts_frequency%dHz_run%d', frequencies(iF), allRuns(iR)) '.png']);
            plotAndSaveMeanFft;
            
        end
        
    end
    
end


    %==============================================================================================================================
    %==============================================================================================================================
    %%                                          NESTED FUNCTION
    %==============================================================================================================================
    %==============================================================================================================================
    function plotAndSaveMeanFft
        
        plotFfts2( ...
            ff, ...
            meanFft, ...
            'chanLabels', chanList, ...
            'nMaxChanPerAx', 12, ...
            'title', sprintf('%dHz stimulation', frequencies(iF)), ...
            'scale', 2 ...
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
        
        set(findobj(gcf,'Type','uicontrol'),'Visible','off');
        
        s.Format = 'tiff';
        s.Resolution = h.I_DPI;
        hgexport(gcf, figfilename, s);
        
        close(gcf);
        
    end

end




