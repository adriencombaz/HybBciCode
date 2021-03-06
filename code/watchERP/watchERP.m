function watchERP

addpath( fullfile(fileparts(fileparts(mfilename('fullpath'))), 'deps') );
addpath( fullfile(fileparts(fileparts(mfilename('fullpath'))), 'deps', 'lptIO') );

% desiredScreenID = 2;
% desiredScreenID = 1;
desiredScreenID = 0;


%%                        SCANNER PARAMETERS
%==========================================================================


%---------------------------------------------------------------------------------------
% default values
subjectName                     = 'test';
saveData                        = true;
saveLog                         = true;
saveUnfoldedScenario            = true;
useLptPort                      = true;
showLog                         = true;
showP3                          = true;
gapOrNoGapList                  = {'gap', 'noGap'};
gapOrNoGap                      = gapOrNoGapList{1};
nRepetitions                    = 10;
nCuesToShow                     = 12;
ssvepFreqList                   = {'60/4', '60/5', '60/6', '60/7', '60/8', '0'}; 
ssvepFreqStr                    = ssvepFreqList{1};

parameterList = {
    'Subject name',                             subjectName,                'subjectName'
    'gap or no gap',                            gapOrNoGapList,             'gapOrNoGap'
    'Number of cues',                           nCuesToShow,                'nCuesToShow'
    'Numner of repetitions',                    nRepetitions,               'nRepetitions'
    'SSVEP frequency',                          ssvepFreqList,              'ssvepFreqStr'
    'Show oddball stimulation',                 showP3,                     'showP3'
    'Use LPT Port',                             useLptPort,                 'useLptPort'
    'Save data',                                saveData,                   'saveData'
    'Save logs to text file',                   saveLog,                    'saveLog'
    'Save unfolded scenario',                   saveUnfoldedScenario,       'saveUnfoldedScenario'
    'Show logs in console output',              showLog,                    'showLog'
    };

prefGroupName = 'watchERP';

%---------------------------------------------------------------------------------------
% update parameters from GUI
pars = getItFromGUI( ...
    parameterList(:,1)', ...    list of parameter descriptions (cell array of strings)
    parameterList(:,2)', ...    list of default values for each parameter
    parameterList(:,3)', ...    list of variables to update
    prefGroupName, ...          name of preference group (to save parameter values for the next Round)
    sprintf( 'Input parameters of %s', prefGroupName ) ...
    );

if isempty( pars ),
    return
end

ssvepFreq = eval(ssvepFreqStr);

%---------------------------------------------------------------------------------------
%
% ISI = [.25 .35];
ISI = [.2 .3];
% ISI = [2 3];
% ISI = [.1 .2];
switch gapOrNoGap
    case 'gap'
        stimDurationInSec = [.2 .2];
        gapDurationInSec  = ISI - stimDurationInSec;
    case 'noGap'
        stimDurationInSec = ISI;
        gapDurationInSec  = 0;
end

fakeStimDurInSec                = 0.1;
% fakeStimDurInSec                = 0.05;
initialPauseinSec               = 2;
cueDurationInSec                = 2;
pauseAfterCueInSec              = 1;
pauseBetweenStagesInSec         = 1;
p300DelayInSec                  = 0.5;

% scenariosDir                    = 'scenarios/';
useBinaryIntensity              = true;
correctStimulusAppearanceTime   = true;
showProgressBar                 = true;


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
        eegDataDir  = 'd:/data/EEG-recordings/watchERP/';
    case 'neu-wrk-0139',
        eegDataDir  = 'C:/home/adrien/KULeuven/PhD/EEG-recordings/watchERP/';
    case 'neu-wrk-0161',
        eegDataDir  = 'C:/EEG-recordings/watchERP/';
    case 'kuleuven-24b13c',
        eegDataDir  = 'd:/KULeuven/PhD/Work/Hybrid-BCI/HybBciRecordedData/watchERP/';
    case 'neu-wrk-0158',
        eegDataDir  = 'd:/Adrien/Work/Hybrid-BCI/HybBciRecordedData/watchERP/';
    otherwise,
        eegDataDir  = './EEG-recordings/watchERP/';
