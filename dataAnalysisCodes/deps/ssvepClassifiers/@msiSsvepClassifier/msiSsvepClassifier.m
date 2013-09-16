%% SSVEP detector/classifier based on Multivariate Synchronization Index (MSI) method
% 
%   [1] Zhang, Y., Xu, P., Cheng, K., & Yao, D. (2013). Multivariate Synchronization
%       Index for Frequency Recognition of SSVEP-based Brain-computer Interface.
%       Journal of neuroscience methods, 1–9. doi:10.1016/j.jneumeth.2013.07.018

classdef msiSsvepClassifier < ssvepClassifier
    
    properties %(GetAccess = 'public', SetAccess = 'public')
        Y
        C22invSqrt
        eigValThreshold         = 1e-12;
    end
    
    methods        
        %-----------------------------------------------------------------------------------------------
        function obj = msiSsvepClassifier( varargin )

            obj = obj@ssvepClassifier( varargin{:} ); % call the superclass constructor

            obj.tag = 'MSI';
            obj.description = 'SSVEP classifier based on Multivariate Synchronization Index method';
             
            
            % construct an initial matrix as a replication of the window time-interval
            obj.Y = repmat( (0:obj.nSamplesInWindow-1)*2*pi/obj.samplingRate, [2*obj.nHarmonics 1 obj.nFrequencies] );
            
            % adjust frequency slices
            for iFreq = 1:obj.nFrequencies, % in the paper iFreq = 1
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
            
           % Compute C22 for each frequency
            for iFreq = 1:obj.nFrequencies, % in the paper iFreq = 1
                C22 = obj.Y(:,:,iFreq) * obj.Y(:,:,iFreq)' / obj.nSamplesInWindow;
                obj.C22invSqrt(:,:,iFreq) = C22 ^ (-1/2);
            end
            
        end % of MSI class constructor
        
        %-----------------------------------------------------------------------------------------------
        function [iWinnerClass, winnerClass, classScores] = classify( obj, inputEEGData )
            
            N = size( inputEEGData, 1 );  % number of EEG channels
            M = size( inputEEGData, 2 );
            assert( M == obj.nSamplesInWindow );
            P = N + 2*obj.nHarmonics;
            
            X = obj.normalizeSignal( inputEEGData );
            C11 = X * X' / M;
            C11invSqrt = C11^(-1/2);
            classScores = zeros( 1, obj.nFrequencies );
            for iFreq = 1:obj.nFrequencies,
                C12 = X * obj.Y(:,:,iFreq)' / M;
                R = [ eye( N ),                                 C11invSqrt*C12*obj.C22invSqrt(:,:,iFreq);
                      obj.C22invSqrt(:,:,iFreq)*C12'*C11invSqrt, eye( 2*obj.nHarmonics )                  ];
                eigVals = eig( R );
                eigVals( eigVals < obj.eigValThreshold ) = obj.eigValThreshold;
                eigVals = eigVals / sum( eigVals );
                classScores(iFreq) = 1 + sum( eigVals .* log( eigVals ) ) / log( P );
            end
            
            [~, iWinnerClass] = max( classScores );           
            winnerClass = obj.frequenciesList( iWinnerClass );
            
        end % of method classify
    
    end % of methods section
    
end % of MSI class definition