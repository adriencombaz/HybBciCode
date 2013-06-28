function computeSnrs_perSubject( iS )

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

%% ========================================================================================================

%--------------------------------------------------------------------------
sub     = unique( fileList.subjectTag );
fileList = fileList( ismember( fileList.subjectTag, sub{iS} ), : );
% resDir = fullfile( resDir, sprintf('linSvm_%dRunsForTrain', nRunsForTraining), sprinstf('subject_%s', sub{iS}) );
if ~exist( resDir, 'dir' ), mkdir(resDir); end

%--------------------------------------------------------------------------
run = unique( fileList.run );
if ~isequal(run(:), (1:max(run))'), error('wrong run numbering'); end
if numel(run) ~= size(fileList, 1), error('number of runs and files do not match'); end

%--------------------------------------------------------------------------
nRepMax = 10;
harmonics = [1 2];
nHarmonics = numel(harmonics);

refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

butterFilt.lowMargin = .2;
butterFilt.highMargin = 40;
butterFilt.order = 4;
targetFS = 256;
% nSquares = 2;
% nItemsPerSquare = 6;

%--------------------------------------------------------------------------
fid = fopen( fullfile( resDir, sprintf('snrs_subject%s.txt', sub{iS}) ),'wt' );
fprintf(fid, 'subject, run, roundNb, nRep, targetFrequency, watchedFrequency, channel, harmonic, snr, winnerFreq, correctness\n');

%% ========================================================================================================
for iRun = 1:max(run)
    
    %% LOAD AND PROCESS THE EEG DATA
    %==============================================================================
    %==============================================================================
    
    %
    %--------------------------------------------------------------------------
    sessionDir          = fullfile(dataDir, fileList.sessionDirectory{iRun});
    [~, name, ext]      = fileparts( ls(fullfile(sessionDir, [fileList.fileName{iRun} '*.bdf'])) );
    filename            = strtrim( [name ext] );
    hdr                 = sopen( fullfile(sessionDir, filename) );
    [sig hdr]           = sread(hdr);
    statusChannel       = bitand(hdr.BDF.ANNONS, 255);
    hdr.BDF             = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
    samplingRate        = hdr.SampleRate;
    [filter.a filter.b] = butter(butterFilt.order, [butterFilt.lowMargin butterFilt.highMargin]/(samplingRate/2));
    
    channels        = hdr.Label;
    channels(strcmp(channels, 'Status')) = [];
    discardChanInd  = cell2mat( cellfun( @(x) find(strcmp(channels, x)), discardChanNames, 'UniformOutput', false ) );
    refChanInd      = cell2mat( cellfun( @(x) find(strcmp(channels, x)), refChanNames, 'UniformOutput', false ) );
    channels([discardChanInd refChanInd]) = [];
    nChan           = numel(channels);
    
    %
    %--------------------------------------------------------------------------
    [~, name, ext]  = fileparts( ls(fullfile(sessionDir, [fileList.fileName{iRun}(1:19) '*.mat'])) );
    paramFile       = strtrim( [name ext] );
    pars            = load( fullfile(sessionDir,paramFile), 'nP3item', 'nCuesToShow', 'nRepetitions', 'lookHereStateSeq', 'realP3StateSeqOnsets', 'ssvepFreq', 'scenario' );
    pars.scenario   = rmfield(pars.scenario, 'textures');
    
    if ~isequal( pars.ssvepFreq, [12 15]), error('unexpected ssvep frequencies'); end
    
    
    %
    %--------------------------------------------------------------------------
    onsetEventIndSsvep   = cellfun( @(x) strcmp(x, 'SSVEP stim on'), {pars.scenario.events(:).desc} );
    onsetEventValueSsvep = pars.scenario.events( onsetEventIndSsvep ).id;
    eventChanSsvep       = logical( bitand( statusChannel, onsetEventValueSsvep ) );
    
    onsetEventIndP3   = cellfun( @(x) strcmp(x, 'P300 stim on'), {pars.scenario.events(:).desc} );
    onsetEventValueP3 = pars.scenario.events( onsetEventIndP3 ).id;
    eventChanP3       = logical( bitand( statusChannel, onsetEventValueP3 ) );
    
    targetStateSeq  = pars.lookHereStateSeq( pars.lookHereStateSeq~=max(pars.lookHereStateSeq) );
    
    %
    %-------------------------------------------------------------------------------------------
    refSig = mean(sig(:,refChanInd), 2);
    sig(:, [discardChanInd refChanInd])  = [];
    sig = bsxfun( @minus, sig, refSig );
    for i = 1:size(sig, 2)
        sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
    end
    [sig channels] = reorderEEGChannels(sig, channels);
    sig = sig{1};
    
    
    %
    %-------------------------------------------------------------------------------------------
    DSF = samplingRate / targetFS;
    if DSF ~= floor(DSF), error('something wrong with the sampling rate'); end
    
    subsamplingLPfilter = fspecial( 'gaussian', [1 DSF*2-1], 1 );
    sig                 = conv2( sig', subsamplingLPfilter, 'same' )';
    sig                 = sig(1:DSF:end,:);
    
    eventChanSsvep   = eventChanSsvep(1:DSF:end,:);
    ssvepOnsets      = find( diff( eventChanSsvep ) == 1 ) + 1;
    ssvepOffsets     = find( diff( eventChanSsvep ) == -1 ) + 1;
    ssvepOffsets( ssvepOffsets <= ssvepOnsets(1) ) = [];
    if pars.nCuesToShow ~= numel(ssvepOnsets), error('number of cues do not match'); end
    
    eventChanP3   = eventChanP3(1:DSF:end,:);
%     p3Onsets      = find( diff( eventChanP3 ) == 1 ) + 1;
    p3Offsets     = find( diff( eventChanP3 ) == -1 ) + 1;
    
    
    %
    %-------------------------------------------------------------------------------------------
    for iCue = 1:pars.nCuesToShow
        
        fprintf('subject %s, test run %d out of %d, cue %d out of %d\n', ...
            sub{iS}, iRun, max(run), iCue, pars.nCuesToShow);
        
        targetSymbol    = targetStateSeq( iCue );
        targetSquare    = ceil( targetSymbol / pars.nP3item );
        targetFreq      = pars.ssvepFreq( targetSquare );
        
        iSampleStart = ssvepOnsets( iCue );
        p3Offsets_iCue = p3Offsets( p3Offsets > ssvepOnsets( iCue ) & p3Offsets < ssvepOffsets( iCue ) );
        if numel(p3Offsets_iCue) ~= pars.nRepetitions * pars.nP3item,
            error('not the expected amount of p3 onsets');
        end
        
        for iRep = 1:nRepMax
            
            iSampleEnd  = p3Offsets_iCue( iRep * pars.nP3item );
            epochLenght = iSampleEnd - iSampleStart + 1;
            epoch       = sig( iSampleStart:iSampleEnd, : );
            mcdObj      = myMCD( pars.ssvepFreq, targetFS, harmonics, epochLenght );
            [Snr, ~]    = mcdObj.getSNRs( epoch' );
            clear mcdObj
            
            for iFreq = 1:numel( pars.ssvepFreq )
                for iCh = 1:nChan
                    for iH = 1:nHarmonics
                        
                        snr_iCh_iH = squeeze( Snr((iCh-1)*nHarmonics+iH, :) );
                        if ~isequal(size(snr_iCh_iH), [1 2]), error('something wrong here!'); end
                        winnerFreq = pars.ssvepFreq( snr_iCh_iH == max(snr_iCh_iH) );
                        fprintf(fid, '%s, %d, %d, %d, %.2f, %.2f, %s, %d, %f, %.2f, %d\n' ...
                            , sub{iS} ...
                            , iRun ...
                            , iCue ...
                            , iRep ...
                            , targetFreq ...
                            , pars.ssvepFreq(iFreq) ...
                            , channels{iCh} ...
                            , iH-1 ...
                            , snr_iCh_iH( iFreq ) ...
                            , winnerFreq ...
                            , winnerFreq == targetFreq ...
                            );
                    end % OF NHARMONICS LOOP
                end % OF NCHANNELS LOOP
            end % OF NFREQ LOOP
        end % OF NREPETITIONS LOOP
    end % OF NCUES LOOP
end % OF NRUNS LOOP

fclose(fid);

end