end

% init data directory
%--------------------------------------------------------------------------
currentTimeString = datestr( now, 31 );
currentTimeString(11:3:end) = '-';
currentDataDir = [eegDataDir currentTimeString(1:10) '-' strrep( subjectName, ' ', '-' ) '/'];
if ~exist( currentDataDir, 'dir' ) && ( saveData || saveLog || saveUnfoldedScenario )
    mkdir( currentDataDir );
end
dataFilename = sprintf( '%s%s.mat', currentDataDir, currentTimeString );
unScFilename = [dataFilename(1:end-4) '-unfolded-scenario.xml'];



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

logThis( 'path to sten                          %s', which('sten') );
logThis( 'min stimulus duration [sec]           %g', min(stimDurationInSec) );
logThis( 'max stimulus duration [sec]           %g', max(stimDurationInSec) );
logThis( 'min gap duration [sec]                %g', min(gapDurationInSec) );
logThis( 'max gap duration [sec]                %g', max(gapDurationInSec) );
logThis( 'intial pause [sec]                    %g', initialPauseinSec );
logThis( 'Send markers through lpt port         %s', yesNo( useLptPort ) );
logThis( 'Show logs in console output           %s', yesNo( showLog ) );
logThis( 'Save logs to text file                %s', yesNo( saveLog ) );
logThis( 'Save data to mat file                 %s', yesNo( saveData ) );
logThis( 'Use binary (on/off) intensity profile %s', yesNo( useBinaryIntensity ) );
logThis( 'Save unfolded scenario                %s', yesNo( saveUnfoldedScenario ) );
logThis( 'Correct stimulus appearance time      %s', yesNo( correctStimulusAppearanceTime ) );
logThis( 'Show presentation progress bar        %s', yesNo( showProgressBar ) );

%%                  INIT THE STIMULATION ENGINE
%==========================================================================
pwd
st = sten( 'desiredScreenID' , desiredScreenID );
pwd
st.sc = generateScenario( desiredScreenID );
pwd

iP300Stimuli        = find( cellfun( @(x) strcmp(x, 'P300 stimulus'), {st.sc.stimuli(:).description} ) );
iLookHereStimulus   = find( cellfun( @(x) strcmp(x, 'Look here stimulus'), {st.sc.stimuli(:).description} ) );
iSSVEPStimuli       = find( cellfun( @(x) strcmp(x, 'SSVEP stimulus'), {st.sc.stimuli(:).description} ) );

iP3off  = numel( st.sc.stimuli(iP300Stimuli).states );
iCueOff = numel( st.sc.stimuli(iLookHereStimulus).states );
nItems  = iCueOff-1;

st.setFrequency( ssvepFreq, iSSVEPStimuli );

% st.sc.stimuli(iSSVEPStimuli).states(1).frequency = ssvepFreq;
% st.sc.stimuli(iSSVEPStimuli).states(2).frequency = 0;

%--------------------------------------------------------------------------
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
    p3StateSeq          = iP3off;
    p3DurationSeq       = initialPauseinSec;
    lookHereStateSeq    = iCueOff;
    lookHereDurationSeq = initialPauseinSec;
    SSVEPStateSeq       = 2;
    SSVEPDurationSeq    = initialPauseinSec;
end



cueList = repmat(1:nItems, 1, floor(nCuesToShow/nItems));
cueList = cueList(randperm(numel(cueList)));
if floor(nCuesToShow/nItems) ~= (nCuesToShow/nItems)
    logThis( 'nElts does not divide nSubroundsPerRound, as a consequence the cue list will be unbalanced' );
    padd = randperm(nItems);
    cueList( numel(cueList)+1 : nCuesToShow ) = padd( 1 : nCuesToShow-numel(cueList) );
end

