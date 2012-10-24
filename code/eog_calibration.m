% eog_calibration(num_trials, lpt_port, screenId, lang)
%
% Present EOG calibration trials to a subject. Each trial consists of a
% saccade in each direction and an eye blink.
%
% The following trigger style marker codes are send through the parallel
% port:
%     110 - Saccade to the left
%     111 - Saccade to the right
%     112 - Saccade upwards
%     113 - Saccade downwards
%     114 - Eye blink
%
% num_trials - number of trials to show.
% lpt_port   - name ('LPT1', 'LPT2', ...) of the LPT port to send markers
%              through. Defaults to 'LPT1'.
% screenId   - the Psychtoolbox screen id to present the stimuli on.
%              Defaults to 0.
% lang       - the language in which to display the instructions to the
%              subject. Defaults to 'nl' for Dutch. Any other value will
%              switch to English (recommend using 'en' for clarity).
function eog_calibration(num_trials, lpt_port, screenId, lang)

% Configuration parameters
crossSize = 100;

eogLeftCode = 110;
eogRightCode = 111;
eogUpCode = 112;
eogDownCode = 113;
blinkCode = 114;

if nargin < 4
    lang = 'nl';
end
if nargin < 3
    screenId = 0;
end
if nargin < 2
    lpt_port = 'LPT1';
end

PARALLEL_PORT = getLPTportIOAddress(lpt_port);

%% Open Window, configure Psychtoolbox

window = Screen('OpenWindow', screenId);
HideCursor;
    
[screenWidth, screenHeight] = Screen('WindowSize', window);
black = BlackIndex(window);
white = WhiteIndex(window);

Screen('TextFont', window, 'Cambria');
Screen('TextSize', window, 50);

crossImage = imread('cross.png');
crossImageHeight = size(crossImage,1);
crossImageWidth = size(crossImage,2);
crossTexture = Screen('MakeTexture', window, crossImage);

lptwrite(PARALLEL_PORT, 0);

screenCenter = [screenWidth, screenHeight] / 2;
crossPos = [crossImageWidth/2, screenHeight/2, eogLeftCode; ...
            screenWidth - crossImageWidth/2, screenHeight/2, eogRightCode; ...
            screenWidth/2, crossImageHeight/2, eogDownCode; ...
            screenWidth/2, screenHeight - crossImageHeight/2, eogUpCode];

crossPos = repmat(crossPos, num_trials, 1);

%% Present saccade trials

Screen('FillRect', window, black);
if strcmp(lang, 'nl')
    DrawFormattedText(window, 'Volg het witte kruis met uw ogen.', 'center', screenHeight/4, white);
else
    DrawFormattedText(window, 'Follow the white cross with your eyes.', 'center', screenHeight/4, white);
end
Screen('DrawTexture', window, crossTexture, [], [screenCenter - crossSize/2, screenCenter + crossSize/2]);
Screen('Flip', window);
WaitSecs(5.0);

Screen('FillRect', window, black);
Screen('DrawTexture', window, crossTexture, [], [screenCenter - crossSize/2, screenCenter + crossSize/2]);
Screen('Flip', window);
WaitSecs(1.0);

for i = randperm(num_trials*4)
    lptwrite(PARALLEL_PORT, crossPos(i,3));
    WaitSecs(0.01);
    lptwrite(PARALLEL_PORT, 0);
    move_texture(window, crossTexture, crossSize, screenCenter - crossSize/2, crossPos(i,1:2) - crossSize/2, 0.25, 'sine');
    move_texture(window, crossTexture, crossSize, crossPos(i,1:2) - crossSize/2, screenCenter - crossSize/2, 1, 'sine'); 
end

Screen('FillRect', window, black);
Screen('DrawTexture', window, crossTexture, [], [screenCenter - crossSize/2, screenCenter + crossSize/2]);
Screen('Flip', window);
WaitSecs(1.0);

%% Present blink trials

Screen('FillRect', window, black);
if strcmp(lang, 'nl')
    DrawFormattedText(window, 'Knipper met uw ogen\n\nwanneer het kruis de grond raakt.', 'center', screenHeight/4 + crossSize/2 + 20, white);
else
    DrawFormattedText(window, 'Blink your eyes\n\nwhen the cross bounces on the ground.', 'center', screenHeight/4 + crossSize/2 + 20, white);
end
Screen('TextSize', window, 30);
if strcmp(lang, 'nl')
    DrawFormattedText(window, 'Volg het kruis NIET met uw ogen.\n\nBlijf kijken naar het midden\n\nvan het scherm.', 'center', screenHeight/2 + crossSize/2 + 20, white);
else
    DrawFormattedText(window, 'Do NOT follow the cross with your eyes.\n\nKeep them fixed at the center\n\nof the screen.', 'center', screenHeight/2 + crossSize/2 + 20, white);
end
Screen('TextSize', window, 50);
Screen('DrawTexture', window, crossTexture, [], [(screenWidth - crossSize)/2, screenHeight/4 - crossSize/2, (screenWidth + crossSize)/2, screenHeight/4 + crossSize/2]);
drawGround();
Screen('Flip', window);
WaitSecs(10);

Screen('FillRect', window, black);
Screen('DrawTexture', window, crossTexture, [], [(screenWidth - crossSize)/2, screenHeight/4 - crossSize/2, (screenWidth + crossSize)/2, screenHeight/4 + crossSize/2]);
drawGround();
Screen('Flip', window);
WaitSecs(1.0);

function drawGround()
%     Screen('DrawLine', window, white, 0, screenHeight/2 + crossSize/2, screenWidth, screenHeight/2 + crossSize/2, 20);
    Screen('DrawLine', window, white, 0, screenHeight/2 + crossSize/2, screenWidth, screenHeight/2 + crossSize/2, 10);
    Screen('DrawLine', window, white, screenWidth/2, screenHeight/2 + crossSize/2 - 10, screenWidth/2, screenHeight/2 + crossSize/2 + 10, 5);
end

for i = 1:num_trials
    move_texture(window, crossTexture, crossSize, [(screenWidth - crossSize)/2, screenHeight/4 - crossSize/2], screenCenter - crossSize/2, 0.75, 'inv-sine', @drawGround);
    lptwrite(PARALLEL_PORT, blinkCode);
    WaitSecs(0.01);
    lptwrite(PARALLEL_PORT, 0);
    move_texture(window, crossTexture, crossSize, screenCenter - crossSize/2, [(screenWidth - crossSize)/2, screenHeight/4 - crossSize/2], 0.75, 'sine', @drawGround);
end

%% End of experiment
WaitSecs(2);
Screen('FillRect', window, black);
if strcmp(lang, 'nl')
    DrawFormattedText(window, 'Dank u wel.', 'center', 'center', white);
else
    DrawFormattedText(window, 'Thank you.', 'center', 'center', white);
end
Screen('Flip', window);
WaitSecs(5.0);

%% Cleanup
Screen('CloseAll');
end