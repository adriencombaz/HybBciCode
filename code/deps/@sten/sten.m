classdef sten < handle
    % STimulation ENgine for Matlab.
    % developed by Nikolay Chumerin
    % http://sites.google.com/site/chumerin/
    
    properties  % public properties section
        sc                              % scenario
        scr                             % screen
        pb                              % progress bar
        presentationStartTime   = 0;
        presentationStopTime    = 0;
        lastFlipTime            = 0;
        nextFlipTime            = 0;
        frameRenderDurationLog  = [];
        flipTimeLog             = [];
        texAlphaLog             = [];
    end % of public properties section
    
    %----------------------------------------------------------------------------
    properties ( SetAccess = 'private' )
        majorVersion            = 0;
        minorVersion            = 5;
        lastUpdateDate          = '2012-10-22';
        reinitPersVars          = true;
        showPerformancePlot     = false;
        availableScreenList
        skipSyncTests           = 2;
        nFramesForSyncTest      = 100;
        desiredScreenID
        windowRectangle
        stateTimingMargin       = 0;
        dispatchEvents
        pPTBwin
        eventIdList             = [];
        iEvent                  = 0;
        whenToFlip              = 0;
        timeFrameRenderStart    = 0;
        timeFrameRenderFinish   = 0;
        renderingStartTime      = 0;
        timeBeforeFlip          = 0;        
        iFrame                  = 0;
        stopLoopTime            = 0;
        nLocalEvents            = 0;
        alpha                   = 1;
        iSeq                    = 0;
        iStim                   = 0;
        iSt                     = 0;
        iCF                     = 0;
        iV                      = 0;
        iT                      = 0;
        processEvents           = true;
        showLogo                = false;
        globalAlphaScaler       = 1;
        iTex                    = 0;
        texAlphas
        texPTBpointers
        texSrcRects
        texTrgPositions
        logo
        fullPathToSten
    
    end % of private-read/public-write properties section
    
    %----------------------------------------------------------------------------
    properties ( Constant )
        allowedParameterList    = { 'desiredScreenID'       ... 1
                                    'skipSyncTests'         ... 2
                                    'windowRectangle'       ... 3
                                    'showPerformancePlot'   ... 4
                                    'logger'                ... 5
                                    'nFramesForSyncTest'    ... 6
                                    'showLogo'              ... 7
                                    };
        defaultTexturesDir      = ['textures' filesep() ];
    end % of private-read/private-write properties section
    
    %----------------------------------------------------------------------------
    methods
        %-----------------------------------------------
        function obj = sten( varargin )
            logThis( [], 'logCallerInfo', false );
            obj.fullPathToSten = [ fileparts( mfilename('fullpath') ) '/' ];
            obj.availableScreenList = Screen( 'Screens' );
            obj.desiredScreenID = max( obj.availableScreenList );            
            obj.setEventDispatcher( @triggerEvent );
            obj.windowRectangle = [];
            
%             obj.logo.image = readTextureFromPNG( [obj.fullPathToSten 'private/logo.png' ] );
            obj.logo.image = loadTexture( [obj.fullPathToSten 'private/logo.png' ] );

            if ( 14678592 ~= sum( double( obj.logo.image(:) ) ) ),
                error( 'STEN object construction problem: corrupted data has been file detected.' );
            end
            obj.logo.image = obj.logo.image(1:83,:,:);
            parseInputParameters( obj, varargin{:} );
            logThis( 'STimluation ENgine [STEN %s, (%s)] object created', obj.getVersion(), obj.lastUpdateDate );
        end % of constructor STEN
        
        %----------------------------------------------------------------------------
        function stenVersionString = getVersion( obj )
