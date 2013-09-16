cl;

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
        resDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watch-ERP\04-watchSSVEP-PSD\';
        codeDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        resDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciProcessedData\watch-ERP\04-watchSSVEP-PSD\';
        codeDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\';
    case {'sunny', 'solaris', ''}
        addpath( genpath( '~/PhD/hybridBCI-stuffs/deps/' ) );
        rmpath( genpath('~/PhD/hybridBCI-stuffs/deps/eeglab10_0_1_0b/external/SIFT_01_alpha') );
        dataDir = '~/PhD/hybridBCI-stuffs/data/';
        resDir = '~/PhD/hybridBCI-stuffs/results/04-watchSSVEP-PSD/';
        codeDir = '~/PhD/hybridBCI-stuffs/code/';
    otherwise,
        error('host not recognized');
end

if ~exist(resDir, 'dir'), mkdir(resDir); end

% ========================================================================================================
% ========================================================================================================

TableName   = 'watchFftDataset.xlsx';
fileList    = dataset('XLSFile', TableName);

sub     = unique( fileList.subjectTag );
freq    = unique( fileList.frequency );
oddb    = unique( fileList.oddball );
cond    = unique( fileList.condition );
harm	= [1 2];

nSub    = numel( sub );
nFreq   = numel( freq );
nOdd    = numel( oddb );
nCond   = numel( cond );
nHarm   = numel( harm );
if nCond ~= nFreq*nOdd, error('conditions are not entirely determined by frequency and oddball'); end
if ~isequal( oddb, [0 ; 1] ), error('not the expected oddball condition'); end

% check consistency of data
for iS = 1:nSub
    
    subData = fileList( ismember(fileList.subjectTag, sub{iS}), : );
    for iF = 1:nFreq
    
        subFreq = subData( ismember(subData.frequency, freq(iF)), : );
        oddCond = sort( unique( subFreq.oddball ) );
        if ~isequal( oddCond, oddb ),
            error( 'subject %s, frequency %d, not the expected oddball condition', sub{iS}, freq(iF) );
        end
        
    end
end

datasetFilename = fullfile(resDir, 'psdDataset.mat');

% ========================================================================================================
% ========================================================================================================
updateDataset   = false;

if updateDataset && exist(datasetFilename, 'file')
    temp = load( datasetFilename );
    treatedSub = unique( temp.psdDataset.subject );
    sub(ismember(sub, treatedSub)) = [];
end

if isempty(sub),
    fprintf('no need for update, all subject are already there!\n');
    return
end

nSub    = numel( sub );

% ========================================================================================================
% ========================================================================================================
refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

filter.fr_low_margin   = .2;
filter.fr_high_margin  = 40;
filter.order           = 4;
filter.type            = 'butter'; % Butterworth IIR filter

targetFS    = 256;

nMaxTrials  = 36;
timesInSec  = 1:14;
nTimes      = numel( timesInSec );
indTrial    = zeros(nSub, nFreq, nOdd);
nData       = nTimes*nMaxTrials*nOdd*nFreq*nSub*nHarm;

subject     = cell( nData, 1);
frequency   = zeros( nData, 1); 
oddball     = zeros( nData, 1);
trial       = cell( nData, 1);
fileNb      = zeros( nData, 1);
stimDuration= zeros( nData, 1);
% snr         = cell( nData, 1); 
psd         = cell( nData, 1); 
chanList    = cell( nData, 1);
harmonics   = cell( nData, 1);
iData     = 1;

