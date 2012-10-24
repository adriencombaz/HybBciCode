function eegChannelsData = getEegChannelsData( eegSetupList )

    
    eegChannelsData.dependsOn = 'EEG setup';
    nEegSetups = numel( eegSetupList );

    for iSetup = 1:nEegSetups,
        
        switch eegSetupList{iSetup}
            case 'emulator (4ch@1024Hz)',
                eegChannelsData.option(iSetup).labels         = { 'ch1 name'  'ch2 name'  'ch3 name'  'ch4 name'  'use ch1'   'use ch2'   'use ch3'   'use ch4'};
                eegChannelsData.option(iSetup).values         = { 'P3'        'Pz'        'P4'        'PO9'       true        true        true        true};
                eegChannelsData.option(iSetup).varNames       = { 'ch1Name'   'ch2Name'   'ch3Name'   'ch4Name'   'useCh1'   'useCh2'     'useCh3'    'useCh4'};
                eegChannelsData.option(iSetup).prefGroupName  = 'emulator4Channels1024Setup';
    
            case 'emulator (8ch@1024Hz)',
                eegChannelsData.option(iSetup).labels         = { 'ch1 name'  'ch2 name'  'ch3 name'  'ch4 name'  'ch5 name'  'ch6 name'  'ch7 name'  'ch8 name'  'use ch1'   'use ch2'   'use ch3'   'use ch4'   'use ch5'   'use ch6'   'use ch7'   'use ch8'};
                eegChannelsData.option(iSetup).values         = { 'P3'        'Pz'        'P4'        'PO9'       'O1'        'Oz'        'O2'        'PO10'      true        true        true        true        true        true        true        true};
                eegChannelsData.option(iSetup).varNames       = { 'ch1Name'   'ch2Name'   'ch3Name'   'ch4Name'   'ch5Name'   'ch6Name'   'ch7Name'   'ch8Name'   'useCh1'   'useCh2'     'useCh3'    'useCh4'    'useCh5'    'useCh6'    'useCh7'    'useCh8'};
                eegChannelsData.option(iSetup).prefGroupName  = 'emulator8Channels1024Setup';

            case 'emulator (8ch@1000Hz)',
                eegChannelsData.option(iSetup).labels         = { 'ch1 name'  'ch2 name'  'ch3 name'  'ch4 name'  'ch5 name'  'ch6 name'  'ch7 name'  'ch8 name'  'use ch1'   'use ch2'   'use ch3'   'use ch4'   'use ch5'   'use ch6'   'use ch7'   'use ch8'};
                eegChannelsData.option(iSetup).values         = { 'P3'        'Pz'        'P4'        'PO9'       'O1'        'Oz'        'O2'        'PO10'      true        true        true        true        true        true        true        true};
                eegChannelsData.option(iSetup).varNames       = { 'ch1Name'   'ch2Name'   'ch3Name'   'ch4Name'   'ch5Name'   'ch6Name'   'ch7Name'   'ch8Name'   'useCh1'   'useCh2'     'useCh3'    'useCh4'    'useCh5'    'useCh6'    'useCh7'    'useCh8'};
                eegChannelsData.option(iSetup).prefGroupName  = 'emulator8Channels1000Setup';
    
            case 'imec-be (8ch@1000Hz)',
                eegChannelsData.option(iSetup).labels         = { 'ch1 name'  'ch2 name'  'ch3 name'  'ch4 name'  'ch5 name'  'ch6 name'  'ch7 name'  'ch8 name'  'use ch1'   'use ch2'   'use ch3'   'use ch4'   'use ch5'   'use ch6'   'use ch7'   'use ch8'};
                eegChannelsData.option(iSetup).values         = { 'P3'        'Pz'        'P4'        'PO9'       'O1'        'Oz'        'O2'        'PO10'      true        true        true        true        true        true        true        true};
                eegChannelsData.option(iSetup).varNames       = { 'ch1Name'   'ch2Name'   'ch3Name'   'ch4Name'   'ch5Name'   'ch6Name'   'ch7Name'   'ch8Name'   'useCh1'   'useCh2'     'useCh3'    'useCh4'    'useCh5'    'useCh6'    'useCh7'    'useCh8'};
                eegChannelsData.option(iSetup).prefGroupName  = 'imecBe8ChannelsSetup';

            case {'imec-nl (8ch@1024Hz)', 'imec-nl-ptb (8ch@1024Hz)'},
                eegChannelsData.option(iSetup).labels         = { 'ch1 name'  'ch2 name'  'ch3 name'  'ch4 name'  'ch5 name'  'ch6 name'  'ch7 name'  'ch8 name'  'use ch1'   'use ch2'   'use ch3'   'use ch4'   'use ch5'   'use ch6'   'use ch7'   'use ch8'};
                eegChannelsData.option(iSetup).values         = { 'P3'        'Pz'        'P4'        'PO9'       'O1'        'Oz'        'O2'        'PO10'      true        true        true        true        true        true        true        true};
                eegChannelsData.option(iSetup).varNames       = { 'ch1Name'   'ch2Name'   'ch3Name'   'ch4Name'   'ch5Name'   'ch6Name'   'ch7Name'   'ch8Name'   'useCh1'   'useCh2'     'useCh3'    'useCh4'    'useCh5'    'useCh6'    'useCh7'    'useCh8'};
                eegChannelsData.option(iSetup).prefGroupName  = 'imecNl8ChannelsSetup';
    
            case {'imec-nl (4ch@1024Hz)', 'imec-nl-ptb (4ch@1024Hz)'},
                eegChannelsData.option(iSetup).labels         = { 'use ch1 (C3)'  'use ch2 (C4)'  'use ch3 (CZ)'  'use ch4 (PZ)'};
                eegChannelsData.option(iSetup).values         = { true            true            true            true};
                eegChannelsData.option(iSetup).varNames       = { 'useCh1'        'useCh2'        'useCh3'        'useCh4'};
                eegChannelsData.option(iSetup).prefGroupName  = 'imecNl4ChannelsSetup';

            case {'imec-nl (2ch@1024Hz)', 'imec-nl-ptb (2ch@1024Hz)'},
                eegChannelsData.option(iSetup).labels         = { 'use ch1 (C3)'  'use ch2 (C4)'  'use ch3 (CZ)'  'use ch4 (PZ)'};
                eegChannelsData.option(iSetup).values         = { false            false            true            true};
                eegChannelsData.option(iSetup).varNames       = { 'useCh1'        'useCh2'        'useCh3'        'useCh4'};
                eegChannelsData.option(iSetup).prefGroupName  = 'imecNl2ChannelsSetup';

            case 'emotiv-epoc (14ch@128Hz)',
                eegChannelsData.option(iSetup).labels         = { 'use ch1 (AF3)' 'use ch2 (F7)' 'use ch3 (F3)' 'use ch4 (FC5)' ...
                    'use ch5 (T7)' 'use ch6 (P7)' 'use ch7 (O1)' 'use ch8 (O2)' 'use ch9 (P8)' 'use ch10 (T8)' 'use ch11 (FC6)' ...
                    'use ch12 (F4)' 'use ch13 (F8)' 'use ch14 (AF8)'};
                eegChannelsData.option(iSetup).values         = { true true true true true true true true true true true true true true };
                eegChannelsData.option(iSetup).varNames       = { 'useCh1' 'useCh2' 'useCh3' 'useCh4' 'useCh5' 'useCh6' 'useCh7' 'useCh8' 'useCh9' 'useCh10' 'useCh11' 'useCh12' 'useCh13' 'useCh14' };
                eegChannelsData.option(iSetup).prefGroupName  = 'emotivEpocChannelsSetup';
                
        end % of switch

    end % of loop over EEG setups
    
end % of function EEGCHANNELSSETUPDATA