%             stenVersionString = sprintf( '%d.%02d-%s', obj.majorVersion, obj.minorVersion, obj.lastUpdateDate );
            stenVersionString = sprintf( '%d.%02d', obj.majorVersion, obj.minorVersion );
        end % of method STENVERSIONSTRING

        %-----------------------------------------------
        function loadScenario( obj, scenarioFileName )
            if exist( scenarioFileName, 'file' ),
                [scenarioDir, ~, scenarioFormat] = fileparts( scenarioFileName );
                if isempty( scenarioDir ),
                    scenarioDir = '.';
                end
                switch lower( scenarioFormat ),
                    case '.xml',
                        obj.sc = readXMLfile( scenarioFileName ); % xml2mat
                    case '.mat',
                        obj.sc = load( scenarioFileName );
                    otherwise
                        error( 'sten:loadScenario:unknownFiletype', ...
                            'STEN: Unrecognised filetype.' );
                end
                obj.sc.scenarioDir = [ scenarioDir filesep() ];
            else
                error('sten:loadScenario:fileNotFound', ...
                    'STEN: Couldn''t find file [%s].', scenarioFileName );
            end
        end % of method LOADSCENARIO
        
        %-----------------------------------------------
        function saveScenario( obj, scenarioFileName )
            
            if ~exist( 'scenarioFileName', 'var' ) || isempty( scenarioFileName ),
                scenarioFileName = 'stenScenario.xml';
            end
                
            [scenarioDir, ~, scenarioFormat] = fileparts( scenarioFileName );
            if isempty( scenarioDir ),
                scenarioDir = '.';
            end
            switch lower( scenarioFormat ),
                case '.xml',
                    XML = mat2xmlf( obj.sc, 'scenario' );
                    f = fopen( scenarioFileName, 'w' );
                    fprintf( f, '%s', XML );
                    fclose( f );
                case '.mat',
                    scenario = obj.sc;
                    save( scenarioFileName, 'scenario' );
                otherwise
                    error( 'sten:saveScenario:unknownFiletype', ...
                        'STEN: Unrecognised filetype.' );
            end
            
        end % of method SAVESCENARIO
        
        %-----------------------------------------------
        function setEventDispatcher( obj, hfcnEventDispatcher )
            assert( isa( hfcnEventDispatcher, 'function_handle' ), ...
                'sten:setEventDispatcher:invalidFunctionHandle', ...
                'STEN: Invalid event dispatcher function handle!' );
            obj.dispatchEvents = hfcnEventDispatcher;
        end % of method SETEVENTDISPATCHER

        %----------------------------------------------------------------------------
        function unfoldScenario( obj )
            
            logThis( 'Unfolding (filling missing data) scenario [%s]', obj.sc.description)
            
            % Fill out the missing data
            if ~isfield( obj.sc, 'nStimuli') || isempty( obj.sc.nStimuli ),
                obj.sc.nStimuli = numel( obj.sc.stimuli );
            end
            
            if ~isfield( obj.sc, 'nTextures') || isempty( obj.sc.nTextures ),
                obj.sc.nTextures = numel( obj.sc.textures );
            end
            
            if ~isfield( obj.sc, 'nEvents') || isempty( obj.sc.nEvents ),
                obj.sc.nEvents = numel( obj.sc.events );
            end
            
            if ~isfield( obj.sc, 'frameBasedEventIdAdjust') || isempty( obj.sc.frameBasedEventIdAdjust ),
                obj.sc.frameBasedEventIdAdjust = 0; %0.1;
            end
            
            if ~isfield( obj.sc, 'issueFrameBasedEvents') || isempty( obj.sc.issueFrameBasedEvents ),
                obj.sc.issueFrameBasedEvents = true;
            end

            if ~isfield( obj.sc, 'issueTimeBasedEvents') || isempty( obj.sc.issueTimeBasedEvents ),
                obj.sc.issueTimeBasedEvents = false;
            end

            if ~isfield( obj.sc, 'useBinaryIntensity') || isempty( obj.sc.useBinaryIntensity ),
                obj.sc.useBinaryIntensity = false;
            end

            if ~isfield( obj.sc, 'correctStimulusAppearanceTime') || isempty( obj.sc.correctStimulusAppearanceTime ),
                obj.sc.correctStimulusAppearanceTime = true;
            end

            if ~isfield( obj.sc, 'showProgressBar') || isempty( obj.sc.showProgressBar ),
                obj.sc.showProgressBar = false;
            end
            
            % Textures -------------------------
            for iT = 1:obj.sc.nTextures,
                obj.sc.textures(iT).isLoaded        = false;
                obj.sc.textures(iT).isLoadedToPTB   = false;
                obj.sc.textures(iT).image           = [];
                obj.sc.textures(iT).pPTB            = 0;
            end % of texture loop
            
            % Events --------------------------
            lastMaxId = 0;
            for iE = 1:obj.sc.nEvents,
                if ~isfield( obj.sc.events(iE), 'id' ) || isempty( obj.sc.events(iE).id ),
                    obj.sc.events(iE).id = lastMaxId + 1;
                end
                lastMaxId = max( lastMaxId, obj.sc.events(iE).id );
                
                if ~isfield( obj.sc.events(iE), 'showOnScreen' ) || isempty( obj.sc.events(iE).showOnScreen ),
                    obj.sc.events(iE).showOnScreen = false;
                end
                if ~isfield( obj.sc.events(iE), 'sendToServer' ) || isempty( obj.sc.events(iE).sendToServer ),
                    obj.sc.events(iE).sendToServer = false;
                end
                if ~isfield( obj.sc.events(iE), 'saveToFile' ) || isempty( obj.sc.events(iE).saveToFile ),
                    obj.sc.events(iE).saveToFile = false;
                end
                if ~isfield( obj.sc.events(iE), 'callDispatcher' ) || isempty( obj.sc.events(iE).callDispatcher ),
                    obj.sc.events(iE).callDispatcher = false;
                end                
            end % of event loop
            
            if ~isfield( obj.sc, 'iStartEvent' ) || isempty( obj.sc.iStartEvent ),
                obj.sc.iStartEvent = max( 0, obj.sc.nEvents-1 );
            end
            if ~isfield( obj.sc, 'iEndEvent' ) || isempty( obj.sc.iEndEvent ),
                obj.sc.iEndEvent = obj.sc.nEvents;
            end
            if ~isfield( obj.sc, 'iMainLoopStopEvent' ) || isempty( obj.sc.iMainLoopStopEvent ),
                obj.sc.iMainLoopStopEvent = obj.sc.iEndEvent;
            end
                        
            obj.sc.auditoryStimuliList = [];
            obj.sc.visualStimuliList   = [];
            
            % Stimuli --------------------------
            for iStim = 1:obj.sc.nStimuli,
                
                if ~isfield( obj.sc.stimuli(iStim), 'isVisual' ) || isempty( obj.sc.stimuli(iStim).isVisual ),
                    obj.sc.stimuli(iStim).isVisual = true;
                end
                if obj.sc.stimuli(iStim).isVisual,
                    obj.sc.visualStimuliList = [obj.sc.visualStimuliList iStim];
                end
                
                if ~isfield( obj.sc.stimuli(iStim), 'isAuditory' ) || isempty( obj.sc.stimuli(iStim).isAuditory ),
                    obj.sc.stimuli(iStim).isAuditory = false;
                end
                if obj.sc.stimuli(iStim).isAuditory,
                    obj.sc.auditoryStimuliList = [obj.sc.auditoryStimuliList iStim];
                end
                
                if ~isfield( obj.sc.stimuli(iStim), 'isMoving' ) || isempty( obj.sc.stimuli(iStim).isMoving ),
                    obj.sc.stimuli(iStim).isMoving = false;
                end
                
                % default parameters for the stimulus
                if ~isfield( obj.sc.stimuli(iStim), 'default' ),
                    obj.sc.stimuli(iStim).default.frequency = 0;
                    obj.sc.stimuli(iStim).default.initialPhase = 0;
                end
                if ~isfield( obj.sc.stimuli(iStim).default, 'frequency' ) || isempty( obj.sc.stimuli(iStim).default.frequency ),
                    obj.sc.stimuli(iStim).default.frequency = 0;
                end
                if ~isfield( obj.sc.stimuli(iStim).default, 'initialPhase' ) || isempty( obj.sc.stimuli(iStim).default.initialPhase ),
                    obj.sc.stimuli(iStim).default.initialPhase = 0;
                end
                if ~isfield( obj.sc.stimuli(iStim).default, 'durationInMs' ) || isempty( obj.sc.stimuli(iStim).default.durationInMs ),
                    obj.sc.stimuli(iStim).default.durationInMs = inf;
                end
                
                % states of the stimulus
                obj.sc.stimuli(iStim).nStates = numel( obj.sc.stimuli(iStim).states );
                obj.sc.stimuli(iStim).stateSequenceLength = numel( obj.sc.stimuli(iStim).stateSequence );
                obj.sc.stimuli(iStim).iStateInSequence = 1;
                obj.sc.stimuli(iStim).previousEventId = nan;
                
                % !!!!! to be removed
                % stimulus phase/appearance time data initialization                
                obj.sc.stimuli(iStim).actualPhase = 0;  
                obj.sc.stimuli(iStim).appearanceTimeCorrection = 0;
                
                %% Check and adjust (or create if necessary) durationSequenceInSec
                stimulusHasFieldDurationSequence  = isfield( obj.sc.stimuli(iStim), 'durationSequenceInSec' ) && ~isempty( obj.sc.stimuli(iStim).durationSequenceInSec );
                stimulusFieldDurationSequenceInMs = isfield( obj.sc.stimuli(iStim), 'durationSequenceInMs' ) && ~isempty( obj.sc.stimuli(iStim).durationSequenceInMs );
                
                if stimulusFieldDurationSequenceInMs,
                    if stimulusHasFieldDurationSequence,
                        warning( 'sten:unfoldScenario:umbigousDurationSequence', ...
                            'STEN: Stimulus#%g has defined both durationSequenceInMs and durationSequenceInSec fields. Using durationSequenceInMs.', iStim );
                    end
                    % use durationSequenceInMs as a reference
                    obj.sc.stimuli(iStim).durationSequenceInMs = ...
                        repeatAndCropVector( obj.sc.stimuli(iStim).durationSequenceInMs, obj.sc.stimuli(iStim).stateSequenceLength );
                    
                    obj.sc.stimuli(iStim).durationSequenceInSec = obj.sc.stimuli(iStim).durationSequenceInMs / 1000;
                else % durationSequenceInMs was not defined
                    if ~stimulusHasFieldDurationSequence,
                        % both fields were not defined
                        % use the default state duration for all values in durationSequenceInSec
                        obj.sc.stimuli(iStim).durationSequenceInSec = obj.sc.stimuli(iStim).default.durationInMs / 1000;
                    end
                    % use durationSequenceInSec as a reference
                    obj.sc.stimuli(iStim).durationSequenceInSec = ...
                        repeatAndCropVector( obj.sc.stimuli(iStim).durationSequenceInSec, obj.sc.stimuli(iStim).stateSequenceLength );
                    obj.sc.stimuli(iStim).durationSequenceInMs = obj.sc.stimuli(iStim).durationSequenceInSec * 1000;
                end
                if find( obj.sc.stimuli(iStim).durationSequenceInMs <= 0 ),
                    warning( 'sten:unfoldScenario:umbigousDurationSequence', ...
                        'STEN: Stimulus#%g has non-positive values in durationSequenceInMs and durationSequenceInSec.', iStim );
                end
                
                %% Check and fix the eventMatrix
                if ~isfield( obj.sc.stimuli(iStim), 'eventMatrix' ) || isempty( obj.sc.stimuli(iStim).eventMatrix ),
                    obj.sc.stimuli(iStim).eventMatrix = zeros( obj.sc.stimuli(iStim).nStates );
                end
                
                for iSt = 1:obj.sc.stimuli(iStim).nStates,
                    obj.sc.stimuli(iStim).states(iSt).nViews = numel( obj.sc.stimuli(iStim).states(iSt).views );
                    
                    %% Check and adjust (if necessary) viewSequence
                    % the period of each state of a sprite can be specified independently from the
                    % sprite desired period
                    if ~isfield( obj.sc.stimuli(iStim).states(iSt), 'viewSequence' ) || isempty( obj.sc.stimuli(iStim).states(iSt).viewSequence ),
                        obj.sc.stimuli(iStim).states(iSt).viewSequence = 1:obj.sc.stimuli(iStim).states(iSt).nViews;
                    end
                    
                    obj.sc.stimuli(iStim).states(iSt).viewSequenceLength = numel( obj.sc.stimuli(iStim).states(iSt).viewSequence );
                    obj.sc.stimuli(iStim).states(iSt).iCurrentViewInSequence = 1;
                    
                    
                    % stimulus state flickering frequency [Hz]
                    if ~isfield( obj.sc.stimuli(iStim).states(iSt), 'frequency' ) || isempty( obj.sc.stimuli(iStim).states(iSt).frequency ),
                        obj.sc.stimuli(iStim).states(iSt).frequency = obj.sc.stimuli(iStim).default.frequency;
                    end
                    
                    % stimulus state initial phase of flickering [radian]
                    if ~isfield( obj.sc.stimuli(iStim).states(iSt), 'initialPhase' ) || isempty( obj.sc.stimuli(iStim).states(iSt).initialPhase ),
                        obj.sc.stimuli(iStim).states(iSt).initialPhase = obj.sc.stimuli(iStim).default.initialPhase;
                    end
                    
                    % stimulus state position
                    if ~isfield( obj.sc.stimuli(iStim).states(iSt), 'position' ) || isempty( obj.sc.stimuli(iStim).states(iSt).position ),
                        obj.sc.stimuli(iStim).states(iSt).position = obj.sc.stimuli(iStim).desired.position;
                    end
                    
                    
                    for iV = 1:obj.sc.stimuli(iStim).states(iSt).nViews,
                        if ~isfield( obj.sc.stimuli(iStim).states(iSt).views(iV), 'iTexture' ) || isempty( obj.sc.stimuli(iStim).states(iSt).views(iV).iTexture ),
                            obj.sc.stimuli(iStim).states(iSt).views(iV).iTexture = 0;
                        end;
                        if ~isfield( obj.sc.stimuli(iStim).states(iSt).views(iV), 'cropRect' ) || obj.sc.stimuli(iStim).states(iSt).views(iV).iTexture == 0,
                            obj.sc.stimuli(iStim).states(iSt).views(iV).cropRect = [];
                        end
                        
                        obj.sc.stimuli(iStim).states(iSt).views(iV).presentationStartTime = 0;
                        
                    end % of view loop
                    
                    
                    
                end % of state loop
                obj.sc.stimuli(iStim).iCurrentState = 1;
                
            end % of sprite loop
            
        end % of method UNFOLDSCENARIO

        %----------------------------------------------------------------------------
        function updateScenario( obj )
            
            logThis( 'Trying to update scenario [%s]', obj.sc.description )
            
            if isempty( obj.scr ),
                warning( 'sten:updateScenario:PTBnotInitialized', ...
                    'STEN: Psychotoolbox graphics was not initialized. Using default/desired values.' );
                obj.scr = obj.sc.desired.scr;
                horScaler = 1;
                verScaler = 1;
            else
                horScaler = obj.scr.nCols / obj.sc.desired.scr.nCols;
                verScaler = obj.scr.nRows / obj.sc.desired.scr.nRows;
            end
            scaler = [horScaler verScaler horScaler verScaler];
            
            obj.stateTimingMargin = 0.5*obj.scr.flipInterval;
            
            % Visual stimuli --------------------------
            for iStim = obj.sc.visualStimuliList,
                if ~isfield( obj.sc.stimuli(iStim), 'isVisible' ) || isempty(obj.sc.stimuli(iStim).isVisible),
                    obj.sc.stimuli(iStim).isVisible = true;
                end
                
                obj.sc.stimuli(iStim).actual.position = obj.sc.stimuli(iStim).desired.position .* scaler;
                
                if isfield( obj.sc.stimuli(iStim).desired, 'posAdjust'),
                    obj.sc.stimuli(iStim).actual.posAdjust = obj.sc.stimuli(iStim).desired.posAdjust .* scaler;
                else
                    obj.sc.stimuli(iStim).actual.posAdjust = [0 0 0 0];
                end
                
                obj.sc.stimuli(iStim).isMoving = ( sum( abs( obj.sc.stimuli(iStim).actual.posAdjust ) ) > 0 );

                for iSt = 1:obj.sc.stimuli(iStim).nStates,
                    obj.sc.stimuli(iStim).states(iSt).iCurrentViewInSequence = 1;
                    obj.sc.stimuli(iStim).states(iSt).position = obj.sc.stimuli(iStim).states(iSt).position .* scaler;
                end % of loop over stimulus states
                
                % states of the stimulus
                obj.sc.stimuli(iStim).nStates = numel( obj.sc.stimuli(iStim).states );
                obj.sc.stimuli(iStim).stateSequenceLength = numel( obj.sc.stimuli(iStim).stateSequence );
                obj.sc.stimuli(iStim).iStateInSequence = 1;
                obj.sc.stimuli(iStim).iCurrentState = 1;
                
            end % of loop over visual stimuli

            if obj.sc.showProgressBar,
                obj.pb.frame.position   = [0 0 obj.scr.nCols 16]';
                obj.pb.frame.width      = obj.pb.frame.position(3) - obj.pb.frame.position(1) + 1;
                obj.pb.frame.height     = obj.pb.frame.position(4) - obj.pb.frame.position(2) + 1;
                obj.pb.frame.alpha      = 1;
                
                obj.pb.indicator.position = obj.pb.frame.position;
                obj.pb.indicator.width  = obj.pb.indicator.position(3) - obj.pb.indicator.position(1) + 1;
                obj.pb.indicator.height = obj.pb.indicator.position(4) - obj.pb.indicator.position(2) + 1;
                obj.pb.indicator.alpha  = .8;                
            end % of showProgressBar branch
            
        end % of method UPDATESCENARIO        
        
        %----------------------------------------------------------------------------
        function setFrequency( obj, frequency, stimuliList )
            if ~exist( 'stimuliList', 'var' ) || isempty( stimuliList ),
                stimuliList = 1:numel( obj.sc.stimuli );
            end
            logThis( 'Trying to set new frequency [%g]', frequency )
            
            for iStim = stimuliList,
                for iSt = 1:numel( obj.sc.stimuli(iStim).states ),
                    obj.sc.stimuli(iStim).states(iSt).frequency = frequency;
                end % of loop over stimulus states
            end % of loop over visual stimuli
            
        end % of method SETFREQUENCY
        
        %-----------------------------------------------
        function setPresentationDuration( obj, newDuration )
            logThis( 'Trying to set new presentation duration to  %g seconds', newDuration )
            prevDuration = obj.sc.desired.stimulationDuration;
            obj.sc.desired.stimulationDuration = newDuration;
            for iStim = 1:numel( obj.sc.stimuli ),
                if isfield( obj.sc.stimuli(iStim), 'durationSequenceInSec' ),
                    obj.sc.stimuli(iStim).durationSequenceInSec = obj.sc.stimuli(iStim).durationSequenceInSec * newDuration/prevDuration;
                end
                if isfield( obj.sc.stimuli(iStim), 'durationSequenceInMs' ),
                    obj.sc.stimuli(iStim).durationSequenceInMs = obj.sc.stimuli(iStim).durationSequenceInMs * newDuration/prevDuration;
                end
            end % of loop over visual stimuli
            
        end % of method SETPRESENTATIONDURATION
        
        %-----------------------------------------------        
        function initGraph( obj )
            
            logThis( 'Trying to initialize PTB graphics.' )
            try
