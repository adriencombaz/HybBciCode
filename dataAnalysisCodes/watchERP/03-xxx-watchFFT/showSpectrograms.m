function showSpectrograms( dataFileName )
    
    MAX_SUBPLOTS_IN_COLUMN = 8;
    MIN_FREQ = 0;
    MAX_FREQ = 48;
    OVERLAP_RATIO = 0.7;
    
    if( ischar( dataFileName ) && exist( dataFileName, 'file' ) ),
        [~, ~, dataFileExtension] = fileparts( dataFileName );
    end

    switch lower( dataFileExtension ),
        case '.mat',
            data = load( dataFileName );
            if( isfield( data, 'EEG' ) ),
                dataToPlot = data.EEG;
            end
            [nEegChannels, nSamples, ~] = size( dataToPlot );
            
            if( isfield( data, 'eegDeviceSampleRate' ) ),
                dataSamplerate = data.eegDeviceSampleRate;
            elseif( isfield( data, 'eegRecordingStartTime' ) && isfield( data, 'eegRecordingStopTime' ) ),
                dataSamplerate = nSamples / ( data.eegRecordingStopTime - data.eegRecordingStartTime );
            elseif( isfield( data, 'actualFullStimulationDuration' ) ),
                dataSamplerate = nSamples / ( data.actualFullStimulationDuration );
            end

            if( isfield( data, 'stimulusFrequencies' ) ),
                stimulationFrequenciesList = unique( data.stimulusFrequencies(:) );
            elseif( isfield( data, 'frequencyList' ) ),
                stimulationFrequenciesList = unique( data.frequencyList(:) );
            elseif( isfield( data, 'frequencies' ) ),
                stimulationFrequenciesList = unique( data.frequencies(:) );
            end
            eegChannelNamesList = cellfun( ...
                @(x) sprintf( 'ch%g', x ), ...
                num2cell( 1:nEegChannels ), ...
                'UniformOutput', false );

            minFreq = max( MIN_FREQ, min( stimulationFrequenciesList ) - 1 );
            maxFreq = min( MAX_FREQ, 2*max( stimulationFrequenciesList ) + 1 );

        case '.bdf',
            [data, header] = sload( dataFileName );
            dataSamplerate = header.SampleRate;
            nChannels = size( data, 2 );
            channelNamesList = header.Label;
            eegChannelIndicesList = zeros( 1, nChannels );
            nEegChannels = 0;
            for iCh = 1:nChannels,
                if(    ( ( channelNamesList{iCh}(1) == 'E' ) && ( channelNamesList{iCh}(2) == 'X' )  ) ...     EX? channel
                    || ( ( channelNamesList{iCh}(1) == 'S' ) && ( channelNamesList{iCh}(2) == 't' )  )  ), ... Status channel
                    continue; % drop this channel
                end
                nEegChannels = nEegChannels + 1;
                eegChannelIndicesList(nEegChannels) = iCh;
            end
            eegChannelIndicesList = eegChannelIndicesList(1:nEegChannels);
            dataToPlot = data(:,eegChannelIndicesList)';
            eegChannelNamesList = channelNamesList(eegChannelIndicesList);
            minFreq = MIN_FREQ+1;
            maxFreq = MAX_FREQ-1;
    end
            
    
    
    
%     stimulationFrequenciesList
    
    
    nFFT = round( dataSamplerate );
    windowLen = nFFT;
    nOverlap = ceil( windowLen * OVERLAP_RATIO );
    
    
    % Set up number of subplot rows and columns (maximal amount of subplot rows is set to MAX_CHANNELS_IN_COLUMN)
    nSbplCols = ceil( nEegChannels / MAX_SUBPLOTS_IN_COLUMN );
    nSbplRows = ceil( nEegChannels / nSbplCols );
    
    figure();
    
    for iCh = 1:nEegChannels,
        subplot( nSbplRows, nSbplCols, iCh );
        cla();
        spectrogram( ...
            dataToPlot(iCh,:), ...  data
            windowLen, ...          windowLength is a Hamming window of length nFFT.
            nOverlap, ...           nOverlap is the number of samples that each segment overlaps. The default value is the number producing 50% overlap between segments.
            nFFT, ...               nFFT is the FFT length and is the maximum of 256 or the next power of 2 greater than the length of each segment of x. (Instead of nfft, you can specify a vector of frequencies, F. See below for more information.)
            dataSamplerate, ...     Fs is the sampling frequency, which defaults to normalized frequency.
            'yaxis' ...
            );
        ylim( [minFreq maxFreq] );
        xlabel( '' );
        ylabel( eegChannelNamesList{iCh} );
        drawnow();
    end

end % of showSpectrograms function