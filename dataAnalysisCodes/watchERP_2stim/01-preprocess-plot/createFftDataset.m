function createFftDataset

%% ====================================================================================================

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

%% ====================================================================================================

TableName   = 'watchErpDataset.xlsx';
fileList    = dataset('XLSFile', TableName);

[~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
resultsDir          = fullfile( resultsDir, folderName );
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

%% ====================================================================================================

updateDataset   = true;
sub             = unique( fileList.subjectTag );
nSubs           = numel(sub);
indsToRemove    = [];
for iS = 1:nSubs
    if updateDataset && exist( fullfile( resultsDir, sprintf('fftDataset_sub%.2d.mat', iS) ), 'file' )
        indsToRemove = [indsToRemove iS];
    end
end
sub(indsToRemove) = [];

if isempty(sub),
    fprintf('no need for update, all subject are already there!\n');
    return
end

%% ====================================================================================================

nSubs       = numel(sub);
nFreqs      = 2; % left and rigth square
nRunMax     = max( fileList.run );
nCuesMax    = 6;
timesToWatch= 1:14;
nTimes      = numel(timesToWatch);
minFreq     = 1;
maxFreq     = 35;

%% ====================================================================================================

refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

filter.fr_low_margin   = .2;
filter.fr_high_margin  = 40;
filter.order           = 4;
filter.type            = 'butter'; % Butterworth IIR filter
% [filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fs/2));

%% ====================================================================================================

