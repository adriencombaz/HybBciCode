function baseExperiment

%%                        SCANNER PARAMETERS
%==========================================================================
subjectName                     = 'test';
saveData                        = true;
saveLog                         = true;
saveUnfoldedScenario            = true;
useLptPort                      = false;

nBlocksPerCond                  = 1;
nRounds                         = 1;
nSubroundsPerRound              = 2; %6; % 12
nRepetitions                    = 2; %1; % 10
stimDurationInSec               = [0.2 0.3];
fakeStimDurInSec                = 0.1;
gapDurationInSec                = 0;
initialPauseinSec               = 1;
cueDurationInSec                = 1;
pauseAfterCueInSec              = 1;
p300DelayInSec                  = 0.2;
pauseBetweenStagesInSec         = 1;
pauseBetweenRounds              = 2;
stimFreq                        = [12 15];

scenariosDir                    = 'scenarios/';
useBinaryIntensity              = true;
showLog                         = true;
correctStimulusAppearanceTime   = true;
showProgressBar                 = false;


if numel(stimDurationInSec) == 1
    stimDurationInSec = [stimDurationInSec stimDurationInSec];
end
if numel(gapDurationInSec) == 1
    gapDurationInSec = [gapDurationInSec gapDurationInSec];
end

if sum(stimDurationInSec) <= 0, error('stimuli duration should be > 0!!'); end
if sum(gapDurationInSec) < 0, error('gap duration should be >= 0!!'); end


%%                     INIT DIRECTORIES AND FILENAMES
%==========================================================================

% init host name
%--------------------------------------------------------------------------
if isunix,
    envVarName = 'HOSTNAME';
else
    envVarName = 'COMPUTERNAME';
end
hostName = lower( strtok( getenv( envVarName ), '.') );

% init paths
%--------------------------------------------------------------------------
switch hostName,
    case {'noone-laptop-xp', 'neu-wrk-0154'},
        eegDataDir  = 'd:/data/EEG-recordings/hydrid-P300-SSVEP/';
    case 'neu-wrk-0139',
        eegDataDir  = 'C:/home/adrien/KULeuven/PhD/EEG-recordings/hydrid-P300-SSVEP/';
    case 'neu-wrk-0161',
        eegDataDir  = 'C:/EEG-recordings/hydrid-P300-SSVEP/';
    case 'kuleuven-24b13c',
        eegDataDir  = 'd:/KULeuven/PhD/Work/EEG-Recording/hydrid-P300-SSVEP/';
    case 'neu-wrk-0158',
        eegDataDir  = 'd:/Adrien/hybrid-BCI-3-A-BaseExperiment-01/recordedData/';
    otherwise,
        eegDataDir  = './EEG-recordings/';
end

% init data directory
%--------------------------------------------------------------------------
currentTimeString = datestr( now, 31 );
currentTimeString(11:3:end) = '-';
currentDataDir = [eegDataDir currentTimeString(1:10) '-' strrep( subjectName, ' ', '-' ) '/'];
if ~exist( currentDataDir, 'dir' )
    mkdir( currentDataDir );
end


%%              SET UP THE LOGGER AND LOG EXPERIMENT INFO
%==========================================================================
logFilename  = fullfile( currentDataDir, [currentTimeString '-log.txt'] );

logThis( [], ...
    'logTimestamps', 'on', ...
    'logCallerInfo', 'on', ...
    'logFilename', logFilename, ...
    'logToFile', saveLog, ...
    'logToScreen', showLog ...
    );

