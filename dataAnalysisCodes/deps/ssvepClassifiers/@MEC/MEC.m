%% SSVEP detector/classifier based on Minimum Noise Energy Combination (MNEC) spatial filtering
% 
%   [1] O. Friman, I. Volosyak, and A. Graser, "Multiple channel detection of
%       steady-state visual evoked potentials for brain-computer interfaces",
%       Biomedical Engineering, IEEE Transactions on, vol. 54, no. 4, pp. 742–750,
%       2007. 

classdef MEC
    
    properties %(GetAccess = 'public', SetAccess = 'public')
        frequenciesList         = [10 12 15 20];
        nFrequencies
        harmonicsList           = 1;
        nHarmonics
        nChannels               = 8;
        nCombinations
        nSamplesInSubWindow     = 2000;
        nFFT                    = 1000;
        AR_parameter            = 20;
        Y
        X
        SSVEPRemovalMatrix
        samplingRate            = 1000;
        rangeSubWindow
        frequenciesToRemoveList
        nFrequenciesToRemove
        eigValThreshold         = 1e-12;
    end
    
    methods        
        %-----------------------------------------------------------------------------------------------
        function obj = MEC( inpFrequenciesList, inpSamplingRate, inpHarmonicsList, inpNSamplesInSubWindow, inpNFFT, inpARparameter )

            if( nargin > 0 ), %exist( 'frequenciesList', 'var' ) && ~isempty( inpFrequenciesList ) ),
                obj.frequenciesList = inpFrequenciesList;
            end
            
            obj.nFrequencies = numel( obj.frequenciesList );

            if( nargin > 1 ), %exist( 'samplingRate', 'var' ) && ~isempty( inpSamplingRate ) ),
                obj.samplingRate = inpSamplingRate;
            end
            
            if( nargin > 2 ), %exist( 'harmonicsList', 'var' ) && ~isempty( inpHarmonicsList ) ),
                obj.harmonicsList = inpHarmonicsList;
            end
            obj.nHarmonics = numel( obj.harmonicsList );
            
            if( nargin > 3 ), % exist( 'nSamplesInSubWindow', 'var' ) && ~isempty( inpNSamplesInSubWindow ) ),
                obj.nSamplesInSubWindow = inpNSamplesInSubWindow;
            end
            
            if( nargin > 4 ), % exist( 'nFFT', 'var' ) && ~isempty( inpNFFT ) ),
                obj.nFFT = inpNFFT;
            end
            
            if( nargin > 5 ), % exist( 'AR_parameter', 'var' ) && ~isempty( inpARparameter ) ),
                obj.AR_parameter = inpARparameter;
            end
            
            
            %% Prepare mixing martrix for SSVEP component removal
            temp = obj.frequenciesList(:) * obj.harmonicsList(:)';
            obj.frequenciesToRemoveList = unique( temp(:) );
            obj.nFrequenciesToRemove    = numel( obj.frequenciesToRemoveList );
            obj.rangeSubWindow          = 0:obj.nSamplesInSubWindow-1;

            Zp = zeros( obj.nSamplesInSubWindow, 2*obj.nFrequenciesToRemove );
            for iFreq = 1:obj.nFrequenciesToRemove,
                Zp(:,2*iFreq-1)  = sin( obj.frequenciesToRemoveList(iFreq) * 2*pi*obj.rangeSubWindow'/obj.samplingRate );
                Zp(:,2*iFreq)    = cos( obj.frequenciesToRemoveList(iFreq) * 2*pi*obj.rangeSubWindow'/obj.samplingRate );
            end
    
%             invSqZp = invertRealSymmetricMatrix( Zp'*Zp );
%             v = invSqZp * Zp(1,:)';
%             r = -Zp * v;
%             r(1) = r(1) + 1;
%             obj.SSVEPRemovalMatrix = toeplitz( r );
            obj.SSVEPRemovalMatrix = eye( obj.nSamplesInSubWindow ) - ( Zp * invertRealSymmetricMatrix( Zp'*Zp ) * Zp' );

 
            %% Prepare matrix X for signal power [Pxx] estimation
            % In the paper only one frequency f is considered.
            % We consider several [nFrequencies] frequenciesList,  and therefore our
            % matrix X has one more dimension - the frequency dimension.
            
            % construct an initial matrix as a replication of the window time-interval
            obj.X = repmat( obj.rangeSubWindow'*2*pi/obj.samplingRate, [1 2 obj.nHarmonics obj.nFrequencies] );
            
            % adjust frequency slices
            for iFreq = 1:obj.nFrequencies, % in the paper iFreq = 1
                obj.X(:,:,:,iFreq) = obj.X(:,:,:,iFreq) * obj.frequenciesList(iFreq);
            end
            
            % adjust harmonic slices
            for iHarm = 1:obj.nHarmonics, % in the paper iHarm <-> k
                obj.X(:,:,iHarm,:) = obj.X(:,:,iHarm,:) * obj.harmonicsList(iHarm);
            end
            
            % apply sin and cos
            obj.X(:,1,:,:) = sin( obj.X(:,1,:,:) );
            obj.X(:,2,:,:) = cos( obj.X(:,2,:,:) );
            
        end % of MEC class constructor

        %-----------------------------------------------------------------------------------------------
        function [SNRs, Ns] = getSNRs( obj, inputEEGData )
            if( nargin > 1 ),
                obj.Y = inputEEGData;
            end
                        
            obj.nChannels = size( obj.Y, 1 );
            [W, Ns] = obj.getSpatialFilter();
            
            % compute S - matrix of combinations (referred also as "channels" in the paper)
            S = W' * obj.Y;

            %% Estimate power of the signal S
            P = zeros( obj.nHarmonics, Ns, obj.nFrequencies );
            for iFreq = 1:obj.nFrequencies, % in the paper iFreq doesn't exist
                for iComb = 1:Ns, % in the paper iComb <-> l
                    for iHarm = 1:obj.nHarmonics, % in the paper iHarm <-> k
                        P(iHarm,iComb,iFreq) = norm( S(iComb,:) * obj.X(:,:,iHarm,iFreq) );
                    end % of loop over harmonicsList                     
                end % of loop over combinations (or "channels")
            end % of loop over frequenciesList
            P = P .^ 2;

            %% Estimate noise
            tildeS = S * obj.SSVEPRemovalMatrix;

            nPxxRows = ceil( (obj.nFFT+1) / 2 );
            Pxx = zeros( nPxxRows, Ns );

            for iComb = 1:Ns,
                pxx = myPyulear( tildeS(iComb,:), obj.AR_parameter, obj.nFFT );
                Pxx(:,iComb) = pxx(1:nPxxRows);
            end % of loop over combinations (or "channels")

            sigma = zeros( obj.nHarmonics, Ns, obj.nFrequencies );
            div = obj.samplingRate / obj.nFFT;

            for iFreq = 1:obj.nFrequencies, % loop over all frequenciesList
                for iComb = 1:Ns,           % loop over the signals in S
                    for iHarm =1:obj.nHarmonics,    % loop over the harmonicsList of the frequenciesList
                        ind = round( obj.frequenciesList(iFreq) * obj.harmonicsList(iHarm) / div );
                        sigma(iHarm,iComb,iFreq) = mean( Pxx(max(1,ind-1):min(ind+1,nPxxRows),iComb) );
                    end % of loop over harmonicsList
                end % of loop over combinations (channels in S)
            end % of loop over frequenciesList

            % Estimate SNRs
            SNRs = reshape( P ./ sigma, [obj.nHarmonics*Ns obj.nFrequencies] );
            
        end % of method GETSNRS

        %-----------------------------------------------------------------------------------------------
        function [W, Ns, S] = getSpatialFilter( obj, inputEEGData )
            if( nargin > 1 ),
                obj.Y = inputEEGData;
            end
                        
            obj.nChannels = size( obj.Y, 1 );

            %% Remove SSVEP from the signal
            tildaY = obj.Y * obj.SSVEPRemovalMatrix;

            %% Get eigenvalues and eigenvectors?
            [eigVecs, eigVals] = eig( tildaY * tildaY' );
            
            eigVecs = real( eigVecs );
            eigVals = real( diag( eigVals ) );            
            eigVals(abs( eigVals ) < obj.eigValThreshold) = obj.eigValThreshold;
            eigValsCumSum = cumsum( eigVals );
            eigValsCumSum = eigValsCumSum / eigValsCumSum(obj.nChannels);

            %% Select the "optimal" number [N_s] of combinations 
            Ns = 1;
            while( eigValsCumSum(Ns) < 0.1 ),
                Ns = Ns + 1;
            end
            
            obj.nCombinations = Ns;
%             Ns = obj.nChannels; % WTF????

            %% Construct the weight matrix [W]
            W = zeros( obj.nChannels, Ns );
            for iComb = 1:Ns,
%                 W(:,iComb) = eigVecs(:,iComb) ./ sqrt( eigVals(iComb) );
                W(:,iComb) = eigVecs(:,iComb); % ./ sqrt( eigVals(iComb) );
            end % of loop over combinations (or "channels")
%             W = W ./ norm( W );
            
            W( isnan(W) ) = 0; % rude hack to eliminate NaNs
            
            if( nargout > 2 ),
                % compute S - matrix of combinations (referred also as "channels" in the paper)
                S = W' * obj.Y;
            end
            
        end % of GETSPATIALFILTER method

        %-----------------------------------------------------------------------------------------------
        function [iWinnerClass, winnerClass, classScores, SNRs] = classify( obj, inputEEGData, weights )

            SNRs = obj.getSNRs( inputEEGData );
            nSNRs = size( SNRs, 1 );
            
            if( nargin < 3 ), %~exist( 'weights', 'var' ) || ~isempty( weights ) ),
                % use averaging instead of weighting 
                weights = ones( 1, nSNRs ) / nSNRs;
            else
                if( numel( weights ) > nSNRs ),
                    weights = weights(1:nSNRs);
                else
                    error( 'Inconsistent weight vector size' )
                end
            end

            T = weights(:)' * SNRs;
            [maxT, iWinnerClass] = max( T );
            
            classScores = T / maxT;            
            winnerClass = obj.frequenciesList( iWinnerClass );
            
        end % of method classify
    
    end % of methods section
    
end % of MNEC class definition