for iS = 1:nSubs
    
    nData = nRunMax*nFreqs*nCuesMax*nTimes;
    
    subject     = cell( nData, 1 );
    run         = zeros( nData, 1 );
    frequency   = zeros( nData, 1 );
    cue         = zeros( nData, 1 );
    timeInSec   = zeros( nData, 1 );
    ff          = cell( nData, 1 );
    fftVals     = cell( nData, 1 );
    chanList    = cell( nData, 1 );
    fs          = zeros( nData, 1 );
    ind         = 1;
    
    subset = fileList( ismember( fileList.subjectTag, sub{iS} ), : );
    
    for iR = 1:size( subset, 1 )
        
        fprintf('\nsubject %s (%d out of %d), run %d out of %d', ...
            sub{iS}, iS, nSubs, iR, size(subset, 1) );
        
        %--------------------------------------------------------------------------
        sessionDir      = fullfile(dataDir, subset.sessionDirectory{iR});
        filename        = ls(fullfile(sessionDir, [subset.fileName{iR} '*.bdf']));
        paramFile       = ls(fullfile(sessionDir, [subset.fileName{iR}(1:19) '*.mat']));
        pars            = load( fullfile(sessionDir,paramFile), 'nCuesToShow', 'nRepetitions', 'lookHereStateSeq', 'realP3StateSeqOnsets', 'ssvepFreq', 'scenario' );
        pars.scenario   = rmfield(pars.scenario, 'textures');
        
        %--------------------------------------------------------------------------
        hdr             = sopen( fullfile(sessionDir, filename) );
        [sig hdr]       = sread(hdr);
        statusChannel   = bitand(hdr.BDF.ANNONS, 255);
        hdr.BDF         = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
        samplingRate    = hdr.SampleRate;
        
        channels        = hdr.Label;
        channels(strcmp(channels, 'Status')) = [];
        discardChanInd  = cell2mat( cellfun( @(x) find(strcmp(channels, x)), discardChanNames, 'UniformOutput', false ) );
        channels(discardChanInd) = [];
        refChanInd      = cell2mat( cellfun( @(x) find(strcmp(channels, x)), refChanNames, 'UniformOutput', false ) );
        nChan           = numel(channels);
        
        [filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(samplingRate/2));
        
        ssvepFreq       = pars.ssvepFreq;
        
        %--------------------------------------------------------------------------
        sig(:, discardChanInd)  = [];
        sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
        for i = 1:size(sig, 2)
            sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
        end
        [sig channels] = reorderEEGChannels(sig, channels);
        sig = sig{1};
    
        %--------------------------------------------------------------------------
        onsetEventInd   = cellfun( @(x) strcmp(x, 'SSVEP stim on'), {pars.scenario.events(:).desc} );
        onsetEventValue = pars.scenario.events( onsetEventInd ).id;
        eventChan       = logical( bitand( statusChannel, onsetEventValue ) );
        
        stimOnsets      = find( diff( eventChan ) == 1 ) + 1;
        stimOffsets     = find( diff( eventChan ) == -1 ) + 1;
        if numel(stimOnsets) ~= numel(stimOffsets)
            if numel(stimOffsets) == numel(stimOnsets)+1
                if stimOffsets(1) < stimOnsets(1) && stimOffsets(2) > stimOnsets(1)
                    stimOffsets(1) = [];
                else
                    error('something wrong with SSVEP onset/offset markers');
                end
            else 
               error('different amount of stimuli onsets and offsets');
            end
        end
        
        minEpochLenght  = min( stimOffsets - stimOnsets + 1 ) / samplingRate;
        
        %--------------------------------------------------------------------------
        for iF  = 1:numel(ssvepFreq)
            
            nItems          = numel( unique( pars.realP3StateSeqOnsets{iF} ) );
            targetStateSeq  = pars.lookHereStateSeq( pars.lookHereStateSeq~=max(pars.lookHereStateSeq) );
            indList         = ismember(targetStateSeq, (iF-1)*nItems+1:iF*nItems);

            stimOnsets_iF   = stimOnsets(indList);
            stimOffsets_iF  = stimOffsets(indList);
            
            for iCue = 1:numel( stimOnsets_iF )
                
                for iT = 1:nTimes

                    epochLenght     = timesToWatch(iT)*samplingRate;
                    NFFT            = 2^nextpow2(epochLenght);
                    f               = samplingRate/2*linspace(0,1,NFFT/2+1);
                    fx              = f( f>=minFreq & f<=maxFreq );
                    fftVals{ind}    = zeros( numel(fx), nChan );
                    
                    epoch   = sig( stimOnsets_iF(iCue):stimOnsets_iF(iCue)+epochLenght-1, : );
                    for iCh = 1:nChan
                        Y = fft(epoch(:, iCh), NFFT)/epochLenght;
                        Y = 2 * abs( Y( 1:NFFT/2+1 ) );
                        fftVals{ind}(:, iCh) = fftVals{ind}(:, iCh) + Y( f>=minFreq & f<=maxFreq, :);
                    end

                    
                    subject{ind}     = sub{iS};
                    run(ind)         = iR;
                    frequency(ind)   = ssvepFreq(iF);
                    cue(ind)         = iCue;
                    timeInSec(ind)   = timesToWatch(iT);
                    ff{ind}          = fx;
                    chanList{ind}    = channels;
                    fs(ind)          = samplingRate;
                    ind              = ind + 1;
                    
                end % OF TIME LOOP
            end % OF CUE LOOP
        end % OF FREQUENCY LOOP
    end % OF RUN LOOP
    
    subject(ind:end)      = [];
    run(ind:end)          = [];
    frequency(ind:end)    = [];
    cue(ind:end)          = [];
    timeInSec(ind:end)    = [];
    ff(ind:end)           = [];
    fftVals(ind:end)      = [];
    chanList(ind:end)     = [];
    fs(ind:end)           = [];
        
    fftDataset = dataset( ...
        subject, ...
        run, ...
        frequency, ...
        cue, ...
        timeInSec, ...
        ff, ...
        fftVals, ...
        chanList, ...
        fs ...
        );
    
    save( fullfile( resultsDir, sprintf('fftDataset_sub%.2d.mat', iS) ), 'fftDataset' );    
    
end % OF SUBJECT LOOP

end