for iS = 1:nSub,
    for iF = 1:nFreq,
        for iOdd = 1:nOdd,
            
            subset = fileList( ...
                ismember( fileList.subjectTag, sub{iS} ) & ...
                ismember( fileList.frequency, freq(iF) ) & ...
                ismember( fileList.oddball, oddb(iOdd) ) ...
                , : );
            
            for iFile = 1:size(subset, 1) % multiple file case
                                
                %-------------------------------------------------------------------------------------------
                sessionDir      = fullfile(dataDir, subset.sessionDirectory{iFile});
                filename        = ls(fullfile(sessionDir, [subset.fileName{iFile} '*.bdf']));
                hdr             = sopen( fullfile(sessionDir, filename) );
                [sig hdr]       = sread(hdr);
                
                if strcmp(filename, '2013-03-13-10-16-47-hybrid-12Hz.bdf')
                    statusChannel = fix_2013_13_10_16_47_hybrid_12Hz( fullfile(sessionDir, filename) );
                else                
                    statusChannel = bitand(hdr.BDF.ANNONS, 255);
                end
                
                hdr.BDF         = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
                samplingRate    = hdr.SampleRate;
                [filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(samplingRate/2));
                
                channels        = hdr.Label;
                channels(strcmp(channels, 'Status')) = [];
                discardChanInd  = cell2mat( cellfun( @(x) find(strcmp(channels, x)), discardChanNames, 'UniformOutput', false ) );
                refChanInd      = cell2mat( cellfun( @(x) find(strcmp(channels, x)), refChanNames, 'UniformOutput', false ) );
                channels([discardChanInd refChanInd]) = [];
                nChan           = numel(channels);

                %-------------------------------------------------------------------------------------------
                paramFileName   = [filename(1:19) '.mat'];
                expParams       = load( fullfile(sessionDir, paramFileName) );
                expParams.scenario = rmfield(expParams.scenario, 'textures');
                
                onsetEventInd   = cellfun( @(x) strcmp(x, 'SSVEP stim on'), {expParams.scenario.events(:).desc} );
                onsetEventValue = expParams.scenario.events( onsetEventInd ).id;
                eventChan       = logical( bitand( statusChannel, onsetEventValue ) );
                
                
                %-------------------------------------------------------------------------------------------
                refSig = mean(sig(:,refChanInd), 2);
                sig(:, [discardChanInd refChanInd])  = [];
                sig = bsxfun( @minus, sig, refSig );
                for i = 1:size(sig, 2)
                    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
                end
                [sig channels] = reorderEEGChannels(sig, channels);
                sig = sig{1};
                
                
                %-------------------------------------------------------------------------------------------
                DSF = samplingRate / targetFS;
                if DSF ~= floor(DSF), error('something wrong with the sampling rate'); end

                subsamplingLPfilter = fspecial( 'gaussian', [1 DSF*2-1], 1 );
                sig                 = conv2( sig', subsamplingLPfilter, 'same' )';
                sig                 = sig(1:DSF:end,:);
                
                eventChan       = eventChan(1:DSF:end,:);
                stimOnsets      = find( diff( eventChan ) == 1 ) + 1;
                stimOffsets     = find( diff( eventChan ) == -1 ) + 1;
                stimOffsets( stimOffsets <= stimOnsets(1) ) = [];
                minEpochLenght  = min( stimOffsets - stimOnsets + 1 ) / targetFS;
                if max(timesInSec) > minEpochLenght, error('Time to watch is larger (%g sec) than smallest SSVEP epoch lenght (%g sec)', max(timesInSec), minEpochLenght); end
                nTrials         = numel(stimOnsets);
                
                %-------------------------------------------------------------------------------------------
                for iTime = 1:nTimes
                    
                    fprintf('treating subject %s (%d out %d), frequency %d (%d out of %d), oddball condition %d (%d out of %d), file %d/%d, epoch lenght of %g seconds (%d out of %d)\n', ...
                        sub{iS}, iS, nSub, ...
                        freq(iF), iF, nFreq, ...
                        oddb(iOdd), iOdd, nOdd, ...
                        iFile, size(subset, 1), ...
                        timesInSec(iTime), iTime, nTimes);                    
                    
                    
                    epochLenght = timesInSec(iTime)*targetFS;
                    
                    % Prepare martrix X for signal power [Pxx] estimation
                    X = freq(iF) * repmat( (1:epochLenght)'*2*pi/targetFS, [1 2 nHarm] );
                    % adjust harmonic slices
                    for iHarm = 1:nHarm, % in the paper iHarm <-> k
                        X(:,:,iHarm) = X(:,:,iHarm) * harm(iHarm);
                    end
                    % apply sin and cos
                    X(:,1,:) = sin( X(:,1,:) );
                    X(:,2,:) = cos( X(:,2,:) );
                    
%                     mcdObj      = myMCD( freq(iF), targetFS, harm, epochLenght );
                    
                    for iTrial = 1:nTrials
                        epoch       = sig( stimOnsets(iTrial):stimOnsets(iTrial)+epochLenght-1, : );
                        
                        P = zeros( nChan, nHarm );
                        for iCh = 1:nChan,
                            for iHarm = 1:nHarm,
                                P(iCh,iHarm) = norm( epoch(:,iCh)' * X(:,:,iHarm) );
                            end
                        end
                        P = P .^ 2;
                        
%                         [SNRs Ns]   = mcdObj.getSNRs( epoch' );
%                         SNRs        = reshape(SNRs, nHarm, nChan)';
                        
                        
                        subject{iData}      = sub{iS};
                        frequency(iData)    = freq(iF);
                        oddball(iData)      = oddb(iOdd);
                        fileNb(iData)       = iFile;
                        trial{iData}        = sprintf('tr%.2d', iTrial);
                        stimDuration(iData) = timesInSec(iTime);
%                         snr{iData}          = SNRs;
                        psd{iData}          = P;
                        chanList{iData}     = channels;
                        harmonics{iData}    = harm;
                        iData               = iData + 1;
                        
                    end
                end
                
                clear sig mcdObj
            end % of loop over files
        end % of loop over oddball condition
    end % of loop over frequency condition
end % of loop over subject


subject(iData:end)      = [];
frequency(iData:end)    = [];
oddball(iData:end)      = [];
fileNb(iData:end)       = [];
trial(iData:end)        = [];
stimDuration(iData:end) = [];
% snr(iData:end)          = [];
psd(iData:end)          = [];
chanList(iData:end)     = [];
harmonics(iData:end)    = [];

psdDataset = dataset( ...
    subject ...
    , frequency ...
    , oddball ...
    , fileNb ...
    , trial ...
    , stimDuration ...
    , psd ...
    , chanList ...
    , harmonics ...
    );

if updateDataset
    psdDataset = vertcat( temp.psdDataset, psdDataset );
end

save(datasetFilename, 'psdDataset');



%% ========================================================================================================
% =========================================================================================================

psdDatasetOz            = psdDataset;
psdDatasetOz.psd        = cellfun(@(x, y) x( ismember( y, 'Oz' ), 1 ), psdDataset.psd, psdDataset.chanList );
psdDatasetOz.chanList   = [];
psdDatasetOz.harmonics  = [];
export( psdDatasetOz, 'file', fullfile(resDir, 'psdDataset_Oz_1Ha.csv'), 'delimiter', ',' );

%----------------------------------------------------------------------------------------------------------

psdDatasetOz            = psdDataset;
psdDatasetOz.psd        = cellfun(@(x, y) mean( x( ismember( y, 'Oz' ), : ), 2 ), psdDataset.psd, psdDataset.chanList );
psdDatasetOz.chanList   = [];
psdDatasetOz.harmonics  = [];
export( psdDatasetOz, 'file', fullfile(resDir, 'psdDataset_Oz_2Ha.csv'), 'delimiter', ',' );

%----------------------------------------------------------------------------------------------------------


subsetChannels  = {'O1', 'Oz', 'O2'};

psdDatasetOcciptial            = psdDataset;
psdDatasetOcciptial.psd        = cellfun(@(x, y) mean( x( ismember( y, subsetChannels ), 1 ), 1), psdDataset.psd, psdDataset.chanList, 'UniformOutput', false );
psdDatasetOcciptial.chanList   = [];
psdDatasetOcciptial.harmonics  = [];
export( psdDatasetOcciptial, 'file', fullfile(resDir, 'psdDataset_O1OzO2_1Ha.csv'), 'delimiter', ',' );

%----------------------------------------------------------------------------------------------------------

psdDatasetOcciptial            = psdDataset;
psdDatasetOcciptial.psd        = cellfun(@(x, y) mean( mean( x( ismember( y, subsetChannels ), : ), 2 ), 1), psdDataset.psd, psdDataset.chanList, 'UniformOutput', false );
psdDatasetOcciptial.chanList   = [];
psdDatasetOcciptial.harmonics  = [];
export( psdDatasetOcciptial, 'file', fullfile(resDir, 'psdDataset_O1OzO2_2Ha.csv'), 'delimiter', ',' );


%----------------------------------------------------------------------------------------------------------

subsetChannels  = {...
        'CP5',   'CP1',   'CP2',   'CP6', ...
...
      'P7',   'P3',   'Pz',   'P4',   'P8', ...
...     
               'PO3',       'PO4', ...
                'O1', 'Oz', 'O2' ...
};

psdDatasetSelChan            = psdDataset;
psdDatasetSelChan.psd        = cellfun(@(x, y) mean( x( ismember( y, subsetChannels ), 1 ), 1), psdDataset.psd, psdDataset.chanList, 'UniformOutput', false );
psdDatasetSelChan.chanList   = [];
psdDatasetSelChan.harmonics  = [];
export( psdDatasetSelChan, 'file', fullfile(resDir, 'psdDataset_SelChan_1Ha.csv'), 'delimiter', ',' );

%----------------------------------------------------------------------------------------------------------

psdDatasetSelChan            = psdDataset;
psdDatasetSelChan.psd        = cellfun(@(x, y) mean( mean( x( ismember( y, subsetChannels ), : ), 2 ), 1), psdDataset.psd, psdDataset.chanList, 'UniformOutput', false );
psdDatasetSelChan.chanList   = [];
psdDatasetSelChan.harmonics  = [];
export( psdDatasetSelChan, 'file', fullfile(resDir, 'psdDataset_SelChan_2Ha.csv'), 'delimiter', ',' );


%% ========================================================================================================
% =========================================================================================================

subsetChannels  = {...
        'CP5',   'CP1',   'CP2',   'CP6', ...
...
      'P7',   'P3',   'Pz',   'P4',   'P8', ...
...     
               'PO3',       'PO4', ...
                'O1', 'Oz', 'O2' ...
};


for iCh = 1:numel(subsetChannels)
    for iHa = 1:2

        psdDataset_iCh_iHa            = psdDataset;
        psdDataset_iCh_iHa.psd        = cellfun(@(x, y) x( ismember( y, subsetChannels{iCh} ), iHa ), psdDataset.psd, psdDataset.chanList );
        psdDataset_iCh_iHa.chanList   = [];
        psdDataset_iCh_iHa.harmonics  = [];
        psdDataset_iCh_iHa.channel    = repmat(subsetChannels(iCh), size(psdDataset_iCh_iHa, 1), 1);
        psdDataset_iCh_iHa.harmonic   = iHa*ones( size(psdDataset_iCh_iHa, 1), 1 );
        filename = sprintf('psdDataset_%s_Ha%d.csv', subsetChannels{iCh}, iHa);
        export( psdDataset_iCh_iHa, 'file', fullfile(resDir, filename), 'delimiter', ',' );
        
        
    end
end


%% ========================================================================================================
% =========================================================================================================

% sub    = unique( psdDataset.subject );
% freq    = unique( psdDataset.frequency );
% oddb    = unique( psdDataset.oddball );
% trial   = unique( psdDataset.trial );
% stimDur = unique( psdDataset.stimDuration );
% 
% nSub    = numel( sub );
% nOdd    = numel( oddb );
% nFreq   = numel( freq );
% nTrial  = numel( trial);
% nStimDur = numel(stimDur);
% 
% 
% cmap = colormap; close(gcf);
% nCmap = size(cmap, 1);
% colorList = zeros(nFreq, 3);
% for i = 1:nFreq
%     colorList(i, :) = cmap( round((i-1)*(nCmap-1)/(nFreq-1)+1) , : );
% end
% 
% 
% lineStyles = {'--', '-.', ':', '-.', '--'};
% markers = {'o', '^', 's', 'd', 'v'};
% 
% 
% channels = {'O1', 'Oz', 'O2'}; 
%   
% nChan = numel(channels);
%  
% for iSub = 1:nSub
%     
%     figure;
%     
%     for iCh = 1:nChan
%         
%         subplot(nChan, 1, iCh);
%         hold on;
%         legStr = cell(1, nFreq*nOdd);
%         i = 1;
%         for iFreq = 1:nFreq
%             for iOdd = 1:nOdd
%                 
%                 toPlot = zeros( nStimDur, 1 );
%                 for iSD = 1:nStimDur
%                     
%                     subDataset = psdDataset( ...
%                         ismember( psdDataset.subject, sub{iSub} ) ...
%                         & ismember( psdDataset.frequency, freq(iFreq) ) ...
%                         & ismember( psdDataset.oddball, oddb(iOdd) ) ...
%                         & ismember( psdDataset.stimDuration, stimDur(iSD) ) ...
%                         , :);
%                     
% %                     toPlot(iSD) = mean( cellfun( @(x, y) x( ismember( y, channels{iCh} ) ), subDataset.psd, subDataset.chanList ) );
%                     toPlot(iSD) = mean( cellfun( @(x, y) sum( x( ismember( y, channels{iCh} ), : ), 2 ), subDataset.psd, subDataset.chanList ) );
%                     
%                 end
%                 
%                 plot(stimDur, toPlot ...
%                     , 'LineStyle', lineStyles{iOdd} ...
%                     , 'Color', colorList(iFreq, :) ...
%                     , 'LineWidth', 2 ...
%                     , 'Marker', markers{iOdd} ...
%                     , 'MarkerFaceColor', colorList(iFreq, :) ...
%                     , 'MarkerEdgeColor', colorList(iFreq, :) ...
%                     , 'MarkerSize', 2 ...
%                     );
%                 
%                 legStr{i} = sprintf('freq %.2d, oddball %d', freq(iFreq), oddb(iOdd));
%                 i = i+1;
%             end
%         end
%         
%         
%     end
%     legend(legStr)
%     
% end
% 

