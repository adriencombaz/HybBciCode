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
        resDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP\03-xxx-watchFFT\';
        codeDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        resDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciProcessedData\watchERP\03-xxx-watchFFT\';
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

minFreq = 1;
maxFreq = 35;

nSub    = numel( sub );
nFreq   = numel( freq );
nOdd    = numel( oddb );
nCond   = numel( cond );
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


% targetFS    = 256;
targetFS    = 1024;
datasetFilename = fullfile(resDir, sprintf('fftDataset_%dfs.mat', targetFS));

% ========================================================================================================
% ========================================================================================================
% updateDataset   = true;
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

nMaxTrials  = 36;
timesInSec  = 1:14;
nTimes      = numel( timesInSec );
indTrial    = zeros(nSub, nFreq, nOdd);


for iS = 1:nSub,
    
    datasetFilename = fullfile(resDir, sprintf('fftDataset_%s_%dfs.mat',sub{iS}, targetFS));
    nData       = nTimes*nMaxTrials*nOdd*nFreq;
    
    subject     = cell( nData, 1);
    frequency   = zeros( nData, 1);
    oddball     = zeros( nData, 1);
    trial       = cell( nData, 1);
    fileNb      = zeros( nData, 1);
    stimDuration= zeros( nData, 1);
    % snr         = cell( nData, 1);
    fftFreqs    = cell( nData, 1);
    fftVals     = cell( nData, 1);
    chanList    = cell( nData, 1);
    iData     = 1;

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
                clear refSig
                for i = 1:size(sig, 2)
                    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
                end
                [sig channels] = reorderEEGChannels(sig, channels);
                sig = sig{1};
                
                
                %-------------------------------------------------------------------------------------------
                DSF = samplingRate / targetFS;
                if DSF ~= floor(DSF), error('something wrong with the sampling rate'); end
                
                if DSF > 1
                    subsamplingLPfilter = fspecial( 'gaussian', [1 DSF*2-1], 1 );
                    sig                 = conv2( sig', subsamplingLPfilter, 'same' )';
                    sig                 = sig(1:DSF:end,:);
                end
                
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
                    NFFT            = 2^nextpow2(epochLenght);
                    f               = samplingRate/2*linspace(0,1,NFFT/2+1);
                    fx              = f( f>=minFreq & f<=maxFreq );
                    for iTrial = 1:nTrials
                        epoch = sig( stimOnsets(iTrial):stimOnsets(iTrial)+epochLenght-1, : );
                        
                        fftVals{iData}    = zeros( numel(fx), nChan );
                       
                        for iCh = 1:nChan,
                            Y = fft(epoch(:, iCh), NFFT)/epochLenght;
                            Y = 2 * abs( Y( 1:NFFT/2+1 ) );
                            fftVals{iData}(:, iCh) = Y( f>=minFreq & f<=maxFreq, :);
                        end
                        
%                         [SNRs Ns]   = mcdObj.getSNRs( epoch' );
%                         SNRs        = reshape(SNRs, nHarm, nChan)';
                        
                        
                        subject{iData}      = sub{iS};
                        frequency(iData)    = freq(iF);
                        oddball(iData)      = oddb(iOdd);
                        fileNb(iData)       = iFile;
                        trial{iData}        = sprintf('tr%.2d', iTrial);
                        stimDuration(iData) = timesInSec(iTime);
%                         snr{iData}          = SNRs;
                        fftFreqs{iData}     = fx;
                        chanList{iData}     = channels;
                        iData               = iData + 1;
                        
                    end
                end
                
                clear sig mcdObj
            end % of loop over files
        end % of loop over oddball condition
    end % of loop over frequency condition
    
    
    subject(iData:end)      = [];
    frequency(iData:end)    = [];
    oddball(iData:end)      = [];
    fileNb(iData:end)       = [];
    trial(iData:end)        = [];
    stimDuration(iData:end) = [];
    % snr(iData:end)          = [];
    fftFreqs(iData:end)     = [];
    fftVals(iData:end)      = [];
    chanList(iData:end)     = [];
    
    fftDataset = dataset( ...
        subject ...
        , frequency ...
        , oddball ...
        , fileNb ...
        , trial ...
        , stimDuration ...
        , fftFreqs ...
        , fftVals ...
        , chanList ...
        );
    
    if updateDataset
        fftDataset = vertcat( temp.psdDataset, fftDataset );
    end
    
    save(datasetFilename, 'fftDataset');
    
end % of loop over subject

%% ========================================================================================================
% =========================================================================================================


%% ========================================================================================================
% =========================================================================================================

subsetChannels  = {...
                'O1', 'Oz', 'O2' ...
};


for iCh = 1:numel(subsetChannels)
    
    for iS = 1:nSub

        datasetFilename = fullfile(resDir, sprintf('fftDataset_%s_%dfs.mat',sub{iS}, targetFS));
        load(datasetFilename, 'fftDataset');

        fftDataset_iCh_iS            = fftDataset;
        fftDataset_iCh_iS.fftVals    = cellfun(@(x, y) x( :, ismember( y, subsetChannels{iCh} ) ), fftDataset_iCh_iS.fftVals, fftDataset_iCh_iS.chanList, 'UniformOutput', false );
        inds                         = cellfun(@(x, y) find(abs(x-y) == min(abs(x-y))), fftDataset_iCh_iS.fftFreqs, num2cell(fftDataset_iCh_iS.frequency) );
        fftDataset_iCh_iS.fftFreqs   = cellfun(@(x, y) x( y ), fftDataset_iCh_iS.fftFreqs, num2cell(inds) );
%         fftDataset_iCh_iS.fftFreqs   = cellfun(@(x, y) x( (abs(x-y) == min(abs(x-y))) ), fftDataset.fftFreqs, num2cell(fftDataset.frequency) );
        fftDataset_iCh_iS.fftVals    = cellfun(@(x, y) x( y ), fftDataset_iCh_iS.fftVals, num2cell(inds) );
        fftDataset_iCh_iS.chanList   = [];
        fftDataset_iCh_iS.channel    = repmat(subsetChannels(iCh), size(fftDataset_iCh_iS, 1), 1);

        if iS == 1
            fftDataset_iCh = fftDataset_iCh_iS;
        else
            fftDataset_iCh = [ fftDataset_iCh ; fftDataset_iCh_iS ];
        end
        
        
    end
        
    filename = sprintf('fftDataset_%s_%dfs.csv', subsetChannels{iCh}, targetFS);
    export( fftDataset_iCh, 'file', fullfile(resDir, filename), 'delimiter', ',' );
        
end