% % % % %                 Screen( 'Preference', 'Verbosity', 0 );
% % % % %                 if obj.nFramesForSyncTest > 0,
% % % % %                     Screen( 'Preference', 'SkipSyncTests', 1 );
% % % % %                 else
% % % % %                     Screen( 'Preference', 'SkipSyncTests', 2 );
% % % % %                 end
                if numel( obj.availableScreenList ) == 1,
                    [obj.pPTBwin, winRect] = Screen( 'OpenWindow', 0, 0, obj.windowRectangle );
                    %                     [obj.pPTBwin, winRect] = Screen( 'OpenWindow', 0, 0, [960 0 1920 600] );
                else
                    [obj.pPTBwin, winRect] = Screen( 'OpenWindow', obj.desiredScreenID, 0, [], obj.windowRectangle );
                end
                
                %                 HideCursor()
                Screen( 'BlendFunction', obj.pPTBwin, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
                obj.scr.flipInterval = Screen( 'GetFlipInterval', obj.pPTBwin, obj.nFramesForSyncTest );
                obj.scr.FPS  = 1 / obj.scr.flipInterval;
                obj.scr.nCols = winRect(3);
                obj.scr.nRows = winRect(4);
                logThis( 'PTB graphics was successfully initialized' )
                
            catch%#ok<*CTCH>
                Screen( 'CloseAll' );
                logThis( 'FAILED to initialize PTB graphics. Exiting.' )
                psychrethrow( psychlasterror );
                return
                
            end
            
            logThis( 'Graphics stats: flip-interval:%-8.6f ms   frame-rate:%-8.5f Hz  Number of frames for test: %g', ...
                1000*obj.scr.flipInterval, obj.scr.FPS, obj.nFramesForSyncTest );
            
            logThis( 'Screen data: width:%g px    height:%g px', obj.scr.nCols, obj.scr.nRows );
            
        end % of method INITGRAPHICS
        
        %-----------------------------------------------
        function closeGraph( obj )
            Screen( 'Close', obj.pPTBwin );
            Screen( 'CloseAll' );
            logThis( 'PTB graphics was successfully closed' );
        end % of method CLOSEGRAPH
        
        %-----------------------------------------------
        function loadTextures( obj )
            
            if ~isfield( obj.sc, 'texturesDir' ),
                obj.sc.texturesDir = obj.defaultTexturesDir;
            end
            
            % check for absolute path
            if  ( ispc && numel( obj.sc.texturesDir )>1 && obj.sc.texturesDir(2) == ':' ) || ...
                    ( isunix && numel( obj.sc.texturesDir )>0 && obj.sc.texturesDir(1) == '/' ),
                fullTexturesDir = obj.sc.texturesDir;
            else
                fullTexturesDir = [ obj.sc.scenarioDir  obj.sc.texturesDir ];
            end
            
            if (fullTexturesDir(end) ~= '/' && fullTexturesDir(end) ~= '\'),
                fullTexturesDir = [fullTexturesDir filesep()];
            end
            
            if ~exist( fullTexturesDir, 'dir' ),
                error('sten:loadTextures:wrongTexturesDir', ...
                    'STEN: Wrong or not existing textures directory: %s', fullTexturesDir );
            end
            
            logThis( 'Loading textures from directory: %s', fullTexturesDir );
            
            for iT = 1:obj.sc.nTextures,
                textureFullFilename = [fullTexturesDir obj.sc.textures(iT).filename];
                try
%                     obj.sc.textures(iT).image = readTextureFromPNG( textureFullFilename );
                    obj.sc.textures(iT).image = loadTexture( textureFullFilename );
                    logThis('   texture#%03d loaded from file [%s]', iT, textureFullFilename );
                    obj.sc.textures(iT).isLoaded = true;
                catch %#ok<CTCH>
                    logThis( 'FAILED to load texture#%03d from file [%s]', iT, textureFullFilename );
                    obj.sc.textures(iT).image = [];
                    obj.sc.textures(iT).isLoaded = false;
                end % of try load texture
                
            end % of texture loop
            
            if obj.sc.showProgressBar,
                textureFullFilename = [ obj.fullPathToSten 'private/progress-bar.png' ];
                logThis('Loading progress-bar texture from file [%s]', textureFullFilename );
%                 obj.pb.frame.image      = readTextureFromPNG( textureFullFilename );
                obj.pb.frame.image      = loadTexture( textureFullFilename );
                obj.pb.indicator.image  = reshape( uint8( [255 255 0 255] ), [1 1 4] );
                obj.pb.indicator.srcRect= [0 0 1 1]';
                obj.pb.frame.srcRect    = [1 1 size( obj.pb.frame.image, 2 ) size( obj.pb.frame.image, 1 )]';
            end
            
        end % of method LOADTEXTURES

        
        %-----------------------------------------------
        function loadTexturesToPTB( obj )
            
            logThis( 'Loading textures to PTB' );
            emptyTexture = zeros( 1, 1, 4 );
            
            for iTex = 1:obj.sc.nTextures,
                
                if obj.sc.textures(iTex).isLoaded,
                    textureData = obj.sc.textures(iTex).image;
                else
                    obj.sc.textures(iTex).image = emptyTexture;
                end
                
                obj.sc.textures(iTex).pPTB = Screen( 'MakeTexture', obj.pPTBwin, textureData );
                obj.sc.textures(iTex).isLoadedToPTB = true;
                
            end % of texture loop
            
            if obj.sc.showProgressBar,
                obj.pb.frame.pPTB = Screen( 'MakeTexture', obj.pPTBwin, obj.pb.frame.image );
                obj.pb.indicator.pPTB = Screen( 'MakeTexture', obj.pPTBwin, obj.pb.indicator.image );
            end % of showProgressBar branch

            if obj.showLogo,
                
                obj.logo.pPTB = Screen( 'MakeTexture', obj.pPTBwin, obj.logo.image );
                if obj.sc.showProgressBar,
                    obj.logo.position = [obj.scr.nCols-size( obj.logo.image, 2 )+1 obj.scr.nRows-size( obj.logo.image, 1 )+1 obj.scr.nCols obj.scr.nRows];
                else
                    obj.logo.position = [obj.scr.nCols-size( obj.logo.image, 2 )+1 0 obj.scr.nCols size( obj.logo.image, 1 )];
                end
                obj.logo.srcRect = [0 0 size( obj.logo.image, 2) size( obj.logo.image, 1 )]';
                obj.logo.alpha = 0.5;
            end
            
            for iStim = obj.sc.visualStimuliList, %#ok<*PROP>
                for iState = 1:numel( obj.sc.stimuli(iStim).states ),
                    for iView = 1:numel( obj.sc.stimuli(iStim).states(iState).views ),
                        cropRect = obj.sc.stimuli(iStim).states(iState).views(iView).cropRect;
                        if isempty( cropRect ),
                            iTex = obj.sc.stimuli(iStim).states(iState).views(iView).iTexture;
                            if (iTex > 0) && (iTex <= obj.sc.nTextures),
                                texSize = size( obj.sc.textures(iTex).image );
%                                 cropRect = [0 0 texSize(1) texSize(2)]';
                                cropRect = [0 0 texSize(2) texSize(1)]';
                            else
                                cropRect = [0 0 0 0]';
                            end
                        else
                            cropRect = cropRect(:);
                        end
                        obj.sc.stimuli(iStim).states(iState).views(iView).cropRect = cropRect;
                    end % of loopp over views
                end % of loop over states
            end % of loop over stimuli
            
            
            logThis( 'Textures were succesfully loaded to PTB' );
            
        end % of method LOADTEXTURESTOPTB
        
        %-----------------------------------------------
        function warmUp( obj )
            
            logThis( 'Warming MATLAB up' );
            for i = 1:5,
                WaitSecs( .001 );
                [~, obj.lastFlipTime] = Screen( ...
                    'Flip', ...     % routine name
                    obj.pPTBwin, ...% [windowPtr]   ID of the onscreen window whose content should be shown at flip time
                    0, ...          % [when]        If set to zero (default), it will flip on the next possible retrace. If set to a value when > 0, it will flip at the first retrace after system time 'when' has been reached
                    0, ...          % [dontclear]   If set to 1, flip will not clear the framebuffer after Flip - this allows incremental drawing of stimuli. The default is zero, which will clear the framebuffer to background color after each flip. A value of 2 will prevent Flip from doing anything to the framebuffer after flip. This leaves the job of setting up the buffer to you - the framebuffer is in an undefined state after flip
                    0 ...           % [dontsync]    If set to zero (default), Flip will sync to the vertical retrace and will pause Matlabs execution until the Flip has happened. If set to 1, Flip will still synchronize stimulus onset to the vertical retrace, butwill *not* wait for the flip to happen: Flip returns immediately and all returned timestamps are invalid. A value of 2will cause Flip to show the stimulus *immediately* without waiting/syncing to the vertical retrace
                    );
                obj.dispatchEvents( 0, GetSecs() );
            end
            
        end % of method WARMUP
        
        %-----------------------------------------------
        function presentScenario( obj )
            obj.preparePresentation();
            obj.presentScenarioImmediately();
            obj.finishPresentation();
        end % of method PRESENTSCENARIO

        %-----------------------------------------------
        function presentScenarioOptimized( obj )
            obj.preparePresentationOptimized();
            obj.presentScenarioRightNow();
            obj.finishPresentation();
        end % of method PRESENTSCENARIO

        %-----------------------------------------------
        function preparePresentation( obj, nSessions, pauseBeforeFirstFlipInSecs )
            obj.dispatchEvents( obj.sc.events(obj.sc.iStartEvent).id, GetSecs() );
            if ~exist( 'nSessions', 'var' ) || isempty( nSessions ),
                nSessions = 1;
            end
            if ~exist( 'pauseBeforeFirstFlipInSecs', 'var' ) || isempty( pauseBeforeFirstFlipInSecs ),
                pauseBeforeFirstFlipInSecs = 0.100;
            end
            
%             obj.reinitPersVars = true;

            logThis( 'Presenting scenario "%s"', obj.sc.description )
            logThis( 'desired stimulation duration: %g sec', obj.sc.desired.stimulationDuration )
            
            
            obj.eventIdList = zeros( 1, obj.sc.nStimuli + 1 );
            obj.nLocalEvents = 0;

            obj.resetPresentation();
            nFramesToRender = ceil( obj.sc.desired.stimulationDuration / obj.scr.flipInterval );
            
            nVisualObjects = numel( obj.sc.visualStimuliList );
            
            if obj.sc.showProgressBar,
                nVisualObjects = nVisualObjects + 2;
            end % of showProgressBar branch

            % deprecated...
            obj.texAlphas       = zeros( 1, nVisualObjects );  
            obj.texPTBpointers  = zeros( 1, nVisualObjects );  
            obj.texSrcRects     = zeros( 4, nVisualObjects );
            obj.texTrgPositions = zeros( 4, nVisualObjects );
            obj.iTex            = 0;
            

            nExpectedTotalFramesToRender = nSessions*nFramesToRender+100;
            % Log-arrays
            obj.frameRenderDurationLog = nan( 1, nExpectedTotalFramesToRender ); % add some extra frames, to avoid re-allocation
            obj.flipTimeLog           = nan( 1, nExpectedTotalFramesToRender );
            obj.texAlphaLog           = nan( nVisualObjects, nExpectedTotalFramesToRender );
            
            
            % warming up
            obj.processEvents = false;
            obj.globalAlphaScaler = 0;
            stimulationDuration = obj.sc.desired.stimulationDuration;
            Priority( 1 );
            for iFr = 1:3, 
                [~, obj.lastFlipTime] = Screen( ...
                    'Flip', ...     % routine name
                    obj.pPTBwin, ...% [windowPtr]   ID of the onscreen window whose content should be shown at flip time
                    0, ...          % [when]        If set to zero (default), it will flip on the next possible retrace. If set to a value when > 0, it will flip at the first retrace after system time 'when' has been reached
                    0, ...          % [dontclear]   If set to 1, flip will not clear the framebuffer after Flip - this allows incremental drawing of stimuli. The default is zero, which will clear the framebuffer to background color after each flip. A value of 2 will prevent Flip from doing anything to the framebuffer after flip. This leaves the job of setting up the buffer to you - the framebuffer is in an undefined state after flip
                    0 ...           % [dontsync]    If set to zero (default), Flip will sync to the vertical retrace and will pause Matlabs execution until the Flip has happened. If set to 1, Flip will still synchronize stimulus onset to the vertical retrace, butwill *not* wait for the flip to happen: Flip returns immediately and all returned timestamps are invalid. A value of 2will cause Flip to show the stimulus *immediately* without waiting/syncing to the vertical retrace
                    );
            end % of warm up loop
            obj.sc.desired.stimulationDuration = 2*obj.scr.flipInterval;
            obj.presentationStartTime = obj.lastFlipTime + 2*obj.scr.flipInterval;
%             obj.presentScenarioImmediately();        % first "warming-up" call
            obj.presentScenarioRightNow();        % first "warm-up" call

            obj.presentationStartTime = obj.lastFlipTime + 2*obj.scr.flipInterval;
            obj.presentScenarioRightNow();        % second "warm-up" call

            obj.resetPresentation();
            
            obj.globalAlphaScaler = 1;
            % the upcoming stimulation will start no earlier then this time
            obj.presentationStartTime  = obj.lastFlipTime + obj.scr.flipInterval*ceil( pauseBeforeFirstFlipInSecs/obj.scr.flipInterval );
            obj.sc.desired.stimulationDuration = stimulationDuration;
            obj.processEvents = true;

        end % of method PREPAREPRESENTATION        
        %-----------------------------------------------
        function preparePresentationOptimized( obj, pauseBeforeFirstFlipInSecs )

            if ~exist( 'pauseBeforeFirstFlipInSecs', 'var' ) || isempty( pauseBeforeFirstFlipInSecs ),
                pauseBeforeFirstFlipInSecs = 0.100;
            end
            
            logThis( 'Presenting scenario "%s"', obj.sc.description )
            logThis( 'desired stimulation duration: %g sec', obj.sc.desired.stimulationDuration )
            
            nFramesToRender = ceil( obj.sc.desired.stimulationDuration / obj.scr.flipInterval );
            nVisualStimuli = numel( obj.sc.visualStimuliList );
            
            if obj.sc.showProgressBar,
                nVisualObjects = nVisualStimuli + 2;
            else
                nVisualObjects = nVisualStimuli;
            end % of showProgressBar branch

            nExpectedTotalFramesToRender = nFramesToRender+100;
            % Log-arrays
            obj.frameRenderDurationLog  = nan( 1, nExpectedTotalFramesToRender ); % add some extra frames, to avoid re-allocation
            obj.flipTimeLog             = nan( 1, nExpectedTotalFramesToRender );
            obj.texAlphaLog             = nan( nVisualObjects, nExpectedTotalFramesToRender );
            
            
            % save the original parameters of the presenatation for warming up
            originalGlobalAlphaScaler   = obj.globalAlphaScaler;
            originalEventDispatcher     = obj.dispatchEvents;
            originalStimulationDuration = obj.sc.desired.stimulationDuration;
            originalDurationSequencies  = cell( 1, nVisualStimuli );
            originalStateSequencies     = cell( 1, nVisualStimuli );

            % substitute the original parameters with warm-up parameters
            warmUpDurationInFlips = 5;
            obj.dispatchEvents = @dummyEventDispatcher;
            obj.globalAlphaScaler = 0;            
            obj.sc.desired.stimulationDuration = warmUpDurationInFlips*obj.scr.flipInterval;
            warmUpStateDuration = obj.sc.desired.stimulationDuration/warmUpDurationInFlips;
            for iVisStim = 1:nVisualStimuli,
                iStim = obj.sc.visualStimuliList(iVisStim);

                originalDurationSequencies{iVisStim} = obj.sc.stimuli(iStim).durationSequenceInSec;
                obj.sc.stimuli(iStim).durationSequenceInSec = warmUpStateDuration(ones( 1, obj.sc.stimuli(iStim).stateSequenceLength ));

                originalStateSequencies{iVisStim} = obj.sc.stimuli(iStim).stateSequence;
                obj.sc.stimuli(iStim).stateSequence = repeatAndCropVector( 1:obj.sc.stimuli(iStim).nStates, obj.sc.stimuli(iStim).stateSequenceLength );
            end % of loop over visual stimuli
            obj.resetPresentation();

            Priority( 1 );

            obj.presentationStartTime = obj.lastFlipTime + 2*obj.scr.flipInterval;
            obj.reinitPersVars = true;            
            obj.presentScenarioRightNow();        % warm-up

            % recover the original parameters
            obj.globalAlphaScaler = originalGlobalAlphaScaler;
            obj.dispatchEvents = originalEventDispatcher;
            for iVisStim = 1:nVisualStimuli,
                iStim = obj.sc.visualStimuliList(iVisStim);
                obj.sc.stimuli(iStim).durationSequenceInSec = originalDurationSequencies{iVisStim};                
                obj.sc.stimuli(iStim).stateSequence = originalStateSequencies{iVisStim};
            end
            obj.resetPresentation();

            % the upcoming stimulation will start no earlier then this time
            obj.presentationStartTime  = obj.lastFlipTime + obj.scr.flipInterval*ceil( pauseBeforeFirstFlipInSecs/obj.scr.flipInterval );
            obj.sc.desired.stimulationDuration = originalStimulationDuration;
            obj.dispatchEvents( obj.sc.events(obj.sc.iStartEvent).id );

        end % of method PREPAREPRESENTATION        

        %-----------------------------------------------
        function resetPresentation( obj )
            obj.iFrame = 0;
            for iStim = obj.sc.visualStimuliList, %#ok<*PROP>
                obj.sc.stimuli(iStim).previousEventId = nan;
                obj.sc.stimuli(iStim).iStateInSequence = inf;
                obj.sc.stimuli(iStim).iCurrentState = obj.sc.stimuli(iStim).stateSequence(1);
            end
        end % of method RESETPRESENTATION        
        
        %-----------------------------------------------
        function presentScenarioImmediately( obj )
            entranceTime = GetSecs();
            iStim = 0; % preallocate iStim local variable
            iStartFrame = obj.iFrame;
            if entranceTime + obj.scr.flipInterval/2 > obj.presentationStartTime,
%                 logThis( '(presentationStartTime - now): %g', obj.presentationStartTime-entranceTime );
                obj.presentationStartTime = obj.presentationStartTime + ...
                     obj.scr.flipInterval*ceil( (entranceTime+obj.scr.flipInterval/2-obj.presentationStartTime) / obj.scr.flipInterval );
            end
            obj.whenToFlip = obj.presentationStartTime;
            obj.stopLoopTime = obj.presentationStartTime + obj.sc.desired.stimulationDuration; % preliminary estimate
            obj.lastFlipTime = obj.presentationStartTime - obj.scr.flipInterval; % just to proper obj.nextFlipTime est.
            while obj.lastFlipTime <= obj.stopLoopTime - obj.scr.flipInterval,
                obj.timeFrameRenderStart = GetSecs();
                obj.nextFlipTime = obj.lastFlipTime + obj.scr.flipInterval;
                obj.iTex = 0;
                for iStim = obj.sc.visualStimuliList,
                    if ~obj.sc.stimuli(iStim).isVisible,
                        continue
                    end
                    
                    obj.iSt = obj.sc.stimuli(iStim).iCurrentState;
                    
                    % check if current stimulus should change its state
                    if (obj.iFrame==iStartFrame) || obj.sc.stimuli(iStim).states(obj.iSt).stopTime - obj.nextFlipTime < obj.stateTimingMargin,
                        % change of stimulus' state
                        % update index of the next state in the state-sequence
                        obj.iSeq = obj.sc.stimuli(iStim).iStateInSequence;
                        if  obj.iSeq >= obj.sc.stimuli(iStim).stateSequenceLength,
                            obj.iSeq = 1;
                        else
                            obj.iSeq = obj.iSeq + 1;
                        end
                        
                        % save actual (previous) state index
                        iStPrev = obj.iSt;
                        
                        % get new (next) state index from the state-sequence
                        obj.iSt = obj.sc.stimuli(iStim).stateSequence(obj.iSeq);
                        obj.sc.stimuli(iStim).iCurrentState = obj.iSt;
%                         obj.sc.stimuli(iStim).states(iStPrev).position = obj.sc.stimuli(iStim).actual.position; % save prev. position
                        obj.sc.stimuli(iStim).actual.position = obj.sc.stimuli(iStim).states(obj.iSt).position;  % load new postion

                        if (obj.iFrame==iStartFrame),
                            obj.sc.stimuli(iStim).states(obj.iSt).startTime = obj.nextFlipTime;
                        else
                            obj.sc.stimuli(iStim).states(obj.iSt).startTime = obj.sc.stimuli(iStim).states(iStPrev).stopTime;
                        end
                        obj.sc.stimuli(iStim).states(obj.iSt).stopTime = obj.sc.stimuli(iStim).states(obj.iSt).startTime + ...
                            obj.sc.stimuli(iStim).durationSequenceInSec(obj.iSeq);
                        
                        if obj.processEvents,
                            % check if the change of state should trigger any event
                            obj.iEvent = obj.sc.stimuli(iStim).eventMatrix(iStPrev,obj.iSt);
                            if (obj.iEvent > 0) && (obj.sc.stimuli(iStim).previousEventId ~= obj.sc.events(obj.iEvent).id),
                                
                                if obj.sc.issueTimeBasedEvents,
                                    if (obj.iFrame==iStartFrame),
                                        % if it's a first frame of the current presentation, then the time-based event
                                        % should be treated as a frame-based one (stored in the local event list
                                        % [eventIdList] for this frame).
                                        obj.nLocalEvents = obj.nLocalEvents + 1;
                                        obj.eventIdList(obj.nLocalEvents) = obj.sc.events(obj.iEvent).id;
                                    else
                                        % if it's NOT a first frame, then the time-based event should be issued
                                        % immideately with appropriate timestamp [of the new state start time].
                                        obj.dispatchEvents( obj.sc.events(obj.iEvent).id, obj.sc.stimuli(iStim).states(obj.iSt).startTime );
                                    end
                                end % of time-based event handling branch
                                
                                if obj.sc.issueFrameBasedEvents,
                                    % TODO: consider corrected timestamps
                                    obj.nLocalEvents = obj.nLocalEvents + 1;
                                    obj.eventIdList(obj.nLocalEvents) = obj.sc.events(obj.iEvent).id + obj.sc.frameBasedEventIdAdjust;
                                end % of frame-based event handling branch
                                
                              obj.sc.stimuli(iStim).previousEventId = obj.sc.events(obj.iEvent).id;
                            end
%                             if (obj.iEvent > 0),
%                                 obj.sc.stimuli(iStim).previousEventId = obj.sc.events(obj.iEvent).id;
%                             end
                            
                        end
                        obj.sc.stimuli(iStim).iStateInSequence = obj.iSeq;
                        obj.sc.stimuli(iStim).states(obj.iSt).iCurrentViewInSequence = 1;
                        
                    end % of state change branch
                    

                    % select proper texture to draw
                    obj.iCF= obj.sc.stimuli(iStim).states(obj.iSt).iCurrentViewInSequence;
                    obj.iV = obj.sc.stimuli(iStim).states(obj.iSt).viewSequence(obj.iCF);
                    obj.iT = obj.sc.stimuli(iStim).states(obj.iSt).views(obj.iV).iTexture;
                    
                    % draw the texture (if necessary)
                    if ( obj.iT > 0 ),
    
                        obj.iTex = obj.iTex + 1;
                        obj.texPTBpointers(obj.iTex)    = obj.sc.textures(obj.iT).pPTB;
                        obj.texSrcRects(:,obj.iTex)     = obj.sc.stimuli(iStim).states(obj.iSt).views(obj.iV).cropRect;
                        obj.texTrgPositions(:,obj.iTex) = obj.sc.stimuli(iStim).actual.position';
                        
                        % compute actual phase of the stimulus in the current state
                        if obj.sc.correctStimulusAppearanceTime,
                            % Use corrected appearance time of the stimulus to the phase estimation
                            % compute stimulus appearance time correction (w.r.t. next flip)
                            obj.sc.stimuli(iStim).appearanceTimeCorrection = obj.scr.flipInterval * ...
                                (1 - (obj.sc.stimuli(iStim).actual.position(2) + obj.sc.stimuli(iStim).actual.position(4))/(2*obj.scr.nRows) ); 

                            % compute corrected stimulus phase
                            obj.sc.stimuli(iStim).actualPhase = obj.sc.stimuli(iStim).states(obj.iSt).initialPhase + ...
                                2*pi*obj.sc.stimuli(iStim).states(obj.iSt).frequency*(obj.nextFlipTime-obj.presentationStartTime-obj.sc.stimuli(iStim).appearanceTimeCorrection);
                        else
                            % compute UNCORRECTED stimulus phase (estimated using next flip time)
                            obj.sc.stimuli(iStim).actualPhase = obj.sc.stimuli(iStim).states(obj.iSt).initialPhase + ...
                                2*pi*obj.sc.stimuli(iStim).states(obj.iSt).frequency*(obj.nextFlipTime-obj.presentationStartTime) ;
                        end
                        
                        % compute intensity (transparency) of the stimulus in the current state using previously
                        % computed stimulus "phase"
                        obj.texAlphas(obj.iTex) = ( 1 + cos( obj.sc.stimuli(iStim).actualPhase ) ) / 2;
                        
                        if obj.sc.useBinaryIntensity,
                            obj.texAlphas(obj.iTex) = round( obj.texAlphas(obj.iTex) );
                        end

                    end % of obj.iT>0 branch

                    % update stimulus position (if necessary)
                    if obj.sc.stimuli(iStim).isMoving,
                        obj.sc.stimuli(iStim).actual.position = obj.sc.stimuli(iStim).actual.position + obj.sc.stimuli(iStim).actual.posAdjust;
                    end % of moving stimulus branch
                    
                    % increment and update index of the current view in view-sequence
                    if obj.iCF >= obj.sc.stimuli(iStim).states(obj.iSt).viewSequenceLength,
                        obj.iCF = 1;
                    else
                        obj.iCF = obj.iCF + 1;
                    end
                    obj.sc.stimuli(iStim).states(obj.iSt).iCurrentViewInSequence = obj.iCF;
                    
                end % of loop over visual stimuli
                
                if obj.sc.showProgressBar,

                    obj.iTex = obj.iTex + 1;
                    obj.texPTBpointers(obj.iTex)    = obj.pb.indicator.pPTB;                    
                    obj.texSrcRects(:,obj.iTex)     = obj.pb.indicator.srcRect;
                    obj.texTrgPositions(:,obj.iTex) = obj.pb.indicator.position;
                    obj.texTrgPositions(3,obj.iTex) = obj.pb.indicator.position(1) + obj.pb.indicator.width * (obj.nextFlipTime - obj.presentationStartTime) / obj.sc.desired.stimulationDuration;
                    obj.texAlphas(obj.iTex)         = obj.pb.indicator.alpha;

                    obj.iTex = obj.iTex + 1;
                    obj.texPTBpointers(obj.iTex)    = obj.pb.frame.pPTB;                    
                    obj.texSrcRects(:,obj.iTex)     = obj.pb.frame.srcRect;
                    obj.texTrgPositions(:,obj.iTex) = obj.pb.frame.position;
                    obj.texAlphas(obj.iTex)         = obj.pb.frame.alpha;
                    
                end % of showProgressBar branch


                if obj.iTex > 0,
                    Screen( ...
                        'DrawTextures', ...                                     % draw textures routine
                        obj.pPTBwin, ...                                        % window pointer
                        obj.texPTBpointers(1:obj.iTex), ...                     % texture PTB pointers list
                        obj.texSrcRects(:,1:obj.iTex), ...                      % rectangular subparts of the texture to be drawn (default: full texture).
                        obj.texTrgPositions(:,1:obj.iTex),...                   % rectangular subparts of the window where the texture should be drawn
                        [], ...                                                 % rotation angle in degree for rotated drawing of the texture (default: 0)
                        1, ...                                                  % 0 = Nearest neighbour filtering, 1 = Bilinear filtering (default)
                        obj.globalAlphaScaler*obj.texAlphas(1:obj.iTex) ...     % transparency list 0 = fully transparent to 1 = fully opaque, defaults to one.
                        );                    
                end
               
                obj.timeFrameRenderFinish = GetSecs();
                if obj.nextFlipTime <= obj.stopLoopTime - obj.scr.flipInterval,
                    [~, obj.lastFlipTime] = Screen( ...
                        'Flip', ...         % routine name
                        obj.pPTBwin, ...    % [windowPtr]   ID of the onscreen window whose content should be shown at flip time
                        obj.whenToFlip, ... % [when]        If set to zero (default), obj.iT will flip on the next possible retrace. If set to a value when > 0, obj.iT will flip at the first retrace after system time 'when' has been reached
                        0, ...              % [dontclear]   If set to 1, flip will not clear the framebuffer after Flip - this allows incremental drawing of stimuli. The default is zero, which will clear the framebuffer to background color after each flip. A value of 2 will prevent Flip from doing anything to the framebuffer after flip. This leaves the job of setting up the buffer to you - the framebuffer is in an undefined state after flip
                        0 ...               % [dontsync]    If set to zero (default), Flip will sync to the vertical retrace and will pause Matlabs execution until the Flip has happened. If set to 1, Flip will still synchronize stimulus onset to the vertical retrace, butwill *not* wait for the flip to happen: Flip returns immediately and all returned timestamps are invalid. A value of 2 will cause Flip to show the stimulus *immediately* without waiting/syncing to the vertical retrace
                        );
                else
                    [~, obj.lastFlipTime] = Screen( ...
                        'Flip', ...         % routine name
                        obj.pPTBwin, ...    % [windowPtr]   ID of the onscreen window whose content should be shown at flip time
                        obj.whenToFlip, ... % [when]        If set to zero (default), obj.iT will flip on the next possible retrace. If set to a value when > 0, obj.iT will flip at the first retrace after system time 'when' has been reached
                        1, ...              % [dontclear]   If set to 1, flip will not clear the framebuffer after Flip - this allows incremental drawing of stimuli. The default is zero, which will clear the framebuffer to background color after each flip. A value of 2 will prevent Flip from doing anything to the framebuffer after flip. This leaves the job of setting up the buffer to you - the framebuffer is in an undefined state after flip
                        0 ...               % [dontsync]    If set to zero (default), Flip will sync to the vertical retrace and will pause Matlabs execution until the Flip has happened. If set to 1, Flip will still synchronize stimulus onset to the vertical retrace, butwill *not* wait for the flip to happen: Flip returns immediately and all returned timestamps are invalid. A value of 2 will cause Flip to show the stimulus *immediately* without waiting/syncing to the vertical retrace
                        );                    
                end
                
                if obj.processEvents && obj.nLocalEvents > 0,
                    obj.dispatchEvents( obj.eventIdList(1:obj.nLocalEvents), obj.lastFlipTime );
%                     logThis( 'nLocalEvents: %g, lastFlipTime: %10.4f', obj.nLocalEvents, obj.lastFlipTime );
                    obj.nLocalEvents = 0;
                end
                
                if (obj.iFrame == iStartFrame),
                    obj.presentationStartTime = obj.lastFlipTime;
                    obj.whenToFlip = 0;
                    obj.stopLoopTime = obj.presentationStartTime + obj.sc.desired.stimulationDuration; % - obj.stateTimingMargin;
                    
                    % update timings of all visible visual stimuli
                    for iStim = obj.sc.visualStimuliList,
                        if ~obj.sc.stimuli(iStim).isVisible,
                            continue
                        end                    
                        obj.iSt = obj.sc.stimuli(iStim).iCurrentState;
                        obj.iSeq = obj.sc.stimuli(iStim).iStateInSequence;
                        obj.sc.stimuli(iStim).states(obj.iSt).startTime = obj.presentationStartTime;
                        obj.sc.stimuli(iStim).states(obj.iSt).stopTime = obj.sc.stimuli(iStim).states(obj.iSt).startTime + obj.sc.stimuli(iStim).durationSequenceInSec(obj.iSeq);
                    end % of timings adjust loop
                    
                end % of first frame branch
                obj.iFrame = obj.iFrame + 1;
                obj.frameRenderDurationLog(obj.iFrame) = obj.timeFrameRenderFinish - obj.timeFrameRenderStart;
                
            end % main (time) loop
            
            if obj.processEvents,
                obj.dispatchEvents( obj.sc.events(obj.sc.iMainLoopStopEvent).id, obj.stopLoopTime );
            end

            [~, obj.lastFlipTime] = Screen( ...
                'Flip', ...     % routine name
                obj.pPTBwin, ...% [windowPtr]   ID of the onscreen window whose content should be shown at flip time
                0, ...          % [when]        If set to zero (default), obj.iT will flip on the next possible retrace. If set to a value when > 0, obj.iT will flip at the first retrace after system time 'when' has been reached
                0, ...          % [dontclear]   If set to 1, flip will not clear the framebuffer after Flip - this allows incremental drawing of stimuli. The default is zero, which will clear the framebuffer to background color after each flip. A value of 2 will prevent Flip from doing anything to the framebuffer after flip. This leaves the job of setting up the buffer to you - the framebuffer is in an undefined state after flip
                0 ...           % [dontsync]    If set to zero (default), Flip will sync to the vertical retrace and will pause Matlabs execution until the Flip has happened. If set to 1, Flip will still synchronize stimulus onset to the vertical retrace, butwill *not* wait for the flip to happen: Flip returns immediately and all returned timestamps are invalid. A value of 2 will cause Flip to show the stimulus *immediately* without waiting/syncing to the vertical retrace
                );
            
            obj.presentationStopTime = obj.lastFlipTime;
            obj.nextFlipTime = obj.presentationStopTime + obj.scr.flipInterval;
        end % of method PRESENTSCENARIOIMMEDIATELY        

        %-----------------------------------------------
        function exitStatus = presentScenarioRightNow( obj )
            persistent iViewTex iStim nTexturesToRender nTexturesToLog nVisualObjects stimuliToRenderIndices ...
                texPTBpointers initialAlphas finalAlphas texSrcRects texTrgPositions whenToFlip lastFlipTime ...
                iStartFrame iFrame iEvent iState iPrevState iStateInSequence ...
                previousEventId eventQueueLength eventQueue eventId...
                expectedLoopEndTime expectedNextFlipTime expectedPresentationStartTime frameRenderFinishTime ...
                frameRenderStartTime mainPartEntranceTime ...
                pbIndicatorPTB pbIndicatorSrcRect pbIndicatorPosition pbIndicatorWidth pbIndicatorAlpha ...
                pbFramepPTB pbFrameSrcRect pbFramePosition pbFrameAlpha pPTBwin ...
                logoPTB logoSrcRect logoPosition logoAlpha ...
                exitKey exitKeyPressed keyIsDown keyCode ... screenshotKey
            
            if obj.reinitPersVars,
                obj.reinitPersVars = false;
                % Init persistent variables just to avoid allocation lag during main the presentation
                nTexturesToRender = 0;
                nTexturesToLog = nTexturesToRender;
                nVisualObjects = numel( obj.sc.visualStimuliList ) + 1;
                if obj.sc.showProgressBar,
                    nVisualObjects = nVisualObjects + 2;
                end % of showProgressBar branch

                stimuliToRenderIndices =    zeros( 1, nVisualObjects );
                eventId =                   0;
                previousEventId =           nan( 1, nVisualObjects );
                texPTBpointers =            stimuliToRenderIndices;
                initialAlphas =             stimuliToRenderIndices;
                finalAlphas =               initialAlphas;
                texSrcRects =               zeros( 4, nVisualObjects );
                texTrgPositions =           texSrcRects;
                
                whenToFlip = 0;
                lastFlipTime = 0; % obj.lastFlipTime;
                expectedLoopEndTime = 0;
                expectedNextFlipTime = 0; % obj.nextFlipTime;
                expectedPresentationStartTime = 0;
                frameRenderFinishTime = 0;
                frameRenderStartTime = 0;
                mainPartEntranceTime = 0;

                iViewTex = 0;
                iStim = 0;
                iStartFrame = 0; 
                iFrame = 0;
                iEvent = 0;
                iState = 0;
                iPrevState = 0;
                iStateInSequence = inf;
                eventQueueLength = 0;
                eventQueue = zeros( 1, nVisualObjects );
                
                pPTBwin = obj.pPTBwin;
                
                if obj.sc.showProgressBar,
                    pbIndicatorPTB        = obj.pb.indicator.pPTB;
                    pbIndicatorSrcRect    = obj.pb.indicator.srcRect;
                    pbIndicatorPosition   = obj.pb.indicator.position;
                    pbIndicatorWidth      = obj.pb.indicator.width;
                    pbIndicatorAlpha      = obj.pb.indicator.alpha;
                    pbFramepPTB           = obj.pb.frame.pPTB;
                    pbFrameSrcRect        = obj.pb.frame.srcRect;
                    pbFramePosition       = obj.pb.frame.position;
                    pbFrameAlpha          = obj.pb.frame.alpha;
                end
                if obj.showLogo,
                    logoPTB         = obj.logo.pPTB;
                    logoSrcRect     = obj.logo.srcRect;
                    logoPosition    = obj.logo.position;
                    logoAlpha       = obj.logo.alpha;
                end
                KbName( 'UnifyKeyNames' );
%                 rightKey                = KbName( 'rightArrow' );
%                 leftKey                 = KbName( 'leftArrow' );
%                 upKey                   = KbName( 'upArrow' );
%                 downKey                 = KbName( 'downArrow' );
                exitKey                 = KbName( 'escape' );
                screenshotKey           = KbName( 'p' );
                [ keyIsDown, ~, keyCode ] = KbCheck();
                exitKeyPressed = keyIsDown && keyCode(exitKey);

            end % of persistent variables initialization branch

            exitStatus = 0;
            exitKeyPressed = false;
            previousEventId = nan( 1, nVisualObjects );
            iStateInSequence = inf;
            iFrame = obj.iFrame;
            iStartFrame = iFrame;
            mainPartEntranceTime = GetSecs();
            expectedPresentationStartTime = obj.presentationStartTime;
            expectedPresentationStartTime = expectedPresentationStartTime + ...
                obj.scr.flipInterval*ceil( (mainPartEntranceTime+obj.scr.flipInterval/2-expectedPresentationStartTime) / obj.scr.flipInterval );

            whenToFlip = expectedPresentationStartTime;
            expectedLoopEndTime = expectedPresentationStartTime + obj.sc.desired.stimulationDuration; % preliminary estimate
            lastFlipTime = expectedPresentationStartTime - obj.scr.flipInterval; % just to proper obj.nextFlipTime est.
            while (~exitKeyPressed) && (lastFlipTime <= expectedLoopEndTime - obj.scr.flipInterval),
                frameRenderStartTime = GetSecs();
                [ keyIsDown, ~, keyCode ] = KbCheck();
                exitKeyPressed = keyIsDown && keyCode(exitKey);
                if exitKeyPressed,
                    exitStatus = 1;
                    break,
                end;
                
                expectedNextFlipTime = lastFlipTime + obj.scr.flipInterval;
                nTexturesToRender = 0;
                for iStim = obj.sc.visualStimuliList,
                    if ~obj.sc.stimuli(iStim).isVisible,
                        continue
                    end
                    
                    iState = obj.sc.stimuli(iStim).iCurrentState;
                    
                    % check if current stimulus should change its state
                    if (iFrame==iStartFrame) || obj.sc.stimuli(iStim).states(iState).stopTime - expectedNextFlipTime < obj.stateTimingMargin,
                        % change of stimulus' state
                        % update index of the next state in the state-sequence
                        iStateInSequence = obj.sc.stimuli(iStim).iStateInSequence;
                        if  iStateInSequence >= obj.sc.stimuli(iStim).stateSequenceLength,
                            iStateInSequence = 1;
                        else
                            iStateInSequence = iStateInSequence + 1;
                        end
                        
                        % save actual (previous) state index
                        iPrevState = iState;
                        
                        % get new (next) state index from the state-sequence
                        iState = obj.sc.stimuli(iStim).stateSequence(iStateInSequence);
                        obj.sc.stimuli(iStim).iCurrentState = iState;
%                         obj.sc.stimuli(iStim).states(iStPrev).position = obj.sc.stimuli(iStim).actual.position; % save prev. position
                        obj.sc.stimuli(iStim).actual.position = obj.sc.stimuli(iStim).states(iState).position;  % load new postion

                        if (iFrame==iStartFrame),
                            obj.sc.stimuli(iStim).states(iState).startTime = expectedNextFlipTime;
                        else
                            obj.sc.stimuli(iStim).states(iState).startTime = obj.sc.stimuli(iStim).states(iPrevState).stopTime;
                        end
                        obj.sc.stimuli(iStim).states(iState).stopTime = obj.sc.stimuli(iStim).states(iState).startTime + ...
                            obj.sc.stimuli(iStim).durationSequenceInSec(iStateInSequence);
                        
%                         if obj.processEvents,
                            % check if the change of state should trigger any event
                            iEvent = obj.sc.stimuli(iStim).eventMatrix(iPrevState,iState);
%                             if (obj.iEvent > 0) && (obj.sc.stimuli(iStim).previousEventId ~= obj.sc.events(obj.iEvent).id),
                            if (iEvent > 0),
                                eventId = obj.sc.events(iEvent).id;
%                                 logThis( 'eventId: %6g\tpreviousEventId(%d):%6g', eventId, iStim, previousEventId(iStim) );
                                if (previousEventId(iStim) ~= eventId ),

                                    if obj.sc.issueTimeBasedEvents,
                                        if (iFrame==iStartFrame),
                                            % if it's a first frame of the current presentation, then the time-based event
                                            % should be treated as a frame-based one (stored in the local event list
                                            % [eventIdList] for this frame).
                                            eventQueueLength = eventQueueLength + 1;
                                            eventQueue(eventQueueLength) = eventId;
                                        else
                                            % if it's NOT a first frame, then the time-based event should be issued
                                            % immideately with appropriate timestamp [of the new state start time].
                                            obj.dispatchEvents( eventId, obj.sc.stimuli(iStim).states(iState).startTime );
                                        end
                                    end % of time-based event handling branch

                                    previousEventId(iStim) = eventId;
                                end % if (previousEventId(iStim) ~= eventId ),
                            end % if (iEvent > 0),
%                         end % if obj.processEvents,
                        obj.sc.stimuli(iStim).iStateInSequence = iStateInSequence;
%                         obj.sc.stimuli(iStim).states(iState).iCurrentViewInSequence = 1;
                        
                    end % of state change branch
                    

                    % select proper texture to draw
                    iViewTex = obj.sc.stimuli(iStim).states(iState).views(1).iTexture;
                    
                    % draw the texture (if necessary)
                    if ( iViewTex > 0 ),
    
                        nTexturesToRender = nTexturesToRender + 1;
                        stimuliToRenderIndices(nTexturesToRender) = iStim;
                        texPTBpointers(nTexturesToRender)    = obj.sc.textures(iViewTex).pPTB;
                        texSrcRects(:,nTexturesToRender)     = obj.sc.stimuli(iStim).states(iState).views(1).cropRect;
                        texTrgPositions(:,nTexturesToRender) = obj.sc.stimuli(iStim).actual.position';
                        
                        % compute actual phase of the stimulus in the current state
                        if obj.sc.correctStimulusAppearanceTime,
                            % Use corrected appearance time of the stimulus to the phase estimation
                            % compute stimulus appearance time correction (w.r.t. next flip)
                            appearanceTimeCorrection = obj.scr.flipInterval * ...
                                (1 - (obj.sc.stimuli(iStim).actual.position(2) + obj.sc.stimuli(iStim).actual.position(4))/(2*obj.scr.nRows) ); 

                            % compute corrected stimulus phase
                            textureActualPhase = obj.sc.stimuli(iStim).states(iState).initialPhase + ...
                                2*pi*obj.sc.stimuli(iStim).states(iState).frequency*(expectedNextFlipTime-obj.sc.stimuli(iStim).states(iState).startTime-appearanceTimeCorrection);
                        else
                            % compute UNCORRECTED stimulus phase (estimated using next flip time)
                            textureActualPhase = obj.sc.stimuli(iStim).states(iState).initialPhase + ...
                                2*pi*obj.sc.stimuli(iStim).states(iState).frequency*(expectedNextFlipTime-obj.sc.stimuli(iStim).states(iState).startTime) ;
                        end
                        
                        % compute intensity (transparency) of the stimulus in the current state using previously
                        % computed stimulus "phase"
                        initialAlphas(nTexturesToRender) = ( 1 + cos( textureActualPhase ) ) / 2;
                    end % of iViewTex>0 branch

                    % update stimulus position (if necessary)
                    if obj.sc.stimuli(iStim).isMoving,
                        obj.sc.stimuli(iStim).actual.position = obj.sc.stimuli(iStim).actual.position + obj.sc.stimuli(iStim).actual.posAdjust;
                    end % of moving stimulus branch
                    
                end % of loop over visual stimuli
                if obj.sc.useBinaryIntensity,
                    initialAlphas = round( initialAlphas );
                end
                
                if obj.sc.showProgressBar,

                    nTexturesToRender = nTexturesToRender + 1;
                    texPTBpointers(nTexturesToRender)    = pbIndicatorPTB;                    
                    texSrcRects(:,nTexturesToRender)     = pbIndicatorSrcRect;
                    texTrgPositions(:,nTexturesToRender) = pbIndicatorPosition;
                    texTrgPositions(3,nTexturesToRender) = pbIndicatorPosition(1) + pbIndicatorWidth * (expectedNextFlipTime - expectedPresentationStartTime) / obj.sc.desired.stimulationDuration;
                    initialAlphas(nTexturesToRender)     = pbIndicatorAlpha;

                    nTexturesToRender = nTexturesToRender + 1;
                    texPTBpointers(nTexturesToRender)    = pbFramepPTB;                    
                    texSrcRects(:,nTexturesToRender)     = pbFrameSrcRect;
                    texTrgPositions(:,nTexturesToRender) = pbFramePosition;
                    initialAlphas(nTexturesToRender)     = pbFrameAlpha;
                    
                end % of showProgressBar branch

                if obj.showLogo,
                    nTexturesToRender = nTexturesToRender + 1;
                    texPTBpointers(nTexturesToRender)    = logoPTB;
                    texSrcRects(:,nTexturesToRender)     = logoSrcRect;
                    texTrgPositions(:,nTexturesToRender) = logoPosition;
                    initialAlphas(nTexturesToRender)     = logoAlpha;
                end
                
                finalAlphas(:) = 0;
                if nTexturesToRender > 0,
                    finalAlphas = obj.globalAlphaScaler*initialAlphas(1:nTexturesToRender);
                    Screen( ...
                        'DrawTextures', ...                         draw textures routine
                        pPTBwin, ...                                window pointer
                        texPTBpointers(1:nTexturesToRender), ...    texture PTB pointers list
                        texSrcRects(:,1:nTexturesToRender), ...     rectangular subparts of the texture to be drawn (default: full texture).
                        texTrgPositions(:,1:nTexturesToRender),...  rectangular subparts of the window where the texture should be drawn
                        [], ...                                     rotation angle in degree for rotated drawing of the texture (default: 0)
                        1, ...                                      0 = Nearest neighbour filtering, 1 = Bilinear filtering (default)
                        finalAlphas ...                             transparency list 0 = fully transparent to 1 = fully opaque, defaults to one.
                        );
                end
       
                
                frameRenderFinishTime = GetSecs();
                if expectedNextFlipTime <= expectedLoopEndTime - obj.scr.flipInterval,
                    [~, lastFlipTime] = Screen( ...
                        'Flip', ...     routine name
                        pPTBwin, ...    [windowPtr]   ID of the onscreen window whose content should be shown at flip time
                        whenToFlip, ... [when]        If set to zero (default), iViewTex will flip on the next possible retrace. If set to a value when > 0, iViewTex will flip at the first retrace after system time 'when' has been reached
                        0, ...          [dontclear]   If set to 1, flip will not clear the framebuffer after Flip - this allows incremental drawing of stimuli. The default is zero, which will clear the framebuffer to background color after each flip. A value of 2 will prevent Flip from doing anything to the framebuffer after flip. This leaves the job of setting up the buffer to you - the framebuffer is in an undefined state after flip
                        0 ...           [dontsync]    If set to zero (default), Flip will sync to the vertical retrace and will pause Matlabs execution until the Flip has happened. If set to 1, Flip will still synchronize stimulus onset to the vertical retrace, butwill *not* wait for the flip to happen: Flip returns immediately and all returned timestamps are invalid. A value of 2 will cause Flip to show the stimulus *immediately* without waiting/syncing to the vertical retrace
                        );
                else
                    [~, lastFlipTime] = Screen( ...
                        'Flip', ...     routine name
                        pPTBwin, ...    [windowPtr]   ID of the onscreen window whose content should be shown at flip time
                        whenToFlip, ... [when]        If set to zero (default), iViewTex will flip on the next possible retrace. If set to a value when > 0, iViewTex will flip at the first retrace after system time 'when' has been reached
                        1, ...          [dontclear]   If set to 1, flip will not clear the framebuffer after Flip - this allows incremental drawing of stimuli. The default is zero, which will clear the framebuffer to background color after each flip. A value of 2 will prevent Flip from doing anything to the framebuffer after flip. This leaves the job of setting up the buffer to you - the framebuffer is in an undefined state after flip
                        0 ...           [dontsync]    If set to zero (default), Flip will sync to the vertical retrace and will pause Matlabs execution until the Flip has happened. If set to 1, Flip will still synchronize stimulus onset to the vertical retrace, butwill *not* wait for the flip to happen: Flip returns immediately and all returned timestamps are invalid. A value of 2 will cause Flip to show the stimulus *immediately* without waiting/syncing to the vertical retrace
                        );
                    
                end
%                 if obj.processEvents && eventQueueLength > 0,
%                     obj.dispatchEvents( eventQueue(1:eventQueueLength), lastFlipTime );
% %                     logThis( 'nLocalEvents: %g, lastFlipTime: %10.4f', obj.nLocalEvents, obj.lastFlipTime );
%                     eventQueueLength = 0;
%                 end
                if eventQueueLength > 0,
                    obj.dispatchEvents( eventQueue(1:eventQueueLength), lastFlipTime );
%                     logThis( 'nLocalEvents: %g, lastFlipTime: %10.4f', obj.nLocalEvents, obj.lastFlipTime );
                    eventQueueLength = 0;
                end
                
                if (iFrame == iStartFrame),
                    obj.presentationStartTime = lastFlipTime;
                    whenToFlip = 0;
                    expectedLoopEndTime = lastFlipTime + obj.sc.desired.stimulationDuration; % - obj.stateTimingMargin;
                    
                    % update timings of all visible visual stimuli
                    for iStim = obj.sc.visualStimuliList,
                        if ~obj.sc.stimuli(iStim).isVisible,
                            continue
                        end                    
                        iState = obj.sc.stimuli(iStim).iCurrentState;
                        iStateInSequence = obj.sc.stimuli(iStim).iStateInSequence;
                        obj.sc.stimuli(iStim).states(iState).startTime = lastFlipTime;
                        obj.sc.stimuli(iStim).states(iState).stopTime = lastFlipTime + obj.sc.stimuli(iStim).durationSequenceInSec(iStateInSequence);
                    end % of timings adjust loop
                    
                end % of first frame branch
                iFrame = iFrame + 1;
                obj.frameRenderDurationLog(iFrame) = frameRenderFinishTime - frameRenderStartTime;
                obj.flipTimeLog(iFrame) = lastFlipTime;
                nTexturesToLog = nTexturesToRender;
                
                if obj.sc.showProgressBar,
                    nTexturesToLog = nTexturesToLog - 2;
                end
                if obj.showLogo,
                    nTexturesToLog = nTexturesToLog - 1;
                end
                
                if nTexturesToLog > 0,
                    obj.texAlphaLog(stimuliToRenderIndices(1:nTexturesToLog),iFrame) = finalAlphas(1:nTexturesToLog);
                end
            end % main (time) loop
            
%             if obj.processEvents,
                obj.dispatchEvents( obj.sc.events(obj.sc.iMainLoopStopEvent).id, expectedLoopEndTime );
%             end

            obj.iFrame = iFrame;
            [~, lastFlipTime] = Screen( ...
                'Flip', ...     % routine name
                pPTBwin, ...% [windowPtr]   ID of the onscreen window whose content should be shown at flip time
                0, ...          % [when]        If set to zero (default), iViewTex will flip on the next possible retrace. If set to a value when > 0, iViewTex will flip at the first retrace after system time 'when' has been reached
                0, ...          % [dontclear]   If set to 1, flip will not clear the framebuffer after Flip - this allows incremental drawing of stimuli. The default is zero, which will clear the framebuffer to background color after each flip. A value of 2 will prevent Flip from doing anything to the framebuffer after flip. This leaves the job of setting up the buffer to you - the framebuffer is in an undefined state after flip
                0 ...           % [dontsync]    If set to zero (default), Flip will sync to the vertical retrace and will pause Matlabs execution until the Flip has happened. If set to 1, Flip will still synchronize stimulus onset to the vertical retrace, butwill *not* wait for the flip to happen: Flip returns immediately and all returned timestamps are invalid. A value of 2 will cause Flip to show the stimulus *immediately* without waiting/syncing to the vertical retrace
                );

%             obj.frameRenderDurationLog(iFrame) = obj.timeFrameRenderFinish - obj.timeFrameRenderStart;
%             obj.flipTimeLog(iFrame) = obj.lastFlipTime;
%             if iTex>0,
%                 obj.texAlphaLog(1:iTex,iFrame) = finalAlphas(:);
%             end
            
            obj.lastFlipTime = lastFlipTime;
            obj.presentationStopTime = lastFlipTime;
%             obj.presentationStartTime = expectedPresentationStartTime;
            obj.nextFlipTime = obj.presentationStopTime + obj.scr.flipInterval;
            
        end % of method PRESENTSCENARIORIGHTNOW        

        %-----------------------------------------------
        function finishPresentation( obj )
            
            obj.dispatchEvents( obj.sc.events(obj.sc.iEndEvent).id, obj.presentationStopTime );
            obj.nLocalEvents = 0;
            
            Priority( 0 );
            logThis( 'Presentation is finished' );
            logThis( '(Last) presentation duration:             %10.3f seconds', obj.presentationStopTime-obj.presentationStartTime );
            logThis( 'Total number of presented frames:             %6g', obj.iFrame );            
            
            if obj.showPerformancePlot,
                plot( 1000*obj.frameRenderDurationLog(1:obj.iFrame) )
                ylabel( 'ms' );
                xlabel( '(video) frames' );
                title( 'Frame rendering time' );
                xlim( [1 obj.iFrame] );
            end % of showPerformancePlot branch
            
        end % of method FINISHPRESENTATION
    end % of public methods section
    
    methods ( Access = 'private' )
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
                    error( 'sten:parseInputParameters:UnknownParameterName', ...
                        'STEN: Unknown parameter name: "%s"', parameterName );
                elseif numel( iParameter ) > 1,
                    error( 'sten:parseInputParameters:AmbiguousParameterName', ...
                        'STEN: Ambiguous parameter name: "%s"', parameterName );
                else
                    switch( iParameter ),
                        case 1,  % screen
                            if isnumeric( parameterValue ) && numel( parameterValue ) == 1 && ...
                                    parameterValue >= min( obj.availableScreenList ) && ...
                                    parameterValue <= max( obj.availableScreenList ) && ...
                                    parameterValue == fix( parameterValue ),
                                obj.screenId = parameterValue;
                            else
                                error('sten:parseInputParameters:BadScreenID', ...
                                    'STEN: Wrong or missing value for desired screen ID.');
                            end
                            
                        case 3, % windowRectangle
                            if isempty( parameterValue ) || (isnumeric( parameterValue ) && numel( parameterValue ) == 4 && all( parameterValue >= 0 ) ),
                                obj.windowRectangle = parameterValue;
                                iArg = iArg + 1;
                            else
                                error('sten:parseInputParameters:BadWindowRectangle', ...
                                    'STEN: Wrong or missing value for desired screen window rectangle.');
                            end
                            
                        case 4, % showPerformancePlot
                            if isempty( parameterValue ) || (isnumeric( parameterValue ) || islogical( parameterValue )),
                                obj.showPerformancePlot = logical( parameterValue(1) );
%                                 iArg = iArg + 1;
                            else
                                error('sten:parseInputParameters:BadShowPerformancePlot', ...
                                    'STEN: Wrong or missing value for show-performance-plot flag.');
                            end
                            
                        case 5,  % logger
                            if isa( parameterValue, 'function_handle' ),
                                logThis = parameterValue;
                            else
                                error('sten:parseInputParameters:BadLoggerHandle', ...
                                    'STEN: Wrong or missing value for logger function handle.');
                            end
                            
                        case 7,  % showLogo
                            if isempty( parameterValue ) || (isnumeric( parameterValue ) || islogical( parameterValue )),
                                obj.showLogo = parameterValue;
%                                 iArg = iArg + 1;                                
                            else
                                error('sten:parseInputParameters:BadShowLogoValue', ...
                                    'STEN: Wrong or missing value for showLogo flag.');
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
    end % of private methods section
    
    
end % of STEN class definition
