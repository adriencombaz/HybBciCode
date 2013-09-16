%% SSVEP detector/classifier based on Multiset Canonical Correlation Analisys method [1].
% 
%   [1] Zhang, Y., Zhou, G., Jin, J., Wang, X., & Cichocki, A. (2013). Frequency Recognition
%       in SSVEP-based BCI using Multiset Canonical Correlation Analysis.
%       arXiv preprint, 1–7. Retrieved from http://arxiv.org/abs/1308.5609


classdef msetCcaSsvepClassifier < ssvepClassifier
    
    properties %(GetAccess = 'public', SetAccess = 'public')
        W
        Y
        invCyy
        trainAccuracy
        Iscaler = 1e-8;
    end
    
    methods        
        %-----------------------------------------------------------------------------------------------
        function obj = msetCcaSsvepClassifier( varargin )

            obj = obj@ssvepClassifier( varargin{:} ); % call the superclass constructor
            
            obj.isTrainable = true;            
            obj.tag = 'msetCCA';
            obj.description = 'SSVEP classifier based on Multiset Canonical Correlation Analisys method';
            
            % construct the reference signals as sine/cosine-waves (as in standard CCA),
            % so without training, the msetCcaSsvepClassifier is equivalent to ccaSsvepClassifier.
            
            obj.Y{1} = repmat( (0:obj.nSamplesInWindow-1)*2*pi/obj.samplingRate, [2*obj.nHarmonics 1] );
            obj.Y = repmat( obj.Y, [1 obj.nFrequencies] );
            
            for iFreq = 1:obj.nFrequencies,
                obj.Y{iFreq}(:,:) = obj.Y{iFreq} * obj.frequenciesList(iFreq);
                
                % adjust harmonic slices
                for iHarm = 1:obj.nHarmonics, % in the paper iHarm <-> k
                    obj.Y{iFreq}(2*iHarm-1:2*iHarm,:) = obj.Y{iFreq}(2*iHarm-1:2*iHarm,:) * obj.harmonicsList(iHarm);
                end
                
                % apply sin and cos
                obj.Y{iFreq}(1:2:end,:) = sin( obj.Y{iFreq}(1:2:end,:) );
                obj.Y{iFreq}(2:2:end,:) = cos( obj.Y{iFreq}(2:2:end,:) );
                
                % normalize reference signals
                obj.Y{iFreq} = obj.normalizeSignal( obj.Y{iFreq} );
                
            end
            obj.recomputeInvCyy();
            
        end % of msetCcaSsvepClassifier class constructor
        
        %-----------------------------------------------------------------------------------------------
        function recomputeInvCyy( obj )
            
            for iFreq = 1:obj.nFrequencies,
                [N, P, ~] = size( obj.Y{iFreq} );
                Cyy = obj.Y{iFreq} * obj.Y{iFreq}' / P + eye( N )*obj.Iscaler;
                obj.invCyy{iFreq} = inv( Cyy );
            end
            
        end % of method recomputeInvCyy()

        %-----------------------------------------------------------------------------------------------
        function [iWinnerClass, winnerClass, classScores] = classify( obj, inputEEGData )
            
            P = obj.nSamplesInWindow;
