function watchERP_2stim_genereateMovie

addpath( '../deps' );
addpath( '../deps/lptIO' );

desiredScreenID = 2;
% desiredScreenID = 0;

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
ssvepFreqList                   = {'60/4', '60/5', '60/6', '60/7', '60/8'}; 
ssvepFreq1Str                   = ssvepFreqList{1};
ssvepFreq2Str                   = ssvepFreqList{1};

parameterList = {
    'Subject name',                             subjectName,                'subjectName'
    'gap or no gap',                            gapOrNoGapList,             'gapOrNoGap'
    'Number of cues',                           nCuesToShow,                'nCuesToShow'
    'Numner of repetitions',                    nRepetitions,               'nRepetitions'
    'SSVEP frequency 1',                        ssvepFreqList,              'ssvepFreq1Str'
    'SSVEP frequency 2',                        ssvepFreqList,              'ssvepFreq2Str'
    'Show oddball stimulation',                 showP3,                     'showP3'
    'Use LPT Port',                             useLptPort,                 'useLptPort'
    'Save data',                                saveData,                   'saveData'
    'Save logs to text file',                   saveLog,                    'saveLog'
    'Save unfolded scenario',                   saveUnfoldedScenario,       'saveUnfoldedScenario'
    'Show logs in console output',              showLog,                    'showLog'
    };

prefGroupName = 'watchERP_2stim';

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

ssvepFreq = [eval(ssvepFreq1Str) eval(ssvepFreq2Str)];

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
        eegDataDir  = 'd:/KULeuven/PhD/Work/Hybrid-BCI/HybBciRecordedData/watchERP_2stim/';
    case 'neu-wrk-0158',
        eegDataDir  = 'd:/Adrien/Work/Hybrid-BCI/HybBciRecordedData/watchERP_2stim/';
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
st = sten( 'desiredScreenID' , desiredScreenID );
st.sc = generateScenario_2stim( desiredScreenID );


iP300Stimuli        = find( cellfun( @(x) strcmp(x, 'P300 stimulus'), {st.sc.stimuli(:).description} ) );
iLookHereStimulus   = find( cellfun( @(x) strcmp(x, 'Look here stimulus'), {st.sc.stimuli(:).description} ) );
iSSVEPStimuli       = find( cellfun( @(x) strcmp(x, 'SSVEP stimulus'), {st.sc.stimuli(:).description} ) );

if numel(iP300Stimuli) ~= numel(iSSVEPStimuli)
    error('not the same number of p3 and SSVEP stimuli');
end

iP3off  = unique( cellfun(@numel, {st.sc.stimuli(iP300Stimuli).states}) );
if numel(iP3off) ~= 1
    error('the P3 stimuli do not have the same number of states');
end

iCueOff = numel( st.sc.stimuli(iLookHereStimulus).states );
nP3item = (iP3off-1)/numel(iSSVEPStimuli);
if round(nP3item)~=nP3item, error('something wrong here'); end
nItems  = iCueOff-1;

if numel(ssvepFreq) ~= numel(iSSVEPStimuli)
    error('number of ssvep squares do not match the number of frequencies');
end
nSsvep = numel(iSSVEPStimuli);
for iSsvep = 1:nSsvep
    st.setFrequency( ssvepFreq(iSsvep), iSSVEPStimuli(iSsvep) );
end

% st.sc.stimuli(iSSVEPStimuli).states(1).frequency = ssvepFreq;
% st.sc.stimuli(iSSVEPStimuli).states(2).frequency = 0;

%--------------------------------------------------------------------------
% generate state sequence and duration sequence
p3StateSeq              = cell(1, nSsvep);
realP3StateSeqOnsets    = cell(1, nSsvep);
for iSsvep = 1:nSsvep
    p3StateSeq{iSsvep}          = [];
    realP3StateSeqOnsets{iSsvep}= [];
end
p3DurationSeq       = [];
lookHereStateSeq    = [];
lookHereDurationSeq = [];
SSVEPStateSeq       = [];
SSVEPDurationSeq    = 0;


% initial pause
if initialPauseinSec > 0
    p3StateSeq          = cellfun(@(x) {iP3off}, p3StateSeq);
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
%     p3StateSeq          = [ p3StateSeq iP3off ];
    p3StateSeq          = cellfun(@(x) [x iP3off], p3StateSeq, 'UniformOutput', false);
    p3DurationSeq       = [ p3DurationSeq cueDurationInSec ];
    SSVEPStateSeq       = [ SSVEPStateSeq 2 ];
    SSVEPDurationSeq    = [ SSVEPDurationSeq cueDurationInSec ];
    
    % ------------------ pause after cue ------------------
    if pauseAfterCueInSec > 0
