%% SSVEP detector/classifier base class
%

classdef ssvepClassifier < handle
    
    properties %(GetAccess = 'public', SetAccess = 'public')
        frequenciesList             = [10 12 15 20];
        nFrequencies                = 4;
        harmonicsList               = [1 2];
        nHarmonics                  = 2;
        nChannels                   = 8;
        windowLengthInSec           = 2;
        signalShiftsList            = [];
        nSignalShifts               = 0;
        useSignalShifts             = false;
        samplingRate                = 1000;
        nSamplesInWindow            = 2000;
        nSamplesInWindowAsDouble    = 2000;
        isTrainable                 = false;
        tag                         = 'generic';
        description                 = 'generic SSVEP classifier';
    end
    
    methods
        %-----------------------------------------------------------------------------------------------
        function obj = ssvepClassifier( varargin )

            iArg = 1;
            nParameters = numel( varargin );
            
            while ( iArg <= nParameters ),
                
                parameterName = lower( varargin{iArg} );
                parameterName(parameterName<'a') = ''; % remove non-alphabetic characters
                
                if( iArg < nParameters ),
                    parameterValue = varargin{iArg+1};
                else
                    parameterValue = [];
                end
                
                switch( parameterName ),
                    case{ 'frequencieslist', 'frequencylist', 'frequencies' },
                        if( isnumeric( parameterValue ) && all( isfinite( parameterValue ) ) && all( parameterValue > 0 ) ),
                            obj.frequenciesList = parameterValue;
                            obj.nFrequencies = numel( obj.frequenciesList );
                        else
                            error('ssvepClassifier:parseInputParameters:BadFrequenciesList', ...
                                'Invalid list of frequencies provided.');
                        end

                    case{ 'harmonicslist', 'harmoniclist', 'harmonics' },
                        if( isnumeric( parameterValue ) && all( isfinite( parameterValue ) ) && all( parameterValue > 0 ) ),
                            obj.harmonicsList = parameterValue;
                            obj.nHarmonics = numel( obj.harmonicsList );
                        else
                            error('ssvepClassifier:parseInputParameters:BadHarmonicsList', ...
                                'Invalid list of harmonics provided.');
                        end                        

                    case{ 'samplingrate', 'samplerate', 'fs' },
                        if( ( numel( parameterValue ) == 1 ) && isnumeric( parameterValue ) ...
                                && isfinite( parameterValue ) && ( parameterValue > 0 ) ),
                            obj.samplingRate = parameterValue;
                            obj.nSamplesInWindowAsDouble = obj.windowLengthInSec * obj.samplingRate;
                            obj.nSamplesInWindow = round( obj.nSamplesInWindowAsDouble );
                        else
                            error('ssvepClassifier:parseInputParameters:BadSampleRate', ...
                                'Invalid sample rate provided.');
                        end

                    case{ 'windowlengthinsec', 'windowduration', 'windowsizeinsec' },
                        if( ( numel( parameterValue ) == 1 ) && isnumeric( parameterValue ) ...
                                && isfinite( parameterValue ) && ( parameterValue > 0 ) ),
                            obj.windowLengthInSec = parameterValue;
                            obj.nSamplesInWindowAsDouble = obj.windowLengthInSec * obj.samplingRate;
                            obj.nSamplesInWindow = round( obj.nSamplesInWindowAsDouble );
                        else
                            error('ssvepClassifier:parseInputParameters:BadWindowLength', ...
                                'Invalid window duration (size in seconds) provided.');
                        end
                        
                    case{ 'nchannels', 'numberofchannels' },
                        if( ( numel( parameterValue ) == 1 ) && isnumeric( parameterValue ) ...
                                &&  isfinite( parameterValue ) && ( parameterValue > 0 ) ...
                                && ( round( parameterValue ) == parameterValue ) ),
                            obj.nChannels = parameterValue;
                        else
                            error( 'ssvepClassifier:parseInputParameters:BadNumberOfChannels', ...
                                'Invalid number of channels provided.' );
                        end
                        
                    case{ 'signalshifts', 'signalshiftlist' },
                        if( isnumeric( parameterValue ) && all( isfinite( parameterValue ) ) ),
                            obj.signalShiftsList = unique( ( parameterValue ) ); % only integer shifts
                            obj.signalShiftsList( obj.signalShiftsList == 0 ) = [];

                            obj.nSignalShifts = numel( obj.signalShiftsList );
                            obj.useSignalShifts = ( obj.nSignalShifts > 1 ) || ( ( obj.nSignalShifts == 1 ) && ( obj.signalShiftsList ~= 0 ) );
                        else
                            error( 'ssvepClassifier:parseInputParameters:BadShiftsList', ...
                                'Invalid list of shifts provided.' );
                        end                        

                        
                end  % of switch
                
                if isempty( parameterValue  ),
                    iArg = iArg + 1;
                else
                    iArg = iArg + 2;
                end
                
            end % of loop over parameter pairs
         end % of ssvepClassifier class constructor

        %-----------------------------------------------      

    end % of methods section
    %-------------------------------------------------------------------------------
    methods( Static )
        
        function normalizedSignal = normalizeSignal( signal )
            normalizedSignal = bsxfun( @minus, signal, mean( signal, 2 ) );
            for iRow = 1:size( signal, 1 )
                normalizedSignal(iRow,:) = signal(iRow,:) - mean( signal(iRow,:), 2 );
                stdOfRow = std( normalizedSignal(iRow,:) );
                if( stdOfRow < 1e-16 ),
                    warning( 'Possible signal normalizaion problem...' );
                end
                normalizedSignal(iRow,:) = normalizedSignal(iRow,:) / stdOfRow;
            end % loop over rows of matrix A
        end % of normalizeSignal function

        %-----------------------------------------------
        function centeredSignal = centerSignal( signal )
            centeredSignal = bsxfun( @minus, signal, mean( signal, 2 ) );
        end % of centerSignal() static method
        
        %-----------------------------------------------
        function shiftedX = myCircShift( x, sh )
            if( nargin < 2 ),
                sh = 1;
            end
            
            if( numel( sh ) > 1 ),
                %         warning( 'MYCIRCSHIFT:unsupportedShift', 'myCircShift() supports only shifts along second dimension' );
                sh = sh(2); % to be compatible with circshift()
            end
            absShift = abs( sh );
            f = zeros( 1, 1 + ceil( absShift ) );
            f(1) = 1 - ( ceil( absShift ) - absShift );
            if( absShift ~= 0 )
                f(2) = 1 - f(1);
            end
            if( sh < 0 ),
                shiftedX = conv( [x x(:,1:numel(f)-1)], f, 'valid' );
            else
                f = f(end:-1:1);
                shiftedX = conv( [x(:,end-numel(f)+2:end) x], f, 'valid' );
            end
            
        end % of myCircShift() method
        %-----------------------------------------------
        function shiftedSignal = shiftChannels( signal, shiftsList )
            if( numel( shiftsList ) == 0 ),
                error( 'ssvepClassifier:shiftSignal:BadShiftsList', ...
                    'Invalid list of shifts provided.' );
            end
            % adjust shiftsList vector
            shiftsList = shiftsList(:)';
            [nSignalChannels, nSignalSamples, nTrials] = size( signal );
            if( numel( shiftsList ) < nSignalChannels ),
                shiftsList = repmat( shiftsList, [1 nSignalChannels] );                
            end
            shiftsList = rem( shiftsList(1:nSignalChannels), nSignalSamples );
            shiftedSignal = signal;
            for iTr = 1:nTrials,
                for iCh = 1:nSignalChannels,
                    channelShift = shiftsList(iCh);
                    if( channelShift ~= 0 ),
