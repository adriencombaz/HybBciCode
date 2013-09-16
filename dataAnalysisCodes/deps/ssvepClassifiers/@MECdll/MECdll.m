%% SSVEP detector/classifier based on Minimum (noise) Energy Combination (MEC) spatial filtering
% technically this is just a wrapper around a mex implementation (of the MEC classifierver), which
% in turn uses MECclassifierDLL.dll
% 
%   [1] O. Friman, I. Volosyak, and A. Graser, "Multiple channel detection of
%       steady-state visual evoked potentials for brain-computer interfaces",
%       Biomedical Engineering, IEEE Transactions on, vol. 54, no. 4, pp. 742–750,
%       2007. 

classdef MECdll
    
    properties %(GetAccess = 'public', SetAccess = 'public')
        frequenciesList         = [10 12 15 20];
        nFrequencies
        harmonicsList           = 1;
        nHarmonics
        nChannels               = 8;
        normalizeW              = false;
        computeXcorrDirectly    = true;
        nSamplesInSubWindow     = 2000;
        nFFT                    = 1000;
        AR_parameter            = 20;
        samplingRate            = 1000;
    end
    
    methods        
        %-----------------------------------------------------------------------------------------------
        function obj = MECdll( inpNChannels, inpFrequenciesList, inpSamplingRate, inpHarmonicsList, inpNSamplesInSubWindow, inpNFFT, inpARparameter, inpNormalizeW, inpComputeXcorrDirectly )

            if( exist( 'inpNChannels', 'var' ) && ~isempty( inpNChannels ) ),
                obj.nChannels = inpNChannels;
            end
            
            if( exist( 'inpFrequenciesList', 'var' ) && ~isempty( inpFrequenciesList ) ),
                obj.frequenciesList = inpFrequenciesList;
            end            
            obj.nFrequencies = numel( obj.frequenciesList );

            if( exist( 'inpSamplingRate', 'var' ) && ~isempty( inpSamplingRate ) ),
                obj.samplingRate = inpSamplingRate;
            end
            
            if( exist( 'inpHarmonicsList', 'var' ) && ~isempty( inpHarmonicsList ) ),
                obj.harmonicsList = inpHarmonicsList;
            end
            obj.nHarmonics = numel( obj.harmonicsList );
            
            if( exist( 'inpNSamplesInSubWindow', 'var' ) && ~isempty( inpNSamplesInSubWindow ) ),
                obj.nSamplesInSubWindow = inpNSamplesInSubWindow;
            end
            
            if( exist( 'inpNFFT', 'var' ) && ~isempty( inpNFFT ) ),
                obj.nFFT = inpNFFT;
            end
            
            if( exist( 'inpARparameter', 'var' ) && ~isempty( inpARparameter ) ),
                obj.AR_parameter = inpARparameter;
            end
            
            if( exist( 'inpNormalizeW', 'var' ) && ~isempty( inpNormalizeW ) ),
                obj.normalizeW = inpNormalizeW;
            end

            if( exist( 'inpComputeXcorrDirectly', 'var' ) && ~isempty( inpComputeXcorrDirectly ) ),
                obj.computeXcorrDirectly = inpComputeXcorrDirectly;
            end
                        
            MECmexDLL( obj.nChannels, obj.sampleRate, obj.nFrequencies, obj.frequenciesList, obj.nHarmonics, obj.harmonicsList, obj.nSamplesInWindow, obj.nFFT, obj.ARparameter, obj.normalizeW, obj.computeXcorrDirectly );

        end % of MEC class constructor

        %-----------------------------------------------------------------------------------------------
        function [iWinnerClass, winnerClass, classScores] = classify( obj, inputEEGData )             
            [iWinnerClass, classScores] = MECmexDLL( inputEEGData );
            winnerClass = obj.frequenciesList( iWinnerClass );            
        end % of method classify
    
    end % of methods section
    
end % of MECdll class definition