%             X = obj.centerSignal( inputEEGData(:,1:P) );
%             X = obj.normalizeSignal( inputEEGData(:,1:P) );
            X = inputEEGData(:,1:P);
            
            if( obj.useSignalShifts ),
                C = size( X, 1 );
                X = repmat( X, [1+obj.nSignalShifts 1] );
                for i = 1:obj.nSignalShifts,
                    X(C*i+1:C*(i+1),:) = obj.shiftChannels( X(1:C,:), obj.signalShiftsList(i) );
                end
            end
            
            C = size( X, 1 );
            Cxx = X * X' / P + eye( C ) * obj.Iscaler;
            
            classScores = zeros( 1, obj.nFrequencies );
            
            for iFreq = 1:obj.nFrequencies,
                
                Cxy = X * obj.Y{iFreq}(:,:)' / P;
                [~, R] = eig( Cxx \ Cxy * obj.invCyy{iFreq}(:,:) * Cxy' );
                classScores(iFreq) = max( sqrt( real( diag( R ) ) ) );
            end
            
            [~, iWinnerClass] = max( classScores );
            winnerClass = obj.frequenciesList( iWinnerClass );

        end % of method classify()

        %-----------------------------------------------------------------------------------------------
        function accuracy = train( obj, trainData, trainLabels )
            
            uniqueLabels = unique( trainLabels );
            % M - number of classes (frequencies to recognize)
            M = numel( uniqueLabels );
            
            % C - number of channels
            % P - number of samples (in the classification window)
            % nWindows - total number of trials (training samples)
            [C, P, nTrainWindows, ~] = size( trainData );
            
            % sanity checks
            assert( P == obj.nSamplesInWindow );            
            assert( C == obj.nChannels );
            assert( nTrainWindows == numel( trainLabels ) );
            assert( M == obj.nFrequencies );
            
            X = trainData;
%             X = zeros( C, P, nTrainWindows );
%             for i = 1:nTrainWindows,
%                 X(:,:,i) = obj.normalizeSignal( trainData(:,:,i) );
%             end % loop over trials
            
%             % normalize train data
%             for i = 1:nTrainWindows,
%                 X(:,:,i) = obj.normalizeSignal( trainData(:,:,i) );
%             end % loop over trials

%             % center train data
%             for i = 1:nTrainWindows,
%                 X(:,:,i) = obj.centerSignal( trainData(:,:,i) );
%             end % loop over trials
            
            % reset array of canonical variates (CVs)
            obj.Y = cell( 1, M );
            
            % reset array of spatial filters w
            obj.W = cell( 1, M );
            littleI = eye( C ) * obj.Iscaler;
            for iClass = 1:M,
                classLabel = uniqueLabels(iClass);  % current class label
                classIndices = find( trainLabels == classLabel ); % indices of current class trials
                N = numel( classIndices );  % number of training trials the in current class
                
                % allocate some memory
                RminusS = zeros( N*C, N*C );
                S = RminusS;
                
                for i = 1:N,                    
                    iTr = classIndices(i);
                    Cii = X(:,:,iTr) * X(:,:,iTr)' / P  + littleI; % Xi*Xi'
                    
                    iFirst = C*(i-1) + 1;
                    iLast = C*i;
                    
                    S(iFirst:iLast,iFirst:iLast) = Cii;
                    
                    for j = i+1:N,
                        jTr = classIndices(j);                        
                        Cij = X(:,:,iTr) * X(:,:,jTr)' / P; % Xi*Xj'
                        
                        jFirst = C*(j-1) + 1;
                        jLast = C*j;

                        RminusS(iFirst:iLast,jFirst:jLast) = Cij;
                        RminusS(jFirst:jLast,iFirst:iLast) = Cij';
                    end % j-loop                    
                end % i-loop
                
                [V, D] = eig( RminusS, S );
                [~, iMaxRho] = max( diag( D ) );

                w = V(:,iMaxRho);  % as one big column-vector
                obj.W{iClass} = reshape( w, [C, N] ); % as a matrix with column-vectors wi
                
                % compute reference signal matrix Ym for the current class (m=iClass)
                Ym = zeros( N, P );  % nClassTrials x nSamplesInWindow
                for i = 1:N,                    
                    iTr = classIndices(i);
                    w_im = obj.W{iClass}(:,i);
                    Ym(i,:) = w_im' * X(:,:,iTr);  % z_im -> Ym(i,:)
                end % of loop over class trials (i)
                obj.Y{iClass} = obj.normalizeSignal( Ym );

            end % of loop over classes/frequencies (iClass)
            
            obj.recomputeInvCyy();
            
            if( nargout > 0 ),
                % evaluate classifier on training data
                nTP = 0;
                for iWin = 1:nTrainWindows,
                    if( trainLabels(iWin) == obj.classify( X(:,:,iWin) ) )
                        nTP = nTP + 1;
                    end
                end % loop over trials
                accuracy = nTP / nTrainWindows;
                obj.trainAccuracy = accuracy;
            end
            
        end % of method train()
        
        
    end % of methods section
    
end % of ccaSsvepClassifier class definition