logThis( 'Number of rounds                      %g', nRounds );
logThis( 'Number of subrounds in one round      %g', nSubroundsPerRound );
logThis( 'Number of repetitions                 %g', nRepetitions );
logThis( 'min stimulus duration [sec]           %g', stimDurationInSec(1) );
logThis( 'max stimulus duration [sec]           %g', stimDurationInSec(2) );
logThis( 'min gap duration [sec]                %g', gapDurationInSec(1) );
logThis( 'max gap duration [sec]                %g', gapDurationInSec(2) );
logThis( 'intial pause [sec]                    %g', initialPauseinSec );
logThis( 'cue duration [sec]                    %g', cueDurationInSec );
logThis( 'pause after cue [sec]                 %g', pauseAfterCueInSec );
logThis( 'p300 delay [sec]                      %g', p300DelayInSec );
logThis( 'Pause between rounds [sec]            %g', pauseBetweenRounds );
logThis( 'Pause between stages [sec]            %g', pauseBetweenStagesInSec );
logThis( 'Send markers through lpt port         %s', yesNo( useLptPort ) );
logThis( 'Show logs in console output           %s', yesNo( showLog ) );
logThis( 'Save logs to text file                %s', yesNo( saveLog ) );
logThis( 'Save data to mat file                 %s', yesNo( saveData ) );
logThis( 'Use binary (on/off) intensity profile %s', yesNo( useBinaryIntensity ) );
logThis( 'Save unfolded scenario                %s', yesNo( saveUnfoldedScenario ) );
logThis( 'Correct stimulus appearance time      %s', yesNo( correctStimulusAppearanceTime ) );
logThis( 'Show presentation progress bar        %s', yesNo( showProgressBar ) );



%%                    LIST OF EXPERIMENTAL CONDITIONS
%==========================================================================
conditions = { ...
    '0Hz P300 baseline' , ...
    sprintf('%dHz SSVEP baseline', stimFreq(1)), ...
    sprintf('%dHz SSVEP baseline', stimFreq(2)), ...
    sprintf('%dHz hybrid', stimFreq(1)), ...
    sprintf('%dHz hybrid', stimFreq(2)) ...
    };
scrPos = get(0, 'ScreenSize');
scenario = sprintf('Hybrid-01-SSVEP-06-P300-stim@%dx%d.xml', scrPos(3), scrPos(4));
instructions = { ...
    'Please count the number of times the red disk appears on the target item', ...
    'Please focus on the cross hair in the center of the screen', ...
    'Please focus on the cross hair in the center of the screen', ...
    'Please count the number of times the red disk appears on the target item', ...
    'Please count the number of times the red disk appears on the target item' ...
    };
SsvepFreqScen = [ ...
    0, ...
    stimFreq(1), ...
    stimFreq(2), ...
    stimFreq(1), ...
    stimFreq(2), ...
    ];
p3OnScen = [1 0 0  1 1];

%%                            INIT GRAPHICS
%==========================================================================
st = sten();
try
    st.initGraph();
catch%#ok<*CTCH>
    Screen( 'CloseAll' );
    logThis( 'Failed to initialize PTB graphics. Exiting' )
    psychrethrow( psychlasterror );
    return
end
HideCursor();



%%                            EXPERIMENT
%==========================================================================
nConds = numel(conditions);
nBlocks = zeros(1, nConds);
blockSequence = repmat(1:nConds, 1, nBlocksPerCond);
blockSequence = blockSequence(randperm(nConds*nBlocksPerCond));

for iBlock = 1:nConds*nBlocksPerCond
    
    % Display message
    %----------------------------------------------------------------------
    iCond = blockSequence(iBlock);
    textMsg = sprintf( ['Ready to run %s (block %d out of %d).\n%s\n' ...
        'Press any key to continue\n' ...
        ], ...
        conditions{iCond}, nBlocks(iCond)+1, nBlocksPerCond, instructions{iCond});
    DrawFormattedText(st.pPTBwin, textMsg, 'center', 'center', WhiteIndex(st.pPTBwin), [],[],[], 2);
    Screen('Flip', st.pPTBwin);
    WaitSecs(5); 
%     KbWait([], 3);
    Screen('Flip', st.pPTBwin);
    Screen('Close');
    
    
    % Experiment
    %----------------------------------------------------------------------
    tag = sprintf( '%s-block-%.2d', strrep( conditions{iCond}, ' ', '-' ), nBlocks(iCond)+1 );
    HybridScanner();
    
    % clear textures
    %----------------------------------------------------------------------
    Screen('Close');
        
    nBlocks(iCond) = nBlocks(iCond)+1;
end

% Done. Close Screen, release all resources:
logThis( 'Finishing and cleaning up' );

flipTimeLog = st.flipTimeLog;
frameRenderDurationLog = st.frameRenderDurationLog;

st.closeGraph();
ShowCursor();