for iSR = 1:nCuesToShow
    
    iItem = cueList( iSR );
    
    % ------------------- indication cue ------------------
    lookHereStateSeq    = [ lookHereStateSeq iItem ];
    lookHereDurationSeq = [ lookHereDurationSeq cueDurationInSec ];
    p3StateSeq          = [ p3StateSeq iP3off ];
    p3DurationSeq       = [ p3DurationSeq cueDurationInSec ];
    SSVEPStateSeq       = [ SSVEPStateSeq 2 ];
    SSVEPDurationSeq    = [ SSVEPDurationSeq cueDurationInSec ];
    
    % ------------------ pause after cue ------------------
    if pauseAfterCueInSec > 0
        p3StateSeq              = [ p3StateSeq iP3off ];
        p3DurationSeq           = [ p3DurationSeq pauseAfterCueInSec ];
        lookHereStateSeq        = [ lookHereStateSeq iCueOff ];
        lookHereDurationSeq     = [ lookHereDurationSeq pauseAfterCueInSec ];
        SSVEPStateSeq           = [ SSVEPStateSeq 2 ];
        SSVEPDurationSeq        = [ SSVEPDurationSeq pauseAfterCueInSec];
    end
    
    % -------------- start SSVEP before P300 --------------
    if p300DelayInSec > 0
        p3StateSeq              = [ p3StateSeq iP3off ];
        p3DurationSeq           = [ p3DurationSeq p300DelayInSec ];
        SSVEPStateSeq           = [ SSVEPStateSeq 1 ];
        SSVEPDurationSeq        = [ SSVEPDurationSeq p300DelayInSec];
        lookHereStateSeq        = [ lookHereStateSeq iCueOff ];
        lookHereDurationSeq     = [ lookHereDurationSeq p300DelayInSec ];
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
        stateSeq        = [stateSeq ; iP3off*ones(size(stateSeq))];
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
    lookHereStateSeq    = [ lookHereStateSeq iCueOff ];
    lookHereDurationSeq = [ lookHereDurationSeq sum(durationSeq(:)) ];
    SSVEPStateSeq       = [ SSVEPStateSeq 1 ];
    SSVEPDurationSeq    = [ SSVEPDurationSeq sum(durationSeq(:)) ];
    % ------------- Pause between stages ------------------
    if pauseBetweenStagesInSec > 0
        p3StateSeq                  = [ p3StateSeq iP3off ];
        p3DurationSeq               = [ p3DurationSeq pauseBetweenStagesInSec ];
        lookHereStateSeq            = [ lookHereStateSeq iCueOff ];
        lookHereDurationSeq         = [ lookHereDurationSeq pauseBetweenStagesInSec ];
        SSVEPStateSeq               = [ SSVEPStateSeq 2 ];
        SSVEPDurationSeq            = [ SSVEPDurationSeq pauseBetweenStagesInSec ];
    end
    
end

[lookHereStateSeq lookHereDurationSeq]  = shrinkSequence(lookHereStateSeq, lookHereDurationSeq);
[p3StateSeq p3DurationSeq]              = shrinkSequence(p3StateSeq, p3DurationSeq);

if ssvepFreq    % ssvep stimulation on (ssvep baseline, hybrid)
    [SSVEPStateSeq SSVEPDurationSeq] = shrinkSequence(SSVEPStateSeq, SSVEPDurationSeq);
else            % ssvep stimulation off (p300 baseline)
%     SSVEPStateSeq       = 1;
    SSVEPStateSeq       = 2;
    SSVEPDurationSeq    = sum(lookHereDurationSeq);
end

% if sum(lookHereDurationSeq) ~= sum(p3DurationSeq)
if sum(lookHereDurationSeq) - sum(p3DurationSeq) > 1e-10
    error('mistake in the sequence duration');
end

if ~showP3
    p3StateSeq      = iP3off;
    p3DurationSeq   = sum(lookHereDurationSeq);
end

roundDurationInSec = sum(lookHereDurationSeq);

st.sc.stimuli(iP300Stimuli).stateSequence               = p3StateSeq;
st.sc.stimuli(iP300Stimuli).durationSequenceInSec       = p3DurationSeq;
st.sc.stimuli(iLookHereStimulus).stateSequence          = lookHereStateSeq;
st.sc.stimuli(iLookHereStimulus).durationSequenceInSec  = lookHereDurationSeq;
st.sc.stimuli(iSSVEPStimuli).stateSequence              = SSVEPStateSeq;
st.sc.stimuli(iSSVEPStimuli).durationSequenceInSec      = SSVEPDurationSeq;


