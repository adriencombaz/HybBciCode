% function topoplotSnr( iS )

iS = 1;

% init host name
%--------------------------------------------------------------------------
if isunix,
    envVarName = 'HOSTNAME';
else
    envVarName = 'COMPUTERNAME';
end
hostName = lower( strtok( getenv( envVarName ), '.') );

switch hostName,
    case 'kuleuven-24b13c',
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP_2stim\03-classify-ssveps\';
        codeDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP_2stim\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciProcessedData\watchERP_2stim\03-classify-ssveps\';
        codeDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP_2stim\';
    case {'sunny', 'solaris', ''}
        addpath( genpath( '~/PhD/hybridBCI-stuffs/deps/' ) );
        rmpath( genpath('~/PhD/hybridBCI-stuffs/deps/eeglab10_0_1_0b/external/SIFT_01_alpha') );
        dataDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/data/';
        resDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/results/03-classify-ssveps/';
        codeDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/code/';
    otherwise,
        error('host not recognized');
end

if isunix,
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset.csv');
    fileList    = dataset('File', TableName, 'Delimiter', ',');
else
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset.xlsx');
    fileList    = dataset('XLSFile', TableName);
end

locFile         = 'eloc32-biosemi.locs';
chanLocs    = readlocs(locFile, 'filetype', 'loc');

%% ========================================================================================================

%--------------------------------------------------------------------------
sub     = unique( fileList.subjectTag );
filename = fullfile( resDir, sprintf('Results_subject%s.txt', sub{iS}) );

fprintf('loading the dataset... can take a while...\n');
snrDataset = dataset('File', filename, 'Delimiter', ',');
fprintf('dataset loaded!!!!!\n');


%% 
allChans = unique(snrDataset.channel);
allReps = unique(snrDataset.nRep);
allTargetFreq = unique(snrDataset.targetFrequency);
nChan = numel(allChans);
nReps = numel(allReps);
nTargetFreq = numel(allTargetFreq);

for iTF = 1:nTargetFreq
    
    figure;
    for iRep = 1:nReps
        axh = subplot(4, 3, iRep);
        set(axh, 'visible', 'off');
        
        valuesSnr = zeros(1, nChan);
        for iChan = 1:nChan
            
            subDataset = snrDataset( ...
                ismember( snrDataset.targetFrequency, allTargetFreq(iTF) ) ...
                & ismember( snrDataset.nRep, allReps(iRep) ) ...
                & ismember( snrDataset.channel, allChans{iChan} ) ...
                , : );
            
            if allTargetFreq(iTF) == 15
                valuesSnr(iChan) = mean( subDataset.srn15Hz - subDataset.snr12Hz );
            elseif allTargetFreq(iTF) == 12
                valuesSnr(iChan) = mean( subDataset.snr12Hz - subDataset.srn15Hz );
            else
                error('target freq not recognized!!');
            end
            
        end
        
        
        
        topoplot( sign(valuesSnr), chanLocs );
        title( sprintf('nReps = %d', iRep) );
        colorbar
    end
    
end


% end