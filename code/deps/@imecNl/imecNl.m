classdef imecNl < genericEegDevice
    % imecNl EEG device class
    %   imecNl is a subclass of genericEegDevice class.
    
    %----------------------------------------------------------------------------
    properties ( Constant )
        nBytesPerFrame          = 25;
        nSamplesPerFrame        = 1;
        framePreamble           = 'JEF';
        allowedParameterList    = { 'serialPortName', 'bufferSizeInSeconds', 'bdfFileName', 'bytesAvailableFunction', 'bytesAvailableFcnCount' };

    end % of private-read/private-write properties section
    %----------------------------------------------------------------------------
    properties ( SetAccess = 'private' )
        bufferSizeInFrames
        bufferSizeInBytes
        lastRawEEGframePart     = [];
    end % of private-read/public-write properties section
    %----------------------------------------------------------------------------
    properties ( Access = 'private' )
        serialPortName          = 'COM*'
        maxnGoodFrames          = 100;
        maxFlushIterations      = 20;
        interFlushPause         = 0.020;  % wait 20 ms between (unsuccesful) flushes
    end % of private-read/private-write properties section
    %----------------------------------------------------------------------------
    properties ( Access = 'public' )
        serialPortObject
        serialPortJavaObject
        bytesAvailableFcnCount = [];
        bytesAvailableFcn = [];
    end % of public-read/public-write properties section
    
    %----------------------------------------------------------------------------
    
    %----------------------------------------------------------------------------
    methods

        %-----------------------------------------------
        function obj = imecNl( varargin )
            
            obj.setChannelNames( { 'P3' 'Pz' 'P4' 'PO9' 'O1' 'Oz' 'O2' 'PO10' } );
            obj.sampleRate = 1024;
            obj.setBufferSizeInSeconds( 1 );
            obj.setTargetChannels(); % set all channels as target channels

            parseInputParameters( obj, varargin{:} );
            logThis( 'imec-nl EEG device driver object created' );
                        
        end % of constructor IMECNL
        
        %-----------------------------------------------
        function open( obj, varargin )
            parseInputParameters( obj, varargin{:} );
            nCharsInSerialPortName  = numel( obj.serialPortName );
            
            i = nCharsInSerialPortName;
            while (i>0) && (obj.serialPortName(i)<='9'),
                i = i - 1;
            end % of loop across last chars
            if i > 0,
                serialPortNameTemplate = [obj.serialPortName(1:i) '%g'];
            else
                serialPortNameTemplate = 'COM%g';
            end
            
            s = obj.serialPortName(i+1:nCharsInSerialPortName);
            if all( ( s > '0' ) & ( s < '9' ) ),
                serialPortNumberRange = str2double( s );
            else
                serialPortNumberRange = 1:99;
            end
            
            
            %% Find and connect to the EEG device
            % Automatic detection of the serial COM port:
            delete( instrfind )
            for iPort = serialPortNumberRange,
                obj.serialPortName = sprintf( serialPortNameTemplate, iPort);
                obj.serialPortObject = serial( obj.serialPortName ); %#ok<TNMLP>
                obj.serialPortObject.InputBufferSize = obj.bufferSizeInBytes;
                obj.serialPortObject.Baudrate = 1000000;
                obj.serialPortObject.DataBits = 8;
                obj.serialPortObject.Parity = 'none';
                obj.serialPortObject.StopBits = 1;
                obj.serialPortObject.FlowControl = 'none';
                obj.serialPortObject.ReadAsyncMode = 'continuous';
                obj.serialPortObject.Timeout = 0.1;
                logThis( 'Probing port %s', obj.serialPortName );
                if ~isempty( obj.bytesAvailableFcn ) && ~isempty( obj.bytesAvailableFcnCount ),
                    obj.serialPortObject.BytesAvailableFcn = obj.bytesAvailableFcn;
                    obj.serialPortObject.BytesAvailableFcnCount = obj.bytesAvailableFcnCount;
                end
                    
                try
                    obj.isOpened = false;
                    fopen( obj.serialPortObject );
                    obj.serialPortJavaObject = igetfield( obj.serialPortObject, 'jobject' );
                    % From now get( obj.serialPortJavaObject, 'BytesAvailable' )  == obj.serialPortObject.BytesAvailable
                    % From now obj.serialPortJavaObject.BytesAvailable == obj.serialPortObject.BytesAvailable
                    obj.isOpened = true;
                catch %#ok<CTCH>
                    delete( obj.serialPortObject );
                    continue
                end
                logThis( 'Found something on port %s', obj.serialPortName )

                %Check that the system is not already transmitting when the users opens
                %the interface
                logThis( 'Checking if the device is in transmission mode' );
                obj.flush();
                pause( 0.1 );
