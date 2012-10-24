function obj = eegDevice( eegDeviceName, varargin )
    import eegDeviceDrivers.*
    
    switch lower( eegDeviceName ),
        case 'imec-be',
            % imec.be 8 channel wireless EEG device (from Tom and Firat)
            obj = imecBe( varargin{:} );
            
        case 'imec-be-ptb',
            % imec.be 8 channel wireless EEG device (from Tom and Firat) (PsychToolbox version)
            obj = imecBePTB( varargin{:} );

        case 'imec-nl',
            % imec.nl 8 channel wireless EEG device (from Shrishail)
            obj = imecNl( varargin{:} );
            
        case 'imec-nl-ptb',
            % imec.nl 8 channel wireless EEG device (PsychToolbox version)
            obj = imecNlPTB( varargin{:} );
 
        case 'emotiv-epoc',
            % Emotiv Epoc 14 channel wireless EEG device
            obj = emotivEpoc( varargin{:} );
            
        case 'neurosky-mindset',
            % Neurosky MindSet single channel bluetoth-wireless EEG device
            obj = neuroskyMindSet( varargin{:} );
            
        case 'emulator',
            % emulator EEG device
            obj = emulator( varargin{:} );

        case 'biosemiemulator',
            % emulator of Bioseme EEG device
            obj = biosemiEmulator( varargin{:} );

        otherwise
            error( 'eegDevice:unknownEegDevice', 'Sorry do not know the device.' );
            
    end % of switch
    
end % of function EEGDEVICE
