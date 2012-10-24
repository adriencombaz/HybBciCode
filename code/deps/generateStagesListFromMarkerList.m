function stagesList = generateStagesListFromMarkerList( markerList, nSamples, startRecordingTime, endRecordingTime, desiredLabelsList, sampleRate, useSampleRateAsReference )
        
    if ~exist( 'sampleRate', 'var' ) || isempty( sampleRate ),
        sampleRate = 1024;
    end
    
    if ~exist( 'useSampleRateAsReference', 'var' ) || isempty( useSampleRateAsReference ),
        useSampleRateAsReference = true;
    end
    
    if ~exist( 'desiredLabelsList', 'var' ) || isempty( desiredLabelsList ),
        desiredLabelsList = unique( round( markerList(3,:) ) );
        desiredLabelsList = desiredLabelsList( desiredLabelsList>0 );
    end
    
    recordingSessionDuration = endRecordingTime - startRecordingTime;
    
    function sampleIndex = ts2si( timestamp ) % convert timestamp into corresponding sample index        
        dt = timestamp - startRecordingTime;
        if useSampleRateAsReference,
            sampleIndex = round( dt * sampleRate );
        else
            sampleIndex = round( nSamples * dt / recordingSessionDuration );
        end
    end % of nested function TIMESTAMP2SAMPLEINDEX

    nMarkers = size( markerList, 2 );
    selectedMarkers = find( ismember( markerList(3,:), desiredLabelsList ) );
    nStages = numel( selectedMarkers );
    stagesList = zeros( nStages, 3 );
    
    for iStage = 1:nStages,
        iMarker = selectedMarkers( iStage );
        iStartSample = max( 1, ts2si( markerList(1,iMarker) ) );

        if iMarker < nMarkers,
            iEndSample = min( nSamples, ts2si( markerList(1,iMarker+1) )-1 );
        else
            iEndSample = nSamples;
        end
        
        stagesList(iStage,1) = iStartSample; 
        stagesList(iStage,2) = iEndSample;
        stagesList(iStage,3) = markerList(3,iMarker); % stage label

    end % of loop over stages (selected from markerList)

end % of function GENERATESTAGESLISTFROMMARKERLIST