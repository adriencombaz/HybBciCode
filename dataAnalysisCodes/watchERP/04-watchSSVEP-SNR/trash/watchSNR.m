function watchSNR

channelList{1} = {'Oz'};
channelList{2} = {'O1', 'Oz', 'O2'};
channelList{3} = {'CP5', 'CP1', 'CP2', 'CP6', 'P7', 'P3', 'Pz', 'P4', 'P8', 'PO3', 'PO4', 'O1', 'Oz', 'O2'};
channelList{4} = 'all';

labels = {'Oz', 'occipital', 'occipito-parietal', 'all-scalp'};

for i = 4%1:numel(channelList)
    
    createSnrDataset(channelList{i}, labels{i});
    
end

end

function createSnrDataset(channelList, label)

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
        resDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watch-ERP\04-watchSSVEP-SNR\';
%         codeDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        resDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciProcessedData\watch-ERP\04-watchSSVEP-SNR\';
%         codeDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\';
    case {'sunny', 'solaris', ''}
        addpath( genpath( '~/PhD/hybridBCI-stuffs/deps/' ) );
        rmpath( genpath('~/PhD/hybridBCI-stuffs/deps/eeglab10_0_1_0b/external/SIFT_01_alpha') );
        dataDir = '~/PhD/hybridBCI-stuffs/data/';
        resDir = '~/PhD/hybridBCI-stuffs/results/04-watchSSVEP-SNR/';
%         codeDir = '~/PhD/hybridBCI-stuffs/code/';
    otherwise,
        error('host not recognized');
end

% resDir = fullfile(resDir, label);
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
nData       = nTimes*nMaxTrials*nOdd*nFreq*nSub*nHarm;

subject     = cell( nData, 1);
frequency   = zeros( nData, 1); 
oddball     = zeros( nData, 1);
trial       = zeros( nData, 1);
fileNb      = zeros( nData, 1);
stimDuration= zeros( nData, 1);
snr         = cell( nData, 1); 
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
                
                fprintf('treating subject %s (%d out %d), frequency %.2f (%d out of %d), oddball condition %d (%d out of %d), file %d/%d\n', ...
                    sub{iS}, iS, nSub, ...
                    freq(iF), iF, nFreq, ...
                    oddb(iOdd), iOdd, nOdd, ...
                    iFile, size(subset, 1));
                
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
                
                channels    = hdr.Label;
                refChanInd  = cell2mat( cellfun( @(x) find(strcmp(channels, x)), refChanNames, 'UniformOutput', false ) );
                if strcmp( channelList, 'all' )
                    channels(strcmp(channels, 'Status')) = [];
                    discardChanInd  = cell2mat( cellfun( @(x) find(strcmp(channels, x)), discardChanNames, 'UniformOutput', false ) );
                    channels([discardChanInd refChanInd]) = [];
                    chanInd = 1:numel(channels);
                else
                    chanInd     = cell2mat( cellfun( @(x) find(strcmp(channels, x)), channelList, 'UniformOutput', false ) );
                    channels    = channels(chanInd);
                end                
                nChan       = numel(channels);

                %-------------------------------------------------------------------------------------------
                paramFileName   = [filename(1:19) '.mat'];
                expParams       = load( fullfile(sessionDir, paramFileName) );
                expParams.scenario = rmfield(expParams.scenario, 'textures');
                
                onsetEventInd   = cellfun( @(x) strcmp(x, 'SSVEP stim on'), {expParams.scenario.events(:).desc} );
                onsetEventValue = expParams.scenario.events( onsetEventInd ).id;
                eventChan       = logical( bitand( statusChannel, onsetEventValue ) );
                
                
                %-------------------------------------------------------------------------------------------
                refSig = mean(sig(:,refChanInd), 2);
%                 sig(:, [discardChanInd refChanInd])  = [];
                sig = sig(:, chanInd);
                sig = bsxfun( @minus, sig, refSig );
                for i = 1:size(sig, 2)
                    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
                end
%                 [sig channels] = reorderEEGChannels(sig, channels);
%                 sig = sig{1};
                
                
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
                    
%                     fprintf('treating subject %s (%d out %d), frequency %d (%d out of %d), oddball condition %d (%d out of %d), file %d/%d, epoch lenght of %g seconds (%d out of %d)\n', ...
%                         sub{iS}, iS, nSub, ...
%                         freq(iF), iF, nFreq, ...
%                         oddb(iOdd), iOdd, nOdd, ...
%                         iFile, size(subset, 1), ...
%                         timesInSec(iTime), iTime, nTimes);                    
                    
                    
                    epochLenght = timesInSec(iTime)*targetFS;
                    mcdObj      = myMCD( freq(iF), targetFS, harm, epochLenght );
                    
                    for iTrial = 1:nTrials
                        epoch       = sig( stimOnsets(iTrial):stimOnsets(iTrial)+epochLenght-1, : );
                        [SNRs, ~]   = mcdObj.getSNRs( epoch' );
                        SNRs        = reshape(SNRs, nHarm, nChan)';
                        
                        
                        subject{iData}      = sub{iS};
                        frequency(iData)    = freq(iF);
                        oddball(iData)      = oddb(iOdd);
                        fileNb(iData)       = iFile;
                        trial(iData)        = iTrial;
                        stimDuration(iData) = timesInSec(iTime);
                        snr{iData}          = SNRs;
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
snr(iData:end)          = [];
chanList(iData:end)     = [];
harmonics(iData:end)    = [];

snrDatasetFull = dataset( ...
    subject ...
    , frequency ...
    , oddball ...
    , fileNb ...
    , trial ...
    , stimDuration ...
    , snr ...
    , chanList ...
    , harmonics ...
    );

for iH = 1:nHarm
    
    snrDataset              = snrDatasetFull;
    snrDataset.snr          = cell2mat( cellfun(@(x) mean( mean( x( :, iH ) ) ), snrDatasetFull.snr, 'UniformOutput', false ) );
    snrDataset.harmonics    = [];
    snrDataset.chanList     = [];
    filename                = sprintf('snrDataset_%s_%dHa.csv', label, iH);
    export( snrDataset, 'file', fullfile(resDir, filename), 'delimiter', ',' );

end
% save(fullfile(resDir, 'snrDataset.mat'), 'snrDataset');

end