st.sc.desired.stimulationDuration = roundDurationInSec;


st.sc.useBinaryIntensity            = useBinaryIntensity;
st.sc.correctStimulusAppearanceTime = correctStimulusAppearanceTime;
st.sc.showProgressBar               = showProgressBar;
st.sc.issueFrameBasedEvents         = true;
st.sc.issueTimeBasedEvents          = false;
st.sc.frameBasedEventIdAdjust       = 0;
st.unfoldScenario();
if saveUnfoldedScenario,
    logThis( 'Saving unfolded scenario to file %s' , unScFilename );
    st.saveScenario( unScFilename );
end

st.loadTextures();

%% =====================================================================================
%                           INIT BIOSEMILABELCHANNEL object

nMaxEvents  = round( 2 * ( 2 + numel(p3StateSeq) + numel(lookHereStateSeq) + numel(SSVEPStateSeq) ) );
labChan     = biosemiLabelChannel( 'sizeListLabels', nMaxEvents , 'useTriggerCable', useLptPort);



%% =====================================================================================
%                                   INIT GRAPHICS
try
    st.initGraph();
catch%#ok<*CTCH>
    Screen( 'CloseAll' );
    logThis( 'Failed to initialize PTB graphics. Exiting' )
    psychrethrow( psychlasterror );
    return
end
HideCursor();

st.updateScenario();
st.loadTexturesToPTB();

st.setEventDispatcher( @labChan.markEvent );

logThis( 'Screen flip-interval:             %8.6f ms', st.scr.flipInterval );
logThis( 'Screen frame-rate:                %8.5f Hz', st.scr.FPS );
logThis( 'Screen size:                      %g x %g px', st.scr.nCols, st.scr.nRows );

st.preparePresentationOptimized();


%% ================================================================
%                         EXPERIMENT
logThis( 'Presenting stimuli (experiment in progress)' );

presentationStartTime = st.presentationStartTime;
st.presentScenarioRightNow();
presentationFinishTime = st.presentationStopTime;
st.finishPresentation();

logThis( 'Presentation duration:         %8.3f seconds', presentationFinishTime-presentationStartTime );

%% ================================================================
%                          FINISHING
% Done. Close Screen, release all resources:
logThis( 'Finishing and cleaning up' );
st.closeGraph();
ShowCursor();

if saveData
    logThis( 'Saving data into mat file: %s', dataFilename );
    labelList   = labChan.getListLabels();
    screenInfo  = st.scr;
    flipTimeLog = st.flipTimeLog;
    scenario    = st.sc;
    frameRenderDurationLog = st.frameRenderDurationLog;
    listOfVariablesToSave = { ...
        'subjectName', ...
        'stimDurationInSec', ...
        'gapDurationInSec', ...
        'fakeStimDurInSec', ...
        'nRepetitions', ...
        'initialPauseinSec', ...
        'cueDurationInSec', ...
        'pauseAfterCueInSec', ...
        'pauseBetweenStagesInSec', ...
        'nCuesToShow', ...
        'useBinaryIntensity', ...
        'correctStimulusAppearanceTime', ...
        'showProgressBar', ...
        'scenario', ...
        'realP3StateSeqOnsets', ...
        'p3StateSeq', ...
        'p3DurationSeq', ...
        'lookHereStateSeq', ...
        'lookHereDurationSeq', ...
        'SSVEPStateSeq', ...
        'SSVEPDurationSeq', ...
        'labelList', ...
        'screenInfo', ...
        'presentationStartTime', ...
        'presentationFinishTime', ...
        'flipTimeLog', ...
        'frameRenderDurationLog' ...
        'gapOrNoGap', ...
        'ssvepFreq', ...
       };
   save( dataFilename, listOfVariablesToSave{:} );
end


end



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



function strOut = yesNo( boolInp )
if boolInp,
    strOut = 'Yes';
else
    strOut = 'No';
end
end