%                 obj.isTransmitting = ( get( obj.serialPortJavaObject, 'BytesAvailable' ) ~= 0);
                obj.isTransmitting = ( obj.serialPortJavaObject.BytesAvailable ~= 0 );
                if obj.isTransmitting,
                    logThis( 'The device is in transmission mode, trying to analyse the data' );
%                     obj.rawData = fread( obj.serialPortObject, get( obj.serialPortJavaObject, 'BytesAvailable' ), 'uint8' );
                    obj.rawData = fread( obj.serialPortObject, obj.serialPortJavaObject.BytesAvailable, 'uint8' );
                    iPreamble = strfind( char( obj.rawData(:)' ), obj.framePreamble );
                    if length( find(diff(iPreamble) == obj.nBytesPerFrame) ) > obj.maxnGoodFrames,
                        logThis( 'Yep, this is the IMEC.NL device.' );
                        break
                    else
                        logThis( 'Hmmm... The data this device transmits, do not look like data from IMEC.NL device. Continue search...' );
                        obj.close();
                    end
                else
                    logThis( 'Hmmm... This device does not behave as the IMEC.NL device. Continue search...' );
                    obj.close();
                end % of if device is trainsmitting branch
                
            end % of serial port loop
            
            if ~obj.isOpened,
                logThis( 'Could not find the EEG-Device' );
                error( 'Check the EEG device!' )
            else
                % Open a BDF file to save the data in
                if obj.saveBDF,
                    obj.openBDF();
                end

                % Flush the input buffer
                obj.flush();
            end
            
            
        end % of OPEN method
        %-----------------------------------------------
        function close( obj )
            if obj.isOpened,
                logThis( 'Closing the (imec.nl) EEG-Device' );
                fclose( obj.serialPortObject );
                delete( obj.serialPortObject );
                obj.isOpened = false;
                obj.lastRawEEGframePart = [];
                logThis( 'Estimated sample rate: %12.6f', obj.estimatedSampleRate );
                
                if obj.saveBDF && isempty( obj.bdfHDR ),
                    obj.bdfHDR = swrite( obj.bdfHDR, [obj.bdfBuffer', repmat( obj.BDF_CONST, size(obj.bdfBuffer,2),1)]);
                    sclose( obj.bdfHDR );
                end
            end
        end % of CLOSE method
        
        %-----------------------------------------------
        function quickFlush( obj )
            if obj.isOpened,
%                 if get( obj.serialPortJavaObject, 'BytesAvailable' ) > 0,
                if obj.serialPortJavaObject.BytesAvailable > 0,
%                     fread( obj.serialPortObject, get( obj.serialPortJavaObject, 'BytesAvailable' ) );
                    fread( obj.serialPortObject, obj.serialPortJavaObject.BytesAvailable );
                    obj.lastFlushTime = GetSecs();
                end
            else
                logThis( 'The device has not been opened!' );
                obj.lastFlushTime = [];
            end
        end % of QUICKFLUSH method
        
        %-----------------------------------------------
        function flush( obj )
            nBytesInBuffer = 0;
            for iFlush = 1:obj.maxFlushIterations,
                obj.quickFlush();                
                WaitSecs( obj.interFlushPause );
                nBytesInBuffer = obj.serialPortJavaObject.BytesAvailable;
                obj.quickFlush();
                if  nBytesInBuffer < round(1.002*obj.sampleRate*obj.nBytesPerFrame*obj.nSamplesPerFrame) && obj.serialPortJavaObject.BytesAvailable == 0,
                    obj.quickFlush();
                    return
                end
            end % of flushes loop
            logThis( 'Couldn''t properly flush the EEG-device buffer!' );
        end % of FLUSH method

        %-----------------------------------------------
        function rawEegData = getRawData( obj )
            rawEegData = [];
            if obj.isOpened
                % read real data
%                 obj.rawData = fread( obj.serialPortObject, get( obj.serialPortJavaObject, 'BytesAvailable' ), 'uint8' );
%                 rawEegData = [obj.lastRawEEGframePart(:); fread( obj.serialPortObject, obj.serialPortJavaObject.BytesAvailable, 'uint8' ) ];
                rawEegData = fread( obj.serialPortObject, obj.serialPortJavaObject.BytesAvailable, 'uint8' );
                obj.rawData = uint8( rawEegData );
                obj.lastRawEEGframePart = [];
            end
        end % of GETRAWDATA method
        
        %-----------------------------------------------
        function [EEG labels markerList] = read( obj )
            if obj.isOpened, % && obj.serialPortJavaObject.BytesAvailable>0, % && obj.isTransmitting,
                bytesAvailable = obj.serialPortJavaObject.BytesAvailable;
                obj.lastReadTime = GetSecs();
                if bytesAvailable == 0,
                    EEG = [];
                    labels = [];
                    markerList = [];
                    obj.lastReadTime = [];
%                     obj.lastRawEEGframePart = [];
                    return
                end
                
                if bytesAvailable >= obj.bufferSizeInBytes,
                    logThis( 'Buffer overflow detected' );
                    obj.lastRawEEGframePart = [];
                end
                
%                 obj.rawData = [obj.lastRawEEGframePart(:); fread( obj.serialPortObject, bytesAvailable, 'uint8' )];
                obj.rawData = fread( obj.serialPortObject, bytesAvailable, 'uint8' );
                if sum( obj.rawData<0 | obj.rawData>255 ),
                    logThis( 'Found wrong values (negative and/or >255) in obj.rawData' );
                    rawDataFilename = [ datestr( now(), 'yyyy-mm-dd-HH-MM-SS-FFF' ) '.mat' ];
                    logThis( 'Saving raw data to file [%s]', rawDataFilename );
                    rawData = obj.rawData; 
                    save( rawDataFilename, 'rawData' );
                    clear rawData
                    logThis( 'Fixing obj.rawData' );
                    obj.rawData(obj.rawData<0) = obj.rawData(obj.rawData<0) + 256;
                end
                
                nBytesInRawData     = numel( obj.rawData );
                nSamplesToExpect    = ceil( nBytesInRawData / obj.nBytesPerFrame ) * obj.nSamplesPerFrame;
                nSamplesToAllocate  = round( 1.5*nSamplesToExpect );  % extra 50%
                EEG                 = zeros( obj.nChannels, nSamplesToAllocate );
%                 maskOfInterpolatedSamples = false( 1, nSamplesToAllocate );
                nLostFrames = 0;
                
                % looking for the first good frame
                iByte = 1;

%                 logThis( 'Scanning binary stream for a valid packet' )
                while iByte<=(nBytesInRawData-obj.nBytesPerFrame+1) && ( obj.rawData(iByte)~=74 || obj.rawData(iByte+1)~=69 || obj.rawData(iByte+2)~=70 ), % || obj.rawData(iByte+obj.nBytesPerFrame)~=74),
                    iByte = iByte + 1;
                end
                % if found
                if iByte<=(nBytesInRawData-obj.nBytesPerFrame+1),
                    
                    % reconstruct two samples from the first good frame
                    EEG(:,1) = 256*obj.rawData((iByte+07):2:(iByte+21)) + obj.rawData((iByte+08):2:(iByte+22));
                    nReconstructedSamples = 1;
                    iPrevFrame = obj.rawData(iByte+3) + 256*obj.rawData(iByte+4) + 65536*obj.rawData(iByte+5) + 16777216*obj.rawData(iByte+6);
                    
                    iLastGoodSample = EEG(:,nReconstructedSamples);
                    
                    iByte = iByte + obj.nBytesPerFrame;
                    
%                     logThis( 'Keep further EEG data reconstruction' )
                    % reconstruct raw EEG data
                    while  iByte<=(nBytesInRawData-obj.nBytesPerFrame+1),
                        if (obj.rawData(iByte)==74) && (obj.rawData(iByte+1)==69) && (obj.rawData(iByte+2)==70), % && (obj.rawData(iByte+obj.nBytesPerFrame)==74),
                            iFrame = obj.rawData(iByte+3) + 256*obj.rawData(iByte+4) + 65536*obj.rawData(iByte+5) + 16777216*obj.rawData(iByte+6);
                            frameInc = iFrame - iPrevFrame;
                            iSample = nReconstructedSamples + frameInc;
                            EEG(:,iSample) = 256*obj.rawData((iByte+07):2:(iByte+21)) + obj.rawData((iByte+08):2:(iByte+22));
                            
                            
                            if frameInc>1, % some frames were lost
                                nLostFrames = nLostFrames + frameInc - 1;
                                delta = (EEG(:,iSample) - iLastGoodSample) / (obj.nSamplesPerFrame*frameInc - 1);
                                for j = (nReconstructedSamples+1):(iSample-1),
                                    EEG(:,j) = EEG(:,j-1) + delta;
                                end
%                                 maskOfInterpolatedSamples((nReconstructedSamples+1):(iSample-1)) = true;
                            end
                            
                            nReconstructedSamples = iSample;
                            iLastGoodSample = EEG(:,nReconstructedSamples);
                            iPrevFrame = iFrame;
                            iByte = iByte + obj.nBytesPerFrame;
                        else % current frame doesn't seem to be good, so continue byte-by-byte search for the next good frame
                            iByte = iByte + 1;
                        end
                    end % of main loop
                else
                    error( 'Sorry, something wrong with the EEG-data...' )
                end
                
                obj.lastRawEEGframePart = obj.rawData(iByte:nBytesInRawData);
                EEG = EEG(obj.targetChannelList,1:nReconstructedSamples) - 32768;
                obj.rawData = uint8( obj.rawData ); % !!!!
%                 maskOfInterpolatedSamples = maskOfInterpolatedSamples(1:nReconstructedSamples);

                if (obj.lastReadTime - obj.lastFlushTime) <= obj.bufferSizeInSeconds-1/obj.sampleRate,
                    % We update the sample rate related parameters only if there was no buffer overflow and
                    % all (read) samples fit in the device buffer, otherwise just skip this update.
                    obj.nSamplesReadTotal    = obj.nSamplesReadTotal + nReconstructedSamples;
                    obj.readingDurationTotal = obj.readingDurationTotal + (obj.lastReadTime - obj.lastFlushTime);
                    obj.estimatedSampleRate  = obj.nSamplesReadTotal / obj.readingDurationTotal;
                end
                
                % label EEG data (if needed)
                if nargout>1 || obj.saveBDF,
                    % return marker (event) list (if needed)
                    
                    if nargout>2,
                        [labels markerList] = obj.getLabels( nReconstructedSamples );
                    else
                        labels = obj.getLabels( nReconstructedSamples ); % call inherited method
                    end % of markerList branch
                end % of labelling branch                
                
                % Save data in BDF file
                if obj.saveBDF,
                    toWrite = [obj.bdfBuffer, [EEG; obj.BDF_CONST+labels]];
                    nDataBlocks = fix( size( toWrite, 2 ) / (obj.bdfHDR.Dur*obj.bdfHDR.Samplerate) );
                    nSamplesToWrite = nDataBlocks * obj.bdfHDR.Dur * obj.bdfHDR.Samplerate;
                    obj.bdfBuffer = toWrite(:,nSamplesToWrite+1:end);
                    obj.bdfHDR = swrite( obj.bdfHDR, toWrite(:,1:nSamplesToWrite)' );
                end
                
                obj.lastFlushTime = obj.lastReadTime;
                
            else
                EEG = [];
                labels = [];
                markerList = [];
                obj.lastReadTime = [];
            end % of obj.isOpened
            
        end % of READ method
        
        %-----------------------------------------------
        function setBufferSizeInSeconds( obj, nSeconds )
            if nargin > 1,
                obj.bufferSizeInSeconds = nSeconds;
            else
                obj.bufferSizeInSeconds = 1;
            end
            obj.bufferSizeInSamples = obj.sampleRate * obj.bufferSizeInSeconds;
            obj.bufferSizeInFrames  = ceil( obj.bufferSizeInSamples / obj.nSamplesPerFrame );
            obj.bufferSizeInBytes   = obj.bufferSizeInFrames * obj.nBytesPerFrame;
        end % of function SETBUFFERSIZEINSECOND

        %-----------------------------------------------
        function openBDF( obj )
            obj.bdfHDR.TYPE         = 'BDF';
            obj.bdfHDR.T0           = clock();
            obj.bdfHDR.NS           = obj.nTargetChannels+1;
            obj.bdfHDR.Samplerate   = obj.sampleRate;
            obj.bdfHDR.Dur          = 1; % Duration of one block in seconds
            obj.bdfHDR.AS.SPR       = repmat( obj.sampleRate, obj.nTargetChannels+1, 1 ); % Samples per block
            obj.bdfHDR.Transducer   = [repmat( {'Ag-AgCl Active electrode'}, obj.nTargetChannels, 1 ); ' '];
            obj.bdfHDR.Label        = [obj.targetChannelNameList, {'Status'}]';
            obj.bdfHDR.PhysMax      = [repmat( 32767, obj.nTargetChannels, 1 ); 255];
            obj.bdfHDR.PhysMin      = [repmat(-32768, obj.nTargetChannels, 1 ); 0];
            obj.bdfHDR.DigMax       = [repmat( 65535, obj.nTargetChannels, 1 ); 255];
            obj.bdfHDR.DigMin       = zeros( obj.nTargetChannels+1, 1 );
            obj.bdfHDR.PreFilt      = [repmat( 'HP:0.2Hz LP:52-274Hz', obj.nTargetChannels, 1 ); '                    '];
            obj.bdfHDR.PhysDim      = [repmat( {'uV'}, obj.nTargetChannels, 1 ); '-'];
            
            obj.bdfHDR = sopen( obj.bdfHDR, 'w' );
        end % of function OPENBDF
        
        %-----------------------------------------------
        function parseInputParameters( obj, varargin )
            iArg = 1;
            nParameters = numel( varargin );
            while ( iArg <= nParameters ),
                parameterName = varargin{iArg};
                if (iArg < nParameters),
                    parameterValue = varargin{iArg+1};
                else
                    parameterValue = [];
                end
                iParameter = find( strncmpi( parameterName, obj.allowedParameterList, numel( parameterName ) ) );
                if isempty( iParameter ),
                    error( 'imecNl:parseInputParameters:UnknownParameterName', ...
                        'Unknown parameter name: %s.', parameterName );
                elseif numel( iParameter ) > 1,
                    error( 'imecNl:parseInputParameters:AmbiguousParameterName', ...
                        'Ambiguous parameter name: %s.', parameterName );
                else
                    switch( iParameter ),
                        case 1,  % serialPortName
                            if ischar( parameterValue ),
                                obj.serialPortName = parameterValue;
                            else
                                error('imecNl:parseInputParameters:BadSerialPortName', ...
                                    'Wrong or missing value for serialPortName parameter.');
                            end
                            
                        case 2,  % bufferSizeInSeconds
                            if isnumeric( parameterValue ) && isfinite( parameterValue ) && (parameterValue > 0),
                                setBufferSizeInSeconds( obj, parameterValue );
                            else
                                error('imecNl:parseInputParameters:BadBufferSizeInSec', ...
                                    'Wrong or missing value for bufferSizeInSeconds parameter.');
                            end

                        case 3, % bdfFileName
                            if ischar( parameterValue ),
                                obj.bdfHDR.FileName = parameterValue;
                                obj.saveBDF = 1;
                            else
                                error('imecNl:parseInputParameters:BadBdfFileName', ...
                                    'Wrong or missing value for bdfFileName parameter.');
                            end
                            
                        case 4, % bytesAvailableFcn
                            obj.bytesAvailableFcn = parameterValue;
                            
                        case 5, % bytesAvailableFcnCount
                            if isnumeric( parameterValue ) && isfinite( parameterValue ) && (parameterValue > 0),
                                obj.bytesAvailableFcnCount = parameterValue;
                            else
                                error('imecNl:parseInputParameters:bytesAvailableFcnCount', ...
                                    'Wrong or missing value for bytesAvailableFcnCount parameter.');
                            end
                            

                    end % of iParameter switch
                end % of unique acceptable iParameter found branch
                
                if isempty( parameterValue  ),
                    iArg = iArg + 1;
                else
                    iArg = iArg + 2;
                end
                
            end % of parameter loop
        end % of function parseInputParameters
        %-----------------------------------------------
    end % of methods section
    
    
end % of IMECNL class definition
