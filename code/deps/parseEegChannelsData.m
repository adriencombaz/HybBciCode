function [eegDeviceName targetChannelList channelNameList] = parseEegChannelsData( eegChannelsData, eegSetupName )

    switch eegSetupName,
        case 'emulator (8ch@1000Hz)',
            eegDeviceName = 'emulator';
            channelNameList = eegChannelsData.output(1:8);
            targetChannelList = find( cell2mat( eegChannelsData.output(9:16) ) );

        case 'emulator (8ch@1024Hz)',
            eegDeviceName = 'emulator';
            channelNameList = eegChannelsData.output(1:8);
            targetChannelList = find( cell2mat( eegChannelsData.output(9:16) ) );

        case 'emulator (4ch@1024Hz)',
            eegDeviceName = 'emulator';
            channelNameList = eegChannelsData.output(1:4);
            targetChannelList = find( cell2mat( eegChannelsData.output(5:8) ) );
            
        case 'imec-be (8ch@1000Hz)',
            eegDeviceName = 'imec-be';
            channelNameList = eegChannelsData.output(1:8);
            targetChannelList = find( cell2mat( eegChannelsData.output(9:16) ) );

        case 'imec-nl (8ch@1024Hz)',
            eegDeviceName = 'imec-nl';
            channelNameList = eegChannelsData.output(1:8);
            targetChannelList = find( cell2mat( eegChannelsData.output(9:16) ) );
            
        case 'imec-nl (4ch@1024Hz)',
            eegDeviceName = 'imec-nl';
            channelNameList   = { 'C3' 'C4' 'CZ' 'PZ' 'N/A' 'N/A' 'N/A' 'N/A' };
            targetChannelList = find( cell2mat( eegChannelsData.output ) );
            
        case 'imec-nl (2ch@1024Hz)',
            eegDeviceName = 'imec-nl-ptb';
            channelNameList   = { 'C3' 'C4' 'CZ' 'PZ' 'N/A' 'N/A' 'N/A' 'N/A' };
            targetChannelList = find( cell2mat( eegChannelsData.output ) );

        case 'imec-nl-ptb (8ch@1024Hz)',
            eegDeviceName = 'imec-nl-ptb';
            channelNameList = eegChannelsData.output(1:8);
            targetChannelList = find( cell2mat( eegChannelsData.output(9:16) ) );
            
        case 'imec-nl-ptb (4ch@1024Hz)',
            eegDeviceName = 'imec-nl-ptb';
            channelNameList   = { 'C3' 'C4' 'CZ' 'PZ' 'N/A' 'N/A' 'N/A' 'N/A' };
            targetChannelList = find( cell2mat( eegChannelsData.output ) );
            
        case 'imec-nl-ptb (2ch@1024Hz)',
            eegDeviceName = 'imec-nl';
            channelNameList   = { 'C3' 'C4' 'CZ' 'PZ' 'N/A' 'N/A' 'N/A' 'N/A' };
            targetChannelList = find( cell2mat( eegChannelsData.output ) );

        case 'emotiv-epoc (14ch@128Hz)',
            eegDeviceName = 'emotiv-epoc';
            targetChannelList = 3 + find( cell2mat( eegChannelsData.output ) );
            channelNameList     = { 'COUNTER', 'INTERPOLATED', 'RAW_CQ', 'AF3', 'F7', 'F3', 'FC5', 'T7', ...
                'P7', 'O1', 'O2', 'P8', 'T8', 'FC6', 'F4', 'F8', 'AF4', 'GYROX', 'GYROY', ...
                'TIMESTAMP', 'ES_TIMESTAMP', 'FUNC_ID', 'FUNC_VALUE', 'MARKER', 'SYNC_SIGNAL' };

    end
    
end % of function PARSEEEGCHANNELSDATA