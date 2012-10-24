bufferSizeInSec     = 5;
recordingDuration   = 1; 

logThis( [], 'logCallerInfo', 'off' );

% eegDev = imecBe( 'bufferSizeInSeconds', bufferSizeInSec, 'testSignalMode', 'on' );
% eegDev = imecBePTB( 'bufferSizeInSeconds', bufferSizeInSec, 'testSignalMode', 'on' );
eegDev = imecNl( 'bufferSizeInSeconds', bufferSizeInSec );
eegDev.open();

lastFlushTime = 0;
lastReadTime  = 0;
postLastRawEEGframePart = [];
eegData = [];

for i = 1:100,
        eegDev.flush();
    %     eegDev.quickFlush();
        lastFlushTime = eegDev.lastFlushTime;
        WaitSecs( recordingDuration );
        eegData = eegDev.read();
        lastReadTime = eegDev.lastReadTime;
%         lastRawEEGframePart = eegDev.lastRawEEGframePart;
%         for i = 1:eegDev.nTargetChannels,
%             subplot( eegDev.nTargetChannels, 1, i )
%             plot( eegData(i,:) );
%         end
%         drawnow();
        nSamples = size( eegData, 2 );
        recDuration = lastReadTime-lastFlushTime;
        logThis(  'nSamples: %6g  recording-time: %8.2f ms, local-sample-rate: %8.2f, global-sample-rate: %8.2f,  |lastRawEEGframePart|: %g', ...
            nSamples, 1000*recDuration, nSamples/recDuration, eegDev.estimatedSampleRate, numel( eegDev.lastRawEEGframePart ) );
    
end