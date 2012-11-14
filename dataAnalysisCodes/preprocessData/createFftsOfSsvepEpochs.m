function createFftsOfSsvepEpochs


sessionName{1} = '2012-10-29-Watermelon';

for i = 1:numel(sessionName)
%     createFfts(sessionName{i}, 'eogCorrected');
    createFfts(sessionName{i}, 'nonEogCorreted');
end


end

function createFfts(sessionName, eogTag)

fprintf('\ntreating session %s (%s)\n', sessionName, eogTag);

% Init directories
%--------------------------------------------------------------------------
dataDir         = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\';
folderName      = fullfile(dataDir, sessionName, eogTag);
outputFolder    = fullfile(folderName, 'fftsEpochs');
fileList        = cellstr(ls(sprintf('%s%s*.mat', folderName, filesep)));
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end


%==========================================================================
%%                 FIRST FIND THE SMALLEST EPOCH
%==========================================================================
epochLenght = +inf;
epochLenghtP3baseline = +inf;
sampleRate = zeros(1, numel(fileList));
for iF = 1:numel(fileList)
    
    % load data
    %----------------------------------------------------------------------
    fprintf('\tloading file %d out %d\n', iF, numel(fileList));
    load( fullfile( folderName, fileList{iF}), 'block', 'fs', 'ssvepFreq' );
    
    sampleRate(iF) = fs;
    
    if ssvepFreq ~= 0
        
        % epochs onsets and offsets (in datapoints)
        %----------------------------------------------------------------------
        for iB = 1:numel(block)
            ssvepStartSamples = find( diff( block{iB}.eventChan.ssvep ) == 1 ) + 1;  % stimuli onsets
            ssvepStopSamples = find( diff( block{iB}.eventChan.ssvep ) == -1 ) + 1;  % stimuli offsets
            
            if numel(ssvepStartSamples) ~= numel(ssvepStopSamples), error('different amount of SSVEP onsets and offsets'); end
            
            rangeList = ssvepStopSamples - ssvepStartSamples + 1;
            epochLenght = min( epochLenght, min(rangeList) );
        end
    else
        
        % epochs onsets and offsets (in datapoints)
        %----------------------------------------------------------------------
        for iB = 1:numel(block)
            
            startSamples = find( diff( block{iB}.eventChan.cue ) == -1 ) + 1;  % stimuli onsets
            stopSamples = find( diff( block{iB}.eventChan.cue ) == 1 ) - 1;  % stimuli offsets
            stopSamples = [ stopSamples(2:end)  ; numel( block{iB}.eventChan.cue ) ];
            
            if numel(startSamples) ~= numel(stopSamples), error('different amount of SSVEP onsets and offsets'); end
            
            nEpochs = numel(startSamples);
            realStart = zeros(nEpochs, 1);
            realStop = zeros(nEpochs, 1);
            for i = 1:numel(startSamples)
                realStart(i) = startSamples(i) + find( diff( block{iB}.eventChan.p3(startSamples(i):stopSamples(i)) ) == 1, 1, 'first' );
                realStop(i) = startSamples(i) + find( diff( block{iB}.eventChan.p3(startSamples(i):stopSamples(i)) ) == -1, 1, 'last' );
            end
            
            rangeList = realStop - realStart + 1;
            epochLenghtP3baseline = min( epochLenghtP3baseline, min(rangeList) );
            
        end
    end
    
end

%==========================================================================
%%         THEN COMPUTE THE FFTs FOR THE SMALLEST EPOCH LENGTH
%==========================================================================

[filter.a, filter.b] = butter(4, 0.5 / (fs/2), 'high'); % high pass filter for non eog corrected data
NFFT = 2^nextpow2(epochLenght);
NFFT_P3b = 2^nextpow2(epochLenghtP3baseline);
sampleRate = unique(sampleRate);
if numel(sampleRate) ~= 1, error('not all data have the same sample rate!!!'); end