%                         shiftedSignal(iCh,:,iTr) = myCircShift( shiftedSignal(iCh,:,iTr), channelShift );
                        absShift = abs( channelShift );
                        f = zeros( 1, 1 + ceil( absShift ) );
                        f(1) = 1 - ( ceil( absShift ) - absShift );
                        if( absShift ~= 0 )
                            f(2) = 1 - f(1);
                        end
                        if( channelShift < 0 ),
                            shiftedSignal(iCh,:,iTr) = conv( [shiftedSignal(iCh,:,iTr) shiftedSignal(iCh,1:numel(f)-1,iTr)], f, 'valid' );
                        else
                            f = f(end:-1:1);
                            shiftedSignal(iCh,:,iTr) = conv( [shiftedSignal(iCh,end-numel(f)+2:end,iTr) shiftedSignal(iCh,:,iTr)], f, 'valid' );
                        end                        
                    end % ( sh ~= 0 ) branch
                end % loop over the channels of the input signal
            end % loop over trials
        end % of shiftChannels() function
        
        %-----------------------------------------------
        function phases = estimateChannelPhases( signal, frequency, sampleRate )
            [nSignalChannels, nSamples, ~] = size( signal );
            phases = zeros( 1, nSignalChannels );
            
            windowTimeRange = (0:nSamples-1)' ./ sampleRate;
            windowSizeInSec = nSamples / sampleRate;
            
            windowSizeInFullPeriods    = floor( windowSizeInSec * frequency );
            windowSizeInSec            = windowSizeInFullPeriods / frequency;
            windowSizeInSamples        = round( windowSizeInSec * sampleRate );
            
            windowPhaseRange = 2*pi*frequency*windowTimeRange;

            sinVector = sin( windowPhaseRange );
            sinVector(windowSizeInSamples+1:end) = 0;
            
            cosVector = cos( windowPhaseRange );
            cosVector(windowSizeInSamples+1:end) = 0;
            
%             sinCosMatrix = [sin( windowPhaseRange ) cos( windowPhaseRange )];
%             sinCosMatrix(windowSizeInSamples+1:end,:) = 0;
            envelop = zeros( 1, nSamples );
%             envelop(1:windowSizeInSamples) = hann( windowSizeInSamples )';
            envelop(1:windowSizeInSamples) = blackman( windowSizeInSamples )';
            for iCh = 1:nSignalChannels,
                channelData = signal(iCh,:);
                channelData = channelData - mean( channelData, 2 );
                channelData = channelData .* envelop;
%                 a = channelData * sinCosMatrix;
%                 phases(iCh) = atan2( a(1), a(2) );
                phases(iCh) = atan2( channelData * sinVector, channelData * cosVector );
            end % loop over rows of matrix realignedSigmal
            
%             phases = phases - circ_mean( phases );
%             phases( phases > pi ) = phases( phases > pi ) - 2*pi;
%             phases( phases < -pi ) = phases( phases < -pi ) + 2*pi;
%             shifts = - ( phases * sampleRate / ( 2*pi*frequency) );
             
            
        end % of estimateChannelPhases() method
        
        %-----------------------------------------------
        function [newSigmal, phases, shifts] = removePhaseFromChannels( signal, frequency, sampleRate )
            phases = estimateChannelPhases( signal, frequency, sampleRate );
            shifts = - ( phases * sampleRate / ( 2*pi*frequency) );
            newSigmal = shiftChannels( signal, shifts );
        end % of removePhaseFromChannels()
        
    end % of static methods section
    
end % of ssvepClassifier class definition