mainDataFilename = fullfile( currentDataDir, [currentTimeString '-ExperimentDetail.txt'] );
save( mainDataFilename, ...
    'conditions', ...
    'scenario', ...
    'instructions', ...
    'SsvepFreqScen', ...
    'p3OnScen', ...
    'nBlocksPerCond', ...
    'blockSequence', ...
    'flipTimeLog', ...
    'frameRenderDurationLog' ...
    );

%% ========================================================================
%==========================================================================
%
%                    MAIN STIMULATION NESTED FUNCTION
%
%==========================================================================
%==========================================================================

    function HybridScanner()
        
        
        %% ================================================================
        %                       SCANNER PARAMETERS
        
        currentTimeString = datestr( now, 31 );
        currentTimeString(11:3:end) = '-';
        dataFilename = sprintf( '%s%s-%s.mat', currentDataDir, currentTimeString, tag );
        unScFilename = [dataFilename(1:end-4) '-unfolded-scenario.xml'];
        logThis('');
        logThis('');
        logThis('');
        logThis('');
        logThis('CONDITION:             %s (block %d out of %d)', ...
            conditions{iCond}, nBlocks(iCond)+1, nBlocksPerCond);

        
        %------------------------------------------------------------------
        % 
        SsvepFreq = SsvepFreqScen(iCond);
        
        
        %% ================================================================
        %                PREPARE THE STIMULATION ENGINE
        
        st.loadScenario( [scenariosDir scenario] );
                        
        iP300Stimuli        = find( cellfun( @(x) strcmp(x, 'P300 stimulus'), {st.sc.stimuli(:).description} ) );
        iLookHereStimulus   = find( cellfun( @(x) strcmp(x, 'Look here stimulus'), {st.sc.stimuli(:).description} ) );
        iSSVEPStimuli       = find( cellfun( @(x) strcmp(x, 'SSVEP stimulus'), {st.sc.stimuli(:).description} ) );
        iBackgroundStim     = find( cellfun( @(x) strcmp(x, 'Icons background'), {st.sc.stimuli(:).description} ) );
        
        %--------------------------------------------------------------
        % Check Scenario
        nSSVEP  = numel(iSSVEPStimuli);
        nP300   = numel(iP300Stimuli);
        nLook   = numel(iLookHereStimulus);
        nBgSt   = numel(iBackgroundStim);
        nElts   = numel(st.sc.stimuli(iP300Stimuli(1)).states) - 1;
        nItems  = numel(st.sc.stimuli(iLookHereStimulus).states) - 1;
        
        if nBgSt ~= 1, error('Not exactly one background stimulus'); end
        if nLook ~= 1, error('Not exactly one cue stimulus'); end
        if nSSVEP ~= 1, error('Not exactly one SSVEP stimulus'); end
        if nP300 ~= 1, error('Not exactly one P300 stimulus'); end
        
        for i = 1:nSSVEP
            st.setFrequency( SsvepFreq(i), iSSVEPStimuli(i) );
        end
        
            %--------------------------------------------------------------
            % generate state sequence and duration sequence
            p3StateSeq          = [];
            realP3StateSeqOnsets= [];
            p3DurationSeq       = [];
            lookHereStateSeq    = [];
            lookHereDurationSeq = [];
            SSVEPStateSeq       = [];
            SSVEPDurationSeq    = 0;
            
            % initial pause
            if initialPauseinSec > 0
                p3StateSeq          = nElts + 1;
                p3DurationSeq       = initialPauseinSec;
                lookHereStateSeq    = nItems + 1;
                lookHereDurationSeq = initialPauseinSec;
                SSVEPStateSeq       = 2;
                SSVEPDurationSeq    = initialPauseinSec;
            end
            
            
            
            cueList = repmat(1:nItems, 1, floor(nSubroundsPerRound/nItems));
            cueList = cueList(randperm(numel(cueList)));
            if floor(nSubroundsPerRound/nItems) ~= (nSubroundsPerRound/nItems)
                logThis( 'nElts does not divide nSubroundsPerRound, as a consequence the cue list will be unbalanced' );
                padd = randperm(nItems);
                cueList( numel(cueList)+1 : nSubroundsPerRound ) = padd( 1 : nSubroundsPerRound-numel(cueList) );
            end
            
            for iSR = 1:nSubroundsPerRound
                                    
                    iItem = cueList( iSR );
                    
                    % ------------------- indication cue ------------------
                    lookHereStateSeq    = [ lookHereStateSeq iItem ];
                    lookHereDurationSeq = [ lookHereDurationSeq cueDurationInSec ];
                    p3StateSeq          = [ p3StateSeq nElts+1 ];
                    p3DurationSeq       = [ p3DurationSeq cueDurationInSec ];
                    SSVEPStateSeq       = [ SSVEPStateSeq 2 ];
                    SSVEPDurationSeq    = [ SSVEPDurationSeq cueDurationInSec ];
                    
                    % ------------------ pause after cue ------------------
                    if pauseAfterCueInSec > 0
                        p3StateSeq              = [ p3StateSeq nElts+1 ];
                        p3DurationSeq           = [ p3DurationSeq pauseAfterCueInSec ];
                        SSVEPStateSeq           = [ SSVEPStateSeq 2 ];
                        SSVEPDurationSeq        = [ SSVEPDurationSeq pauseAfterCueInSec];
                        if p3OnScen(iCond)
                            lookHereStateSeq        = [ lookHereStateSeq nItems+1 ];
                            lookHereDurationSeq     = [ lookHereDurationSeq pauseAfterCueInSec ];
                        else % keep the cue on the target for the SSVEP baseline case
                            lookHereDurationSeq(end) = lookHereDurationSeq(end) + pauseAfterCueInSec;
                        end
                    end
                    
                    % -------------- start SSVEP before P300 --------------
                    if p300DelayInSec > 0
                        p3StateSeq              = [ p3StateSeq nElts+1 ];
                        p3DurationSeq           = [ p3DurationSeq p300DelayInSec ];
                        SSVEPStateSeq           = [ SSVEPStateSeq 1 ];
                        SSVEPDurationSeq        = [ SSVEPDurationSeq p300DelayInSec];
                        if p3OnScen(iCond)
                            lookHereStateSeq        = [ lookHereStateSeq nItems+1 ];
                            lookHereDurationSeq     = [ lookHereDurationSeq p300DelayInSec ];
                        else % keep the cue on the target for the SSVEP baseline case
                            lookHereDurationSeq(end) = lookHereDurationSeq(end) + p300DelayInSec;
                        end
                    end
                    
                    % --- P300 stimulation state and duration sequence ----
                    stateSeq = randperm(nItems);
                    for iRep = 2:nRepetitions
                        newSeq = randperm(nItems);
                        while stateSeq(end) == newSeq(1)
                            newSeq = randperm(nItems);
                        end
                        stateSeq = [ stateSeq newSeq ];
                    end
                    realP3StateSeqOnsets = [realP3StateSeqOnsets stateSeq];
                    stateSeq = 2*stateSeq-1;
                    
                    if sum(gapDurationInSec) > 0
                        stateSeq        = [stateSeq ; (2*nItems+1)*ones(size(stateSeq))];
                        stimDurationSeq = stimDurationInSec(1) + ( stimDurationInSec(2) - stimDurationInSec(1) ) .* rand( 1,size(stateSeq, 2) );
                        gapDurationSeq  = gapDurationInSec(1)  + ( gapDurationInSec(2)  - gapDurationInSec(1)  ) .* rand( 1,size(stateSeq, 2) );
                        durationSeq     = [stimDurationSeq ; gapDurationSeq];
                    else
                        stateSeq        = [stateSeq ; stateSeq+1];
                        realStimDur     = stimDurationInSec(1) + (stimDurationInSec(2)-stimDurationInSec(1)) .* rand( 1,size(stateSeq, 2) );
                        fakeOnDurSeq    = fakeStimDurInSec .* ones(1,size(stateSeq, 2));
                        fakeOffDurSeq   = realStimDur - fakeOnDurSeq;
                        durationSeq     = [fakeOnDurSeq ; fakeOffDurSeq];
                    end
                    p3StateSeq          = [ p3StateSeq stateSeq(:)' ];
                    p3DurationSeq       = [ p3DurationSeq durationSeq(:)' ];
                    SSVEPStateSeq       = [ SSVEPStateSeq 1 ];
                    SSVEPDurationSeq    = [ SSVEPDurationSeq sum(durationSeq(:)) ];
                    if p3OnScen(iCond)
                        lookHereStateSeq    = [ lookHereStateSeq nItems+1 ];
                        lookHereDurationSeq = [ lookHereDurationSeq sum(durationSeq(:)) ];
                    else % keep the cue on the target for the SSVEP baseline case
                        lookHereDurationSeq(end) = lookHereDurationSeq(end) + sum(durationSeq(:));
                    end
                    % ------------- Pause between stages ------------------
                    if pauseBetweenStagesInSec > 0
                        p3StateSeq                  = [ p3StateSeq nElts+1 ];
                        p3DurationSeq               = [ p3DurationSeq pauseBetweenStagesInSec ];
                        lookHereStateSeq            = [ lookHereStateSeq nItems+1 ];
                        lookHereDurationSeq         = [ lookHereDurationSeq pauseBetweenStagesInSec ];
                        SSVEPStateSeq               = [ SSVEPStateSeq 2 ];
                        SSVEPDurationSeq            = [ SSVEPDurationSeq pauseBetweenStagesInSec ];
                    end
                                    
            end
            
%             seqDuration = unique( [sum(p3DurationSeq) sum(lookHereDurationSeq) sum(SSVEPDurationSeq)] );
%             if numel(seqDuration) ~= 1
%                 error('sequences do not have the same lenght')
%             end
            
            [lookHereStateSeq lookHereDurationSeq] = shrinkSequence(lookHereStateSeq, lookHereDurationSeq);
            
            if SsvepFreq    % ssvep stimulation on (ssvep baseline, hybrid)
                [SSVEPStateSeq SSVEPDurationSeq] = shrinkSequence(SSVEPStateSeq, SSVEPDurationSeq);
            else            % ssvep stimulation off (p300 baseline)
                SSVEPStateSeq       = 1;
                SSVEPDurationSeq    = sum(lookHereDurationSeq);
            end
            
            if p3OnScen(iCond)  % p300 stimulation on (p300 baseline, hybrid)
                [p3StateSeq p3DurationSeq] = shrinkSequence(p3StateSeq, p3DurationSeq);
            else                % p300 stimulation off (ssvep baseline)
                p3StateSeq      = nElts+1;
                p3DurationSeq   = sum(lookHereDurationSeq);
            end
            
            
            for iS = 1:nP300
                st.sc.stimuli(iP300Stimuli(iS)).stateSequence               = p3StateSeq;
                st.sc.stimuli(iP300Stimuli(iS)).durationSequenceInSec       = p3DurationSeq;
            end
            for iS = 1:nSSVEP
                st.sc.stimuli(iSSVEPStimuli(iS)).stateSequence              = SSVEPStateSeq;
                st.sc.stimuli(iSSVEPStimuli(iS)).durationSequenceInSec      = SSVEPDurationSeq;
            end
            st.sc.stimuli(iLookHereStimulus).stateSequence          = lookHereStateSeq;
            st.sc.stimuli(iLookHereStimulus).durationSequenceInSec  = lookHereDurationSeq;
            st.sc.stimuli(iBackgroundStim).stateSequence            = 1;
            st.sc.stimuli(iBackgroundStim).durationSequenceInSec    = sum(p3DurationSeq);
            
            roundDurationInSec = sum(lookHereDurationSeq);
            st.sc.desired.stimulationDuration = roundDurationInSec;
            nMaxEvents = round( 2 * ( 2 + numel(p3StateSeq) + numel(lookHereStateSeq) + numel(SSVEPStateSeq) ) );
            
        
        st.sc.useBinaryIntensity            = useBinaryIntensity;
        st.sc.correctStimulusAppearanceTime = correctStimulusAppearanceTime;
        st.sc.showProgressBar               = showProgressBar;
        
        st.unfoldScenario();
        if saveUnfoldedScenario,
            logThis( 'Saving unfolded scenario to file %s' , unScFilename );
            st.saveScenario( unScFilename );
        end
        
        st.loadTextures();
        
        %% ================================================================
        %                 INIT BIOSEMILABELCHANNEL object
        
        labChan = biosemiLabelChannel( 'sizeListLabels', nMaxEvents , 'useTriggerCable', useLptPort);
        
        
        
        %% ================================================================
        %                        INIT GRAPHICS    
        
        st.updateScenario();
        st.loadTexturesToPTB();
        
        st.setEventDispatcher( @labChan.markEvent );
        
        pauseBetweenRoundsAjusted = floor( pauseBetweenRounds / st.scr.flipInterval ) * st.scr.flipInterval;
        logThis( 'Screen flip-interval:             %8.6f ms', st.scr.flipInterval );
        logThis( 'Screen frame-rate:                %8.5f Hz', st.scr.FPS );
        logThis( 'Screen size:                      %g x %g px', st.scr.nCols, st.scr.nRows );
        logThis( 'pauseBetweenRounds:             %9.6f s', pauseBetweenRounds );
        logThis( 'pauseBetweenRoundsAjusted:      %9.6f s', pauseBetweenRoundsAjusted );
        
%         st.preparePresentation( nRounds, 0.5 );
        st.preparePresentationOptimized();
        
        
        %% ================================================================
        %                         EXPERIMENT
        logThis( 'Flushing the device and presenting stimuli (experiment in progress)' );
        presentationStartTime = st.presentationStartTime;
        
        for iRound = 1:nRounds,
%             st.presentScenarioImmediately();
            st.presentScenarioRightNow();
            if iRound < nRounds,
                st.resetPresentation();
                st.presentationStartTime = st.presentationStopTime + pauseBetweenRoundsAjusted;
            end
        end % of loop over Rounds
        presentationFinishTime = st.presentationStopTime;
        
        st.finishPresentation();
        
        
        logThis( 'Presentation duration:         %8.3f seconds', presentationFinishTime-presentationStartTime );
        % labelList = labChan.getListLabels();
        
        %% ================================================================
        %                          FINISHING
        
        %------------------------------------------------
        % Saving data
        if saveData,
            logThis( 'Saving data into mat file: %s', dataFilename );
            screenInfo  = st.scr;
            labelList   = labChan.getListLabels();
            condition   = conditions{iCond};
            blockNb     = nBlocks(iCond)+1;
            listOfVariablesToSave = { ...
                'subjectName', ...
                'condition', ...
                'blockNb', ...
                'scenario', ...
                'tag', ...
                'labelList', ...
                'screenInfo', ...
                'SSVEPDurationSeq', ...
                'SSVEPStateSeq', ...
                'lookHereDurationSeq', ...
                'lookHereStateSeq', ...
                'correctStimulusAppearanceTime', ...
                'useBinaryIntensity', ...
                'SsvepFreq', ...
                'nRepetitions', ...
                'nRounds', ...
                'nSubroundsPerRound', ...
                'stimFreq', ...
                'initialPauseinSec', ...
                'cueDurationInSec', ...
                'pauseAfterCueInSec', ...
                'p300DelayInSec', ...
                'stimDurationInSec', ...
                'gapDurationInSec', ...
                'pauseBetweenStagesInSec', ...
                'pauseBetweenRounds', ...
                'pauseBetweenRoundsAjusted', ...
                'presentationFinishTime', ...
                'presentationStartTime' ...
                };
            
            if p3OnScen(iCond)
                listOfVariablesToSave = [listOfVariablesToSave , 'p3DurationSeq' , 'p3StateSeq', 'realP3StateSeqOnsets', 'fakeStimDurInSec'];
            end
            
            save( dataFilename, listOfVariablesToSave{:} );
        end % of saving data branch
        logThis( 'Round %g (out of %g) of subject %s is finished', iRound, nRounds, subjectName );
        
    end

end

%% ========================================================================
%                            ADDITIONAL FUNCTIONS

%--------------------------------------------------------------------------
%
%--------------------------------------------------------------------------
function strOut = yesNo( boolInp )
if boolInp,
    strOut = 'Yes';
else
    strOut = 'No';
end
end

%--------------------------------------------------------------------------
%
%--------------------------------------------------------------------------
function [stateSeq durationSeq] = shrinkSequence(stateSeqI, durationSeqI)

indBeforeChange = find(diff(stateSeqI));
stateSeq        = [stateSeqI(indBeforeChange) stateSeqI(end)];
durationSeq     = zeros(size(stateSeq));

durationSeq(1) = sum( durationSeqI( 1 : indBeforeChange(1) ) );
for i = 2:numel(indBeforeChange)
    durationSeq(i) = sum( durationSeqI( indBeforeChange(i-1)+1 : indBeforeChange(i) ) );
end
durationSeq(i+1) = sum( durationSeqI( indBeforeChange(i)+1 : end ) );


end