for iF = 1:numel(fileList)
    
    % load data
    %----------------------------------------------------------------------
    fprintf('\tloading file %d out %d\n', iF, numel(fileList));
    load( fullfile( folderName, fileList{iF}) );
    nChan = numel(chanList);
    
    
    % filter data (only non eog corrected, eog corrected were already filtered)
    %--------------------------------------------------------------------------
    if strcmp(eogTag, 'nonEogCorreted')
        for iB = 1:numel(block)
            for i = 1:size(block{iB}.sig, 2)
                block{iB}.sig(:,i) = filtfilt( filter.a, filter.b, block{iB}.sig(:,i) );
            end
        end
    end

    
    if ssvepFreq ~= 0
        
        % count number of epochs per block
        %--------------------------------------------------------------------------
        nEpochs = zeros(1, numel(block));
        for iB = 1:numel(block)
            ssvepStartSamples = find( diff( block{iB}.eventChan.ssvep ) == 1 ) + 1;  % stimuli onsets
            nEpochs(iB) = numel(ssvepStartSamples);
        end
        
        f = sampleRate/2*linspace(0,1,NFFT/2+1);
        ampSpec = zeros(numel(f), nChan, sum(nEpochs));
        for iB = 1:numel(block)
            
            % epochs onsets and offsets (in datapoints)
            %----------------------------------------------------------------------
            ssvepStartSamples = find( diff( block{iB}.eventChan.ssvep ) == 1 ) + 1;  % stimuli onsets
            ssvepStopSamples = find( diff( block{iB}.eventChan.ssvep ) == -1 ) + 1;  % stimuli offsets
            
            adjStartSample  = ssvepStartSamples + ceil( (ssvepStopSamples - ssvepStartSamples + 1 - epochLenght) / 2 );
            adjStopSample   = adjStartSample + epochLenght - 1;
            
            
            % build ffts of each epoch
            %----------------------------------------------------------------------
            for iE = 1:nEpochs(iB)
                iEallBlocks = iE + sum(nEpochs(1:iB-1));
                epoch = block{iB}.sig( adjStartSample(iE) : adjStopSample(iE), : );
                for iCh = 1:nChan
                    Y = fft(epoch(:, iCh), NFFT)/epochLenght;
                    ampSpec(:, iCh, iEallBlocks) = 2*abs(Y(1:NFFT/2+1));
                end
            end
            
        end
    else
        
        % count number of epochs per block
        %--------------------------------------------------------------------------
        nEpochs = zeros(1, numel(block));
        for iB = 1:numel(block)
            ssvepStartSamples = find( diff( block{iB}.eventChan.cue ) == 1 ) + 1;  % stimuli onsets
            nEpochs(iB) = numel(ssvepStartSamples);
        end
        
        f = sampleRate/2*linspace(0,1,NFFT/2+1);
        ampSpec = zeros(numel(f), nChan, sum(nEpochs));
        for iB = 1:numel(block)
            
            % epochs onsets and offsets (in datapoints)
            %----------------------------------------------------------------------
            startSamples = find( diff( block{iB}.eventChan.cue ) == -1 ) + 1;  % stimuli onsets
            stopSamples = find( diff( block{iB}.eventChan.cue ) == 1 ) - 1;  % stimuli offsets
            stopSamples = [ stopSamples(2:end)  ; numel( block{iB}.eventChan.cue ) ];
            
            realStart = zeros(nEpochs(iB), 1);
            realStop = zeros(nEpochs(iB), 1);
            for i = 1:nEpochs(iB)
                realStart(i) = startSamples(i) + find( diff( block{iB}.eventChan.p3(startSamples(i):stopSamples(i)) ) == 1, 1, 'first' );
                realStop(i) = startSamples(i) + find( diff( block{iB}.eventChan.p3(startSamples(i):stopSamples(i)) ) == -1, 1, 'last' );
            end
            
            adjStartSample  = realStart + ceil( (realStop - realStart + 1 - epochLenghtP3baseline) / 2 );
            adjStopSample   = realStart + epochLenghtP3baseline - 1;
            
            % build ffts of each epoch
            %----------------------------------------------------------------------
            for iE = 1:nEpochs(iB)
                iEallBlocks = iE + sum(nEpochs(1:iB-1));
                epoch = block{iB}.sig( adjStartSample(iE) : adjStopSample(iE), : );
                for iCh = 1:nChan
                    Y = fft(epoch(:, iCh), NFFT_P3b)/epochLenghtP3baseline;
                    ampSpec(:, iCh, iEallBlocks) = 2*abs(Y(1:NFFT_P3b/2+1));
                end
            end
            
        end % OF BLOCK FOR LOOP
        
    end % OF CONDITION ON DATA TYPE (P3 BASELINE OR NOT)

    blockNb = [];
    for iB = 1:numel(block)
        blockNb = [ blockNb ; iB*ones(nEpochs(iB), 1) ];
    end
    
    % save epochs
    %--------------------------------------------------------------------------
    fprintf('\tsaving ffts\n');
    listOfVariablesToSave = { ...
        'f', ...
        'ampSpec', ...
        'hdr', ...          % normally, not necessary
        'scenario', ...     % normally, not necessary
        'expParams', ...    % normally, not necessary
        'fs', ...
        'p3On', ...
        'ssvepFreq', ...
        'blockNb', ...
        'eogTag', ...
        'chanList' ...
        };
    
    
    clear block ampSpec hdr epoch f expParams scenario
    
end % OF FILE FOR LOOP

end