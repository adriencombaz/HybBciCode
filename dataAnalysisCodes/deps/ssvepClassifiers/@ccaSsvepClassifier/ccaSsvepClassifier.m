%% SSVEP detector/classifier based on Canonical Correlation Analisys method
% 
%   [1] Lin, Z., Zhang, C., Wu, W., & Gao, X. (2006). Frequency recognition based on
%       canonical correlation analysis for SSVEP-based BCIs.
%       IEEE transactions on bio-medical engineering, 54(6 Pt 2), 1172–6. doi:10.1109/TBME.2006.886577

classdef ccaSsvepClassifier < ssvepClassifier
    
    properties %(GetAccess = 'public', SetAccess = 'public')
        Y
        invCyy
    end
    
    methods        
        %-----------------------------------------------------------------------------------------------
        function obj = ccaSsvepClassifier( varargin )

            obj = obj@ssvepClassifier( varargin{:} ); % call the superclass constructor
            obj.tag         = 'CCA';
            obj.description = 'SSVEP classifier based on Canonical Correlation Analisys method';

            
            % construct an initial matrix as a replication of the window time-interval
            obj.Y = repmat( (0:obj.nSamplesInWindow-1)*2*pi/obj.samplingRate, [2*obj.nHarmonics 1 obj.nFrequencies] );
            
            % adjust frequency slices
            for iFreq = 1:obj.nFrequencies,
                obj.Y(:,:,iFreq) = obj.Y(:,:,iFreq) * obj.frequenciesList(iFreq);
            end
            
            % adjust harmonic slices
            for iHarm = 1:obj.nHarmonics, % in the paper iHarm <-> k
                obj.Y(2*iHarm-1:2*iHarm,:,:) = obj.Y(2*iHarm-1:2*iHarm,:,:) * obj.harmonicsList(iHarm);
            end
            
            % apply sin and cos
            obj.Y(1:2:end,:,:) = sin( obj.Y(1:2:end,:,:) );
            obj.Y(2:2:end,:,:) = cos( obj.Y(2:2:end,:,:) );
            
            % normalizeSignal
            for iFreq = 1:obj.nFrequencies, % in the paper iFreq = 1
                obj.Y(:,:,iFreq) = obj.normalizeSignal( obj.Y(:,:,iFreq) );
            end
            
            N = size( obj.Y, 1 );
            % Compute Cyy for each frequency
            for iFreq = 1:obj.nFrequencies, % in the paper iFreq = 1
                Cyy = obj.Y(:,:,iFreq) * obj.Y(:,:,iFreq)' / obj.nSamplesInWindow + eye( N )./1e8;  
                obj.invCyy(:,:,iFreq) = inv( Cyy );
            end
            
        end % of ccaSsvepClassifier class constructor
        
        %-----------------------------------------------------------------------------------------------
        function [iWinnerClass, winnerClass, classScores] = classify( obj, inputEEGData )
            
%             M = size( inputEEGData, 2 );
%             assert( M == obj.nSamplesInWindow );
            M = obj.nSamplesInWindow;
            X = inputEEGData(:,1:M);
            X = obj.normalizeSignal( X );
            if( obj.useSignalShifts ),
                N = size( X, 1 );
                X = repmat( X, [1+obj.nSignalShifts 1] );
                for i = 1:obj.nSignalShifts,
%                     X(N*i+1:N*(i+1),:) = circshift( X(1:N,:), [0 obj.shiftsList(i)] );
                    X(N*i+1:N*(i+1),:) = obj.shiftChannels( X(1:N,:), obj.signalShiftsList(i) );
                end
            end

            N = size( X, 1 );
            Cxx = X * X' / M + eye( N ) * 1e-8;
            
            classScores = zeros( 1, obj.nFrequencies );
            
            for iFreq = 1:obj.nFrequencies,
%                 frequency = obj.frequenciesList(iFreq);
%                 %                 [XX, shifts, phases] = obj.removeMeanPhase( inputEEGData, obj.frequenciesList(iFreq), obj.samplingRate );
%                 phases = obj.estimateChannelPhases( X, frequency, obj.samplingRate );
%                 shifts = - ( phases * obj.samplingRate / ( 2*pi*frequency) );
%                 XX = obj.shiftChannels( X, shifts );
%                 
%                 Cxx = XX * XX' / M + eye( N ) / 1e8;
%                 Cxy = XX * obj.Y(:,:,iFreq)' / M;
                
                Cxy = X * obj.Y(:,:,iFreq)' / M;
                [~, R] = eig( Cxx \ Cxy * obj.invCyy(:,:,iFreq) * Cxy' );
                classScores(iFreq) = max( sqrt( real( diag( R ) ) ) );
            end
            
            [~, iWinnerClass] = max( classScores );
            winnerClass = obj.frequenciesList( iWinnerClass );

        end % of method classify
    
    end % of methods section
    
end % of ccaSsvepClassifier class definition