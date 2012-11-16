function oddballExp

%%                        SCANNER PARAMETERS
%==========================================================================

subjectName                     = 'test';
saveData                        = true;
saveLog                         = true;
saveUnfoldedScenario            = true;
useLptPort                      = true;
showLog                         = true;

stimDurationInSec               = .2;
gapDurationInSec                = [.2 .4];
nRareStim                       = 100;
nFrequentStim                   = 5*nRareStim;
initialPauseinSec               = 2;

scenariosDir                    = 'scenarios/';
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
        eegDataDir  = 'd:/data/EEG-recordings/oddball/';
    case 'neu-wrk-0139',
        eegDataDir  = 'C:/home/adrien/KULeuven/PhD/EEG-recordings/oddball/';
    case 'neu-wrk-0161',
        eegDataDir  = 'C:/EEG-recordings/oddball/';
    case 'kuleuven-24b13c',
        eegDataDir  = 'd:/KULeuven/PhD/Work/EEG-Recording/oddball/';
    case 'neu-wrk-0158',
        eegDataDir  = 'd:/Adrien/Work/Hybrid-BCI/HybBciData/oddball/';
    otherwise,
        eegDataDir  = './EEG-recordings/';
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
st = sten();

scrPos      = get(0, 'ScreenSize');
scenario    = sprintf('oddballScenario@%dx%d.xml', scrPos(3), scrPos(4));
st.loadScenario( [scenariosDir scenario] );

%--------------------------------------------------------------------------
% generate state sequence and duration sequence

stimSeq = [ones(nRareStim, 1) ; 2*ones(nFrequentStim, 1)];
stimSeq = stimSeq( randperm( numel(stimSeq) ) );
stimSeq = [stimSeq , 3*ones(numel(stimSeq), 1)]';
stimSeq = stimSeq(:); % 1: rare stim, 2: frequent stim, 3: pause between stim
stimDur = zeros(size(stimSeq));
stimDur( stimSeq == 1 | stimSeq == 2 ) = min(stimDurationInSec) + ( max(stimDurationInSec) - min(stimDurationInSec) ) * rand(nRareStim+nFrequentStim, 1);
stimDur( stimSeq == 3 ) = min(gapDurationInSec) + ( max(gapDurationInSec) - min(gapDurationInSec) ) * rand(nRareStim+nFrequentStim, 1);

rareStateSeq = double( stimSeq == 1 );
rareStateSeq( rareStateSeq == 0 ) = 2*ones( sum(rareStateSeq==0), 1 ); 
freqStateSeq = double( stimSeq == 2 );
freqStateSeq( freqStateSeq == 0 ) = 2; 

[rareStateSeq rareDurationSeq] = shrinkSequence(rareStateSeq', stimDur');
[freqStateSeq freqDurationSeq] = shrinkSequence(freqStateSeq', stimDur');

if initialPauseinSec > 0
    rareStateSeq    = [2 rareStateSeq];
    rareDurationSeq = [initialPauseinSec rareDurationSeq];
    freqStateSeq    = [2 freqStateSeq];
    freqDurationSeq = [initialPauseinSec freqDurationSeq];
end

iFreqStimuli        = find( cellfun( @(x) strcmp(x, 'frequent stimulus'), {st.sc.stimuli(:).description} ) );
iRareStimuli        = find( cellfun( @(x) strcmp(x, 'rare stimulus'), {st.sc.stimuli(:).description} ) );


st.sc.stimuli(iFreqStimuli).stateSequence               = freqStateSeq;
st.sc.stimuli(iFreqStimuli).durationSequenceInSec       = freqDurationSeq;
st.sc.stimuli(iRareStimuli).stateSequence               = rareStateSeq;
st.sc.stimuli(iRareStimuli).durationSequenceInSec       = rareDurationSeq;

roundDurationInSec = sum(stimDur);
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

nMaxEvents  = round( 2 * ( 2 + numel(stimSeq) ) );
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
    frameRenderDurationLog = st.frameRenderDurationLog;
    listOfVariablesToSave = { ...
        'subjectName', ...
        'stimDurationInSec', ...
        'gapDurationInSec', ...
        'nRareStim', ...
        'nFrequentStim', ...
        'initialPauseinSec', ...
        'useBinaryIntensity', ...
        'correctStimulusAppearanceTime', ...
        'showProgressBar', ...
        'scenario', ...
        'stimSeq', ...
        'stimDur', ...
        'rareStateSeq', ...
        'rareDurationSeq', ...
        'freqStateSeq', ...
        'freqDurationSeq', ...
        'labelList', ...
        'screenInfo', ...
        'presentationStartTime', ...
        'presentationFinishTime', ...
        'flipTimeLog', ...
        'frameRenderDurationLog' ...
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