%         p3StateSeq              = [ p3StateSeq iP3off ];
        p3StateSeq              = cellfun(@(x) [x iP3off], p3StateSeq, 'UniformOutput', false);
        p3DurationSeq           = [ p3DurationSeq pauseAfterCueInSec ];
        lookHereStateSeq        = [ lookHereStateSeq iCueOff ];
        lookHereDurationSeq     = [ lookHereDurationSeq pauseAfterCueInSec ];
        SSVEPStateSeq           = [ SSVEPStateSeq 2 ];
        SSVEPDurationSeq        = [ SSVEPDurationSeq pauseAfterCueInSec];
    end
    
    % -------------- start SSVEP before P300 --------------
    if p300DelayInSec > 0
%         p3StateSeq              = [ p3StateSeq iP3off ];
        p3StateSeq              = cellfun(@(x) [x iP3off], p3StateSeq, 'UniformOutput', false);
        p3DurationSeq           = [ p3DurationSeq p300DelayInSec ];
        SSVEPStateSeq           = [ SSVEPStateSeq 1 ];
        SSVEPDurationSeq        = [ SSVEPDurationSeq p300DelayInSec];
        lookHereStateSeq        = [ lookHereStateSeq iCueOff ];
        lookHereDurationSeq     = [ lookHereDurationSeq p300DelayInSec ];
    end
    
    
    % --- P300 stimulation state and duration sequence ----
    stateSeq = cell(1, nSsvep);
    for iSsvep = 1:nSsvep
        stateSeq{iSsvep} = randperm(nP3item);
        for iRep = 2:nRepetitions
            newSeq = randperm(nP3item);
            while stateSeq{iSsvep}(end) == newSeq(1)
                newSeq = randperm(nP3item);
            end
            stateSeq{iSsvep} = [ stateSeq{iSsvep} newSeq ];
        end
    end
%     realP3StateSeqOnsets = [realP3StateSeqOnsets stateSeq];
    realP3StateSeqOnsets = cellfun(@(x, y) [x y], realP3StateSeqOnsets, stateSeq, 'UniformOutput', false);

%     stateSeq = 2*stateSeq-1;
    stateSeq = cellfun(@(x) 2*x-1, stateSeq, 'UniformOutput', false);
    stateSeqLength = nP3item*nRepetitions; % check that == size(stateSeq{i}, 2)
    
    if sum(gapDurationInSec) > 0
%         stateSeq        = [stateSeq ; iP3off*ones(size(stateSeq))];
        stateSeq        = cellfun(@(x) [x ; iP3off*ones(size(x))], stateSeq, 'UniformOutput', false);
        stimDurationSeq = stimDurationInSec(1) + ( stimDurationInSec(2) - stimDurationInSec(1) ) .* rand( 1, stateSeqLength );
        gapDurationSeq  = gapDurationInSec(1)  + ( gapDurationInSec(2)  - gapDurationInSec(1)  ) .* rand( 1, stateSeqLength );
        durationSeq     = [stimDurationSeq ; gapDurationSeq];
    else
%         stateSeq        = [stateSeq ; stateSeq+1];
        stateSeq        = cellfun(@(x) [x ; x+1], stateSeq, 'UniformOutput', false);
        realStimDur     = stimDurationInSec(1) + (stimDurationInSec(2)-stimDurationInSec(1)) .* rand( 1, stateSeqLength );
        fakeOnDurSeq    = fakeStimDurInSec .* ones(1, stateSeqLength);
        fakeOffDurSeq   = realStimDur - fakeOnDurSeq;
        durationSeq     = [fakeOnDurSeq ; fakeOffDurSeq];
    end
