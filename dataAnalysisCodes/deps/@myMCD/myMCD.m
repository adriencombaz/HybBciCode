classdef myMCD
    %MCD
    
    properties %(GetAccess = 'public', SetAccess = 'public')
        frequencies             = [10 12 15 20];
        nFrequencies
        harmonics               = [1 2 3];
        nHarmonics
        nChannels               = 8;
        nCombinations
        nSamplesInSubWindow     = 2000;
        nFFT                    = 1000;
        AR_parameter            = 20;
        Y
        X
        M
        SSVEPRemovalMatrix
        samplingRate            = 1000;
        rangeSubWindow
        frequenciesToRemove
        nFrequenciesToRemove
    end
    
    methods        
        function obj = myMCD( frequencies, samplingRate, harmonics, nSamplesInSubWindow, nFFT, AR_parameter )            
            if exist( 'frequencies', 'var' ) && ~isempty( frequencies ),
                obj.frequencies = frequencies;
            end
            obj.nFrequencies = numel( obj.frequencies );

            if exist( 'samplingRate', 'var' ) && ~isempty( samplingRate ),
                obj.samplingRate = samplingRate;
            end
            
            if exist( 'harmonics', 'var' ) && ~isempty( harmonics ),
                obj.harmonics = harmonics;
            end
            obj.nHarmonics = numel( obj.harmonics );
            
            if exist( 'nSamplesInSubWindow', 'var' ) && ~isempty( nSamplesInSubWindow ),
                obj.nSamplesInSubWindow = nSamplesInSubWindow;
            end
            
            if exist( 'nFFT', 'var' ) && ~isempty( nFFT ),
                obj.nFFT = nFFT;
            end
            
            if exist( 'AR_parameter', 'var' ) && ~isempty( AR_parameter ),
                obj.AR_parameter = AR_parameter;
            end
            
            %% Prepare mixing martrix for SSVEP component removal
            obj.frequenciesToRemove     = obj.frequencies' * obj.harmonics;
            obj.frequenciesToRemove     = unique( obj.frequenciesToRemove(:) );
            obj.nFrequenciesToRemove    = numel( obj.frequenciesToRemove );
            obj.rangeSubWindow          = 1:obj.nSamplesInSubWindow;

            Zp = zeros( obj.nSamplesInSubWindow, 2*obj.nFrequenciesToRemove );
            for iFreq = 1:obj.nFrequenciesToRemove,
                Zp(:,2*iFreq-1)  = sin( obj.frequenciesToRemove(iFreq) * 2*pi*obj.rangeSubWindow'/obj.samplingRate );
                Zp(:,2*iFreq)    = cos( obj.frequenciesToRemove(iFreq) * 2*pi*obj.rangeSubWindow'/obj.samplingRate );
            end
    
            obj.M = Zp * (inv(Zp'*Zp)) * Zp';
            obj.SSVEPRemovalMatrix = ( eye(obj.nSamplesInSubWindow) - obj.M)';
            
            %% Prepare martrix X for signal power [Pxx] estimation
            % In the paper only one frequency f is considered.
            % We consider several [nFrequencies] frequencies,  and therefore our
            % matrix X has one more dimension - the frequency dimension.
            
            % construct initial matrix as a replication of the window time-interval
            obj.X = repmat( obj.rangeSubWindow'*2*pi/obj.samplingRate, [1 2 obj.nHarmonics obj.nFrequencies] );
            
            % adjust frequency slices
            for iFreq = 1:obj.nFrequencies, % in the paper iFreq = 1
                obj.X(:,:,:,iFreq) = obj.X(:,:,:,iFreq) * obj.frequencies(iFreq);
            end
            
            % adjust harmonic slices
            for iHarm = 1:obj.nHarmonics, % in the paper iHarm <-> k
                obj.X(:,:,iHarm,:) = obj.X(:,:,iHarm,:) * obj.harmonics(iHarm);
            end
            % apply sin and cos
            obj.X(:,1,:,:) = sin( obj.X(:,1,:,:) );
            obj.X(:,2,:,:) = cos( obj.X(:,2,:,:) );
            
        end % of MCD class constructor

        function [SNRs Ns] = getSNRs( obj, inputEEGData )
            if nargin > 1,
                obj.Y = inputEEGData;
            end
           
            obj.nChannels = size( obj.Y, 1 );

            %% remove SSVEP from the signal
            tildaY = obj.Y * obj.SSVEPRemovalMatrix;

            % get eigenvalues and eigenvectors
            [eigvec eigval] = eig( tildaY * tildaY' );
            
%             eigval(abs( eigval ) < 1e-10) = 0;
            eigval(abs( eigval ) < 1e-9) = 0;
            sumeigval = sum( eigval(:) );
            eigvalratio = eigval(1) / sumeigval;

            %% Select the "optimal" number [N_s] of combinations 
            Ns = 1;
            while eigvalratio < 0.1
                Ns = Ns + 1;
                eigvalratio = sum( sum( eigval(1:Ns,1:Ns) ) ) / sumeigval;  % ?????
            end
            obj.nCombinations = Ns;
            Ns = obj.nChannels;

            %% Construct the weight matrix [W]
            W = zeros( obj.nChannels, Ns );
%             keyboard
            for iComb = 1:Ns,
                W(:,iComb) = eigvec(:,iComb) ./ sqrt( eigval(iComb,iComb) );
            end % of loop over combinations (or "channels")
            W = W ./ norm( W );

            % compute S - matrix of combinations (referred also as "channels" in the paper)
            S = W' * obj.Y;

            %% Estimate power of the signal S
            P = zeros( obj.nHarmonics, Ns, obj.nFrequencies );
            for iFreq = 1:obj.nFrequencies, % in the paper iFreq doesn't exist
                for iComb = 1:Ns, % in the paper iComb <-> l
                    for iHarm = 1:obj.nHarmonics, % in the paper iHarm <-> k
                        P(iHarm,iComb,iFreq) = norm( S(iComb,:) * obj.X(:,:,iHarm,iFreq) );
                    end % of loop over harmonics                     
                end % of loop over combinations (or "channels")
            end % of loop over frequencies
            P = P .^ 2;


            %% Estimate noise
            tildeS = S * obj.SSVEPRemovalMatrix;

            Pxx = zeros( ceil( (obj.nFFT+1) / 2 ), Ns );
            for iComb = 1:Ns,
                Pxx(:,iComb) = pyulear( tildeS(iComb,:), obj.AR_parameter, obj.nFFT );
            end % of loop over combinations (or "channels")

            sigma = zeros( obj.nHarmonics, Ns, obj.nFrequencies );
            div = obj.samplingRate / obj.nFFT;

            for iFreq = 1:obj.nFrequencies, % loop over all frequencies
                for iComb = 1:Ns,           % loop over the signals in S
                    for iHarm =1:obj.nHarmonics,    % loop over the harmonics of the frequencies
                        ind = round( obj.frequencies(iFreq) * obj.harmonics(iHarm) / div );
                        sigma(iHarm,iComb,iFreq) = mean( Pxx(ind-1:ind+1,iComb) );
                    end % of loop over harmonics
                end % of loop over combinations (channels in S)
            end % of loop over frequencies

            % Estimate SNRs
            SNRs = reshape( P ./ sigma, [obj.nHarmonics*Ns obj.nFrequencies] );
            
        end % of method GETSNRS
        %-----------------------------------------------------------------------------------------------
        
        function [iWinnerClass winnerClass classScores SNRs powers] = classify( obj, inputEEGData, weights )

            SNRs = obj.getSNRs( inputEEGData );
            nSNRs = size( SNRs, 1 );
            if ~exist( 'weights', 'var' ) || ~isempty( weights ),
                % use means as weights
                weights = ones( 1, nSNRs ) / nSNRs;
            else
                if numel( weights ) > nSNRs,
                    weights = weights(1:nSNRs);
                else
                    error( 'inconsistent weight vector size' )
                end
            end

            T = weights(:)' * SNRs;
            [maxT iWinnerClass] = max( T );
            
            classScores = T / maxT;            
            winnerClass = obj.frequencies( iWinnerClass );            
            
        end % of method classify

    
    end % of methods section
    
end % of MCD class definition