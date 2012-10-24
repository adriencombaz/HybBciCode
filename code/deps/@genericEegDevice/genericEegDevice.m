classdef genericEegDevice < handle
    % EEG device superclass
    
    properties  % public properties section
    end % of public properties section
        %----------------------------------------------------------------------------
    properties ( Constant )
        BDF_CONST           = 524288; %  bitshift( 1, 19 )
        DEFAULT_MARKER_ID   = 0;
        TRIGGER_EVENT_ID    = 1;
        SWITCH_EVENT_ID     = 2;
    end % of private-read/private-write properties section

    %----------------------------------------------------------------------------
    properties ( SetAccess = 'protected' )
        saveBDF                 = false;
        isOpened                = false;
        isTransmitting          = false;
        channelNameList         = {};   % list of EEG device channel names (array of string cells)
        targetChannelNameList   = {};   % list of target channel names (array of string cells)
        targetChannelList       = [];   % list of target channel indices (w.r.t. obj.channelNameList)
        refElectrode            = '';
        gndElectrode            = '';
        sampleRate
        nSamplesReadTotal               % total (across all read calls) number of samples read 
        readingDurationTotal            % total acquisition duration of read data
        estimatedSampleRate             % running estimate of sample rate
        nChannels
        nTargetChannels
        bufferSizeInSeconds
        bufferSizeInSamples
        rawData
        lastFlushTime
        lastReadTime
    end % of private-read/public-write properties section
    %----------------------------------------------------------------------------
    properties ( Access = 'protected' )
        bdfBuffer           = [];
        markerList          = [];
        markerIgnoreList    = [];
        bdfHDR
        lastMarkerId
    end % of prorected properties section
    %----------------------------------------------------------------------------
    properties ( Access = 'private' )
    end % of private-read/private-write properties section

    %----------------------------------------------------------------------------
    methods ( Access = 'protected' )
    end % of protected methods section 

    %----------------------------------------------------------------------------
    methods ( Access = 'private' )
    end % of private methods section 
    %----------------------------------------------------------------------------
    methods
        %-----------------------------------------------
        function obj = genericEegDevice( varargin )
            obj.lastMarkerId = obj.DEFAULT_MARKER_ID;
            obj.estimatedSampleRate = nan;
            obj.nSamplesReadTotal = 0;
            obj.readingDurationTotal = 0;
            logThis( 'Generic EEG device object created' );
        end % of constructor GENERICEEGDEVICE
        
        %-----------------------------------------------
        function setChannelNames( obj, channelNameList )
            assert( iscellstr( channelNameList ), ...
                'channelNameList parameter in genericEegDevice.setChannelNames() method must be a cell array of strings.' );

            nProvidedChannels = numel( channelNameList );
            
            if isempty( obj.nChannels ),
                obj.nChannels = nProvidedChannels;
            end
            
            obj.channelNameList = cell( 1, obj.nChannels );
            if nProvidedChannels > obj.nChannels,
                warning( 'genericEegDevice:setChannelNames:wrongChannelNumber', ...
                    'Number of provided channel names (%g) more then number of EEG device channels (%g). Extra names are ignored.', ...
                    nProvidedChannels, obj.nChannels );
                obj.channelNameList = channelNameList(1:obj.nChannels);
            else
                obj.channelNameList(1:nProvidedChannels) = channelNameList(:);
            end
            
        end % of SETCHANNELNAMES method

        %-----------------------------------------------
        function setTargetChannels( obj, channelList )
            
            if ~exist( 'channelList', 'var' ) || isempty( channelList ),
                channelList = 1:obj.nChannels;  % by default all available channels are target channels 
            end
            nProvidedTargetChannels = numel( channelList );
            obj.targetChannelList = [];
            
            if iscellstr( channelList ), % the provided channelList might be an array of string cells
                for iCh = 1:nProvidedTargetChannels,
                    channelName = channelList{iCh};
                    iChannel = find( strncmpi( channelName, obj.channelNameList, numel( channelName ) ) );
                    if numel( iChannel ) == 1,
                        obj.targetChannelList = [obj.targetChannelList iChannel];
                    end % of found allowed target channel name branch
                end % of loop over channels
            else
                % convert channelList into array of valid indices
                channelList = real( round( double( channelList ) ) );
                channelList((channelList<=0)&(channelList>obj.nChannels)) = [];
                obj.targetChannelList = channelList;
            end
            
            obj.nTargetChannels = numel( obj.targetChannelList );
            
            % Update obj.targetChannelNameList - list of target channel names (array of string cells)
            obj.targetChannelNameList = cell( 1, obj.nTargetChannels );
            for iCh = 1:obj.nTargetChannels,
                obj.targetChannelNameList{iCh} = obj.channelNameList{ obj.targetChannelList(iCh) };
            end % of loop over target channels            
            
        end % of SETTARGETCHANNELS method

        %-----------------------------------------------
        function setMarkerIgnoreList( obj, markerIgnoreList )
        % Set a list of marker IDs to be ignored during the sample labelling
        % (see getLabels). A rude hack, please don't use unless you really 
        % know what you're doing.
            if ~exist( 'markerIgnoreList', 'var' ),
                markerIgnoreList = [];
            end
            obj.markerIgnoreList = markerIgnoreList;
        end % of SETMARKERIGNORELIST method
        
        %-----------------------------------------------
        function setSampleRate( obj, sampleRate )

            if nargin > 1,
                obj.sampleRate = sampleRate;
            else
                obj.sampleRate = 1000;
            end
            
            obj.bufferSizeInSamples = obj.bufferSizeInSeconds * obj.sampleRate;
        end % of function SETSAMPLERATE        
        
        %-----------------------------------------------
        function open( obj, varargin ) %#ok<*MANU>
        end % of OPEN method
        
        %-----------------------------------------------
        function close( obj )
            if obj.isOpened,
                logThis( 'Closing the EEG-Device' );
                obj.isOpened = false;
                logThis( 'Estimated sample rate: %12.6f', obj.estimatedSampleRate );
				if obj.saveBDF,
					obj.bdfHDR = swrite( obj.bdfHDR, obj.bdfBuffer' );
					sclose( obj.bdfHDR );
				end
            end % of if(isOpened) operator
        end % of CLOSE method
        
        %-----------------------------------------------
        function flush( obj )            
            if obj.isOpened,
                obj.lastFlushTime = GetSecs();
            else
                logThis( 'The device has not been opened!' );
                obj.lastFlushTime = [];
            end % of if(isOpened) operator
        end % of FLUSH method

        %-----------------------------------------------
        function markTriggerEvent( obj, markerId, timeStamp )
            if nargin < 3,
                timeStamp = GetSecs();
            end
            nMarkers = numel( markerId );
            if nMarkers > 1,
                obj.markerList = [obj.markerList [timeStamp(ones( 1, nMarkers )); obj.TRIGGER_EVENT_ID(ones( 1, nMarkers )); markerId(:)' ]];
            else
                obj.markerList = [obj.markerList [timeStamp; obj.TRIGGER_EVENT_ID; markerId ]];
            end
        end % of MARKTRIGGEREVENT method

        %-----------------------------------------------
        function markSwitchEvent( obj, markerId, timeStamp )
            if nargin < 3,
                timeStamp = GetSecs();
            end
            nMarkers = numel( markerId );
            if nMarkers > 1, % IS THAT NECESSARY ????
                obj.markerList = [obj.markerList [timeStamp(ones( 1, nMarkers )); obj.SWITCH_EVENT_ID(ones( 1, nMarkers )); markerId(:)' ]];
            else
                obj.markerList = [obj.markerList [timeStamp; obj.SWITCH_EVENT_ID; markerId ]];
            end
        end % of MARKSWITCHEVENT method
        %-----------------------------------------------
        function forgetLastEvent( obj )
            obj.lastMarkerId = obj.DEFAULT_MARKER_ID;
        end % of FORGETLASTEVENT method
        %-----------------------------------------------
        function forgetAllEvents( obj )
            obj.lastMarkerId = obj.DEFAULT_MARKER_ID;
            obj.markerList = [];
        end % of FORGETALLEVENTS method
        %-----------------------------------------------
        function [labels markerList] = getLabels( obj, nSamples )
            dt = obj.lastReadTime - obj.lastFlushTime; % assuming perfect read/flush timings
%             dt = nSamples / obj.sampleRate;     % assuming precise sample rate
            iSampleLastEvent = 1;
                       
            if ~isempty(obj.markerList)
                % Sort the markerlist chronologically
                [~, sortedInd] = sort( obj.markerList(1,:), 2 );
                obj.markerList = obj.markerList(:,sortedInd);
            end
            
            if nargout > 1,
                markerList = obj.markerList;
            end
            
            labels = obj.lastMarkerId(ones( 1, nSamples ));
            
            for iMarker = 1:size( obj.markerList, 2 ),
                
                markerId = obj.markerList(3,iMarker);
                if ismember( markerId, obj.markerIgnoreList ),
                    continue;
                end
                iSample = ceil( nSamples * (obj.markerList(1,iMarker) - obj.lastFlushTime) / dt );
                if iSample > nSamples,
                    obj.lastMarkerId = markerId;
                    break % stop processing events
                end    
                if iSample < 1,
                    obj.lastMarkerId = markerId;
                    iSample = 1;
                end
%                 eventRelativeTime = obj.markerList(1,iMarker) - obj.lastFlushTime; % w.r.t. last flush
%                 if ( eventRelativeTime > dt ),
%                     break % stop processing events
%                 end    
%                 if ( eventRelativeTime <= 0 ),
%                     iSample = 1;
%                 else
%                     iSample = ceil( nSamples * eventRelativeTime / dt );
%                 end
                
                eventTypeId = obj.markerList(2,iMarker);
                
                labels(iSampleLastEvent:iSample-1) = obj.lastMarkerId;
                labels(iSample) = markerId;
                iSampleLastEvent = iSample + 1;
                
                switch eventTypeId,
                    case obj.TRIGGER_EVENT_ID,
                        obj.lastMarkerId = obj.DEFAULT_MARKER_ID;
                    case obj.SWITCH_EVENT_ID,
                        obj.lastMarkerId = markerId;
                end
                
            end % of loop over recorded events
            
            obj.markerList = obj.markerList(:,iMarker+1:end);
            labels(iSampleLastEvent:end) = obj.lastMarkerId;
        end % of GETLABELS method
        
        %-----------------------------------------------
        function [EEG labels markerList] = read( obj ) %#ok<*STOUT>
            obj.lastReadTime = GetSecs();
            if ~obj.isOpened,
                EEG = [];
                obj.lastReadTime = [];
                obj.lastFlushTime = [];
                return
            end
            
            % label EEG data (if needed)
            if nargout>1 || obj.saveBDF,
                % return marker (event) list (if needed)
                if nargout>2,
                    [labels markerList] = obj.getLabels( nReconstructedSamples );
                else
                    labels = obj.getLabels( nReconstructedSamples );
                end % of markerList branch
            end % of labelling branch
            
            if (obj.lastReadTime - obj.lastFlushTime) <= obj.bufferSizeInSeconds-1/obj.sampleRate,
                % We update the sample rate related parameters only if there was no buffer overflow and
                % all (read) samples fit in the device buffer, otherwise just skip this update.
                obj.nSamplesReadTotal    = obj.nSamplesReadTotal + nReconstructedSamples;
                obj.readingDurationTotal = obj.readingDurationTotal + (obj.lastReadTime - obj.lastFlushTime);
                obj.estimatedSampleRate  = obj.nSamplesReadTotal / obj.readingDurationTotal;
            end
            
        end % of READ method
        
        %-----------------------------------------------
        function setBufferSizeInSeconds( obj, nSeconds ) %#ok<*INUSD>
        end % of function SETBUFFERSIZEINSECOND

        %-----------------------------------------------
        function estSampleRate = estimateSampleRate( obj ) %#ok<*INUSD>
            estSampleRate = obj.nSamplesReadTotal / obj.readingDurationTotal;
            obj.estimatedSampleRate = estSampleRate;
        end % of function ESTIMATESAMPLERATE

        %-----------------------------------------------        
        function openBDF( obj )
		end % of function OPENBDF

        %-----------------------------------------------
        function parseInputParameters( obj, varargin )
        end % of function parseInputParameters
        %-----------------------------------------------
    end % of methods section 
    
end % of EMULATOR class definition
