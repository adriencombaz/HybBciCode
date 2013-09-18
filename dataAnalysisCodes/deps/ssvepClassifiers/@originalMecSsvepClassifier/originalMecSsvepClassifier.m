%% SSVEP detector/classifier based on Minimum Energy Combination (MEC) spatial filtering.
%  The 'original' version: the SSVEP removal matrix, spatial filter and the final score
%  are computed independatly of each other.
%
%   [1] O. Friman, I. Volosyak, and A. Graser, "Multiple channel detection of
%       steady-state visual evoked potentials for brain-computer interfaces",
%       Biomedical Engineering, IEEE Transactions on, vol. 54, no. 4, pp. 742–750,
%       2007.

classdef originalMecSsvepClassifier < ssvepClassifier
    
    properties %(GetAccess = 'public', SetAccess = 'public')
        nCombinations
        nFFT                    = 1000;
        arParameter             = 20;
        Y
        X
        SSVEPRemovalMatrix
        rangeSubWindow
        frequenciesToRemoveList
        nFrequenciesToRemove
        eigValThreshold         = 1e-12;
        mecClassifiers
    end
    
    methods
        %-----------------------------------------------------------------------------------------------
        function obj = originalMecSsvepClassifier( varargin )
            
            obj = obj@ssvepClassifier( varargin{:} ); % call the superclass constructor
            obj.tag = 'originalMEC';
            obj.description = 'SSVEP classifier based on Minimum Energy Combination spatial filtering (original version)';
            
            if( numel( varargin ) > 0 )
                obj.parseInputParameters( varargin{:} ); % parse parameters specific for the MEC classifier
            end
            obj.mecClassifiers = cell( 1, obj.nFrequencies );
            for iFreq = 1:obj.nFrequencies,
                newFrequencyList = obj.frequenciesList(iFreq);
                obj.mecClassifiers{iFreq} = mecSsvepClassifier( ...
                    'frequenciesList',  newFrequencyList, ...
                    'nChannels',        obj.nChannels, ...
                    'sampleRate',       obj.samplingRate, ...
                    'harmonicsList',    obj.harmonicsList, ...
                    'nFFT',             obj.nFFT, ...
                    'arParameter',      obj.arParameter, ...
                    'windowSizeInSec',  obj.windowLengthInSec );

            end
            
        end % of MEC class constructor
        
        %-----------------------------------------------------------------------------------------------
        function [SNRs, Ns] = getSNRs( obj, inputEEGData )
            if( nargin > 1 ),
                obj.Y = inputEEGData;
            end
            SNRs = cell( obj.nFrequencies, 1 );
            Ns = zeros( obj.nFrequencies, 1 );
            for iFreq = 1:obj.nFrequencies,
                [SNRs{iFreq}, Ns(iFreq)] = obj.mecClassifiers{iFreq}.getSNRs( obj.Y );
                SNRs{iFreq} = SNRs{iFreq}(:);
            end
            
        end % of method GETSNRS
        
        %-----------------------------------------------------------------------------------------------
        function [iWinnerClass, winnerClass, classScores, SNRs] = classify( obj, inputEEGData )
            
            SNRs = obj.getSNRs( inputEEGData );
            
            T = zeros( 1, obj.nFrequencies );
            for iFreq = 1:obj.nFrequencies,
                T(iFreq) = mean( SNRs{iFreq} );
            end
            [maxT, iWinnerClass] = max( T );
            
            classScores = T / maxT;
            winnerClass = obj.frequenciesList( iWinnerClass );
            
        end % of method classify
        %-----------------------------------------------------------------------------------------------
        function parseInputParameters( obj, varargin )
            
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
                
                switch( lower( parameterName ) ),
                    case{ 'nfft' },
                        if( isnumeric( parameterValue ) && isfinite( parameterValue ) ...
                                && ( numel( parameterValue ) == 1 ) && ( parameterValue > 0 ) ...
                                && ( round( parameterValue ) == parameterValue ) ),
                            obj.nFFT = parameterValue;
                        else
                            error( [mfilename ':parseInputParameters:BadNumberOfFFT'], ...
                                'Invalid nFFT value provided.' );
                        end
                    case{ 'arparameter', 'autoregressionparameter' }, 
                        if( isnumeric( parameterValue ) && isfinite( parameterValue ) ...
                                && ( numel( parameterValue ) == 1 ) && ( parameterValue > 0 ) ...
                                && ( round( parameterValue ) == parameterValue ) ),
                            obj.arParameter = parameterValue;
                        else
                            error( [mfilename ':parseInputParameters:BadArParameter'], ...
                                'Invalid auto-regression parameter provided.');
                        end
                        
                end  % of switch
                
                if isempty( parameterValue ),
                    iArg = iArg + 1;
                else
                    iArg = iArg + 2;
                end
                
            end % of loop over parameter pairs
            
        end % of function parseInputParameters
        %-----------------------------------------------
        
    end % of methods section
        
    
end % of originalMecSsvepClassifier class definition