%     p3StateSeq          = [ p3StateSeq stateSeq(:)' ];
    p3StateSeq          = cellfun(@(x,y) [x y(:)'], p3StateSeq, stateSeq, 'UniformOutput', false);
    p3DurationSeq       = [ p3DurationSeq durationSeq(:)' ];
    lookHereStateSeq    = [ lookHereStateSeq iCueOff ];
    lookHereDurationSeq = [ lookHereDurationSeq sum(durationSeq(:)) ];
    SSVEPStateSeq       = [ SSVEPStateSeq 1 ];
    SSVEPDurationSeq    = [ SSVEPDurationSeq sum(durationSeq(:)) ];
    % ------------- Pause between stages ------------------
    if pauseBetweenStagesInSec > 0
%         p3StateSeq                  = [ p3StateSeq iP3off ];
        p3StateSeq                  = cellfun(@(x) [x iP3off], p3StateSeq, 'UniformOutput', false);
        p3DurationSeq               = [ p3DurationSeq pauseBetweenStagesInSec ];
        lookHereStateSeq            = [ lookHereStateSeq iCueOff ];
        lookHereDurationSeq         = [ lookHereDurationSeq pauseBetweenStagesInSec ];
        SSVEPStateSeq               = [ SSVEPStateSeq 2 ];
        SSVEPDurationSeq            = [ SSVEPDurationSeq pauseBetweenStagesInSec ];
    end
    
end

[lookHereStateSeq lookHereDurationSeq]  = shrinkSequence(lookHereStateSeq, lookHereDurationSeq);
dum = p3DurationSeq;
[p3StateSeq{1} p3DurationSeq] = shrinkSequence(p3StateSeq{1}, p3DurationSeq);
for iSsvep = 2:nSsvep
    [p3StateSeq{iSsvep} dum] = shrinkSequence(p3StateSeq{iSsvep}, dum);
end
if dum ~= p3DurationSeq, error('something wrong here!!'); end

    [SSVEPStateSeq SSVEPDurationSeq] = shrinkSequence(SSVEPStateSeq, SSVEPDurationSeq);

if sum(lookHereDurationSeq) - sum(p3DurationSeq) > 1e-10
    error('mistake in the sequence duration');
end

if ~showP3
    p3StateSeq      = cellfun(@(x) {iP3off}, p3StateSeq);
    p3DurationSeq   = sum(lookHereDurationSeq);
end

roundDurationInSec = sum(lookHereDurationSeq);

st.sc.stimuli(iLookHereStimulus).stateSequence          = lookHereStateSeq;
st.sc.stimuli(iLookHereStimulus).durationSequenceInSec  = lookHereDurationSeq;
for iSsvep = 1:nSsvep
    st.sc.stimuli(iSSVEPStimuli(iSsvep)).stateSequence              = SSVEPStateSeq;
    st.sc.stimuli(iSSVEPStimuli(iSsvep)).durationSequenceInSec      = SSVEPDurationSeq;
    st.sc.stimuli(iP300Stimuli(iSsvep)).stateSequence               = p3StateSeq{iSsvep};
    st.sc.stimuli(iP300Stimuli(iSsvep)).durationSequenceInSec       = p3DurationSeq;
end

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
%

%--------------------------------------------------------------------------
FPS = 60;
roundDurationInFrames       = round(roundDurationInSec*FPS);
p300stimulusStatePerFrame   = cell(nSsvep, 1);
ssvepStimulusStatePerFrame  = cell(nSsvep, 1);
for iSsvep = 1:nSsvep
    p300stimulusStatePerFrame{iSsvep}   = zeros(1, roundDurationInFrames);
    ssvepStimulusStatePerFrame{iSsvep}  = zeros(1, roundDurationInFrames);
end
cueStimulusStatePerFrame    = zeros(1, roundDurationInFrames);

%--------------------------------------------------------------------------
for iSsvep = 1:nSsvep
    durationSeqInFrames = round( st.sc.stimuli(iP300Stimuli(iSsvep)).durationSequenceInSec * FPS );
    if sum( durationSeqInFrames ) < roundDurationInFrames
        durationSeqInFrames(end) = durationSeqInFrames(end) + roundDurationInFrames -  sum( durationSeqInFrames );
    end
    stateSequence       = st.sc.stimuli(iP300Stimuli(iSsvep)).stateSequence;
    ind = 0;
    for iS = 1:numel(stateSequence)
        p300stimulusStatePerFrame{iSsvep}( ind+1:ind+durationSeqInFrames(iS) ) = stateSequence(iS);
        ind = ind+durationSeqInFrames(iS);
    end
end

%--------------------------------------------------------------------------
for iSsvep = 1:nSsvep
    durationSeqInFrames = round( st.sc.stimuli(iSSVEPStimuli(iSsvep)).durationSequenceInSec * FPS );
    if sum( durationSeqInFrames ) < roundDurationInFrames
        durationSeqInFrames(end) = durationSeqInFrames(end) + roundDurationInFrames -  sum( durationSeqInFrames );
    end
    stateSequence       = st.sc.stimuli(iSSVEPStimuli(iSsvep)).stateSequence;
    ind = 0;
    for iS = 1:numel(stateSequence)
        ssvepStimulusStatePerFrame{iSsvep}( ind+1:ind+durationSeqInFrames(iS) ) = stateSequence(iS);
        ind = ind+durationSeqInFrames(iS);
    end
end

%--------------------------------------------------------------------------
durationSeqInFrames = round( st.sc.stimuli(iLookHereStimulus).durationSequenceInSec * FPS );
if sum( durationSeqInFrames ) < roundDurationInFrames
    durationSeqInFrames(end) = durationSeqInFrames(end) + roundDurationInFrames -  sum( durationSeqInFrames );
end
stateSequence       = st.sc.stimuli(iLookHereStimulus).stateSequence;
ind = 0;
for iS = 1:numel(stateSequence)
    cueStimulusStatePerFrame( ind+1:ind+durationSeqInFrames(iS) ) = stateSequence(iS);
    ind = ind+durationSeqInFrames(iS);
end


%% =====================================================================================
%
scrPos  = Screen('Rect', desiredScreenID);

pixPath = fullfile(cd, 'textures');
outPath = fullfile(cd, 'movieFrames');
if ~exist( outPath, 'dir' ), mkdir( outPath ); end

frameStart = 1;

for iFr = 1:roundDurationInFrames

    for iPc = 10:10:100
        if iFr-1 < iPc*roundDurationInFrames/100 && iFr >= iPc*roundDurationInFrames/100
            fprintf('...%d%%', iPc);
            break
        end
    end
    
    frameImg = zeros(scrPos(4), scrPos(3), 3);
    
    % SSVEP Square
    for iSsvep = 1:nSsvep
        iState  = ssvepStimulusStatePerFrame{iSsvep}(iFr);
        iTex    = st.sc.stimuli(iSSVEPStimuli(iSsvep)).states(iState).views.iTexture;
        if iTex
            figName = fullfile(pixPath, st.sc.textures(iTex).filename);
            [img , ~, ~] = imread( figName );
            img = double(img)/255;
            pos = st.sc.stimuli(iSSVEPStimuli(iSsvep)).states(iState).position;
            phase = 2 * pi * st.sc.stimuli(iSSVEPStimuli(iSsvep)).states(iState).frequency * (iFr - frameStart - 1)/FPS;
            alpha = ( 1 + cos( phase ) ) / 2;
            frameImg( pos(2):pos(4), pos(1):pos(3), : ) = alpha * repmat(img, pos(4)-pos(2)+1, pos(3)-pos(1)+1) ...
                + (1-alpha) * frameImg( pos(2):pos(4), pos(1):pos(3), : );
        else
            frameStart = iFr;
        end
    end
    
    % P3 stim
    for iSsvep = 1:nSsvep
        iState  = p300stimulusStatePerFrame{iSsvep}(iFr);
        iTex    = st.sc.stimuli(iP300Stimuli(iSsvep)).states(iState).views.iTexture;
        figName = fullfile(pixPath, st.sc.textures(iTex).filename);
        [img , ~, alpha] = imread( figName );
        img = double(img);
        alpha = double(alpha);
        pos = st.sc.stimuli(iP300Stimuli(iSsvep)).states(iState).position;
        frameImg( pos(2):pos(4), pos(1):pos(3), : ) = repmat((alpha/255), [1 1 3]).*(img/255) + repmat((1-alpha/255), [1 1 3]).*frameImg( pos(2):pos(4), pos(1):pos(3), : );
    end
    
    % Cue
    iState  = cueStimulusStatePerFrame(iFr);
    iTex    = st.sc.stimuli(iLookHereStimulus).states(iState).views.iTexture;
    if iTex
        figName = fullfile(pixPath, st.sc.textures(iTex).filename);
        [img , ~, alpha] = imread( figName );
        img = double(img);
        alpha = double(alpha);
        pos = st.sc.stimuli(iLookHereStimulus).states(iState).position;
        img = imresize(img, [pos(4)-pos(2)+1, pos(3)-pos(1)+1]);
        alpha = imresize(alpha, [pos(4)-pos(2)+1, pos(3)-pos(1)+1]);
        frameImg( pos(2):pos(4), pos(1):pos(3), : ) = repmat((alpha/255), [1 1 3]).*(img/255) + repmat((1-alpha/255), [1 1 3]).*frameImg( pos(2):pos(4), pos(1):pos(3), : );
    end
    
    imName = sprintf('img%07d.png', iFr);
    imwrite( frameImg, fullfile(outPath, imName) );
%     imwrite( frameImg, fullfile(outPath, imName), 'alpha', alphaCh );
    
end



%% ================================================================
%                          FINISHING
% Done. Close Screen, release all resources:
logThis( 'Finishing and cleaning up' );
st.closeGraph();
ShowCursor();


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
