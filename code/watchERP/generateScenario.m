function sc = generateScenario( desiredScreenID )

ssvepColor = [1 1 1]; % white
% ssvepColor = [1 1 O]; % yellow
% ssvepColor = [.5 .5 .5]; % grey
ssvepAlpha = .75; % 0: fully transparent, 1: fully opaque
dimmedColor = 'white'; % 'white' 'grey' 'yellow'
flashStyle = 'newColor'; % 'combine' 'newColor'
flashImage = 'red-disk-medium'; % 'black-pixel' 'red-disk-medium', for 'overlap' case
flashColor = 'yellow'; % 'white' 'grey' 'yellow' for 'newColor' case

alphaFactorDim = .5;
alphaFactorFlash = 1;
sizeFactorFlash = 1.2;

%% Init parameters
%==========================================================================
eltMatrix   = [3 2];
nItems      = prod(eltMatrix);
scrPos      = get(0, 'ScreenSize');
% scrPos      = [1 1 1920 1200];
% scrPos      = [1 1 1280 1024];
scrPos      = Screen('Rect', desiredScreenID);
eltSizeH    = 175; %150;%200;
eltSizeV    = 175; %150;%200;
eltGapH     = eltSizeH;
eltGapV     = eltSizeV;
SSVEPMarginH = 80;
SSVEPMarginV = 80;

eltSizeH_flash  = round( sizeFactorFlash * eltSizeH );
hPadd           = eltSizeH_flash - eltSizeH;
hPaddL          = round(hPadd/2);
hPaddR          = hPadd - hPaddL;
eltSizeV_flash  = round( sizeFactorFlash * eltSizeV );
vPadd           = eltSizeV_flash - eltSizeV;
vPaddT          = round(vPadd/2);
vPaddB          = vPadd - vPaddT;

if hPaddL > SSVEPMarginH || vPaddT > SSVEPMarginV
    error('generateScenario:outOfFlickerItem', 'flashed object will be out the flickering area. Increase SSVEP margin or decrease sizeFactorFlash');
end

SSVEPSizeH = 2*SSVEPMarginH + eltMatrix(2)*eltSizeH + (eltMatrix(2)-1)*eltGapH;
SSVEPSizeV = 2*SSVEPMarginV + eltMatrix(1)*eltSizeV + (eltMatrix(1)-1)*eltGapV;

%%
%==========================================================================

imageDir    = 'images\';
imageName{1} = fullfile(imageDir, 'apple');
imageName{2} = fullfile(imageDir, 'medicine');
imageName{3} = fullfile(imageDir, 'lightBulb');
imageName{4} = fullfile(imageDir, 'shirt');
imageName{5} = fullfile(imageDir, 'toilet');
imageName{6} = fullfile(imageDir, 'bathtub');

switch dimmedColor
    case 'white'
        dimmedImageName = cellfun( @(x) [x '.png'], imageName, 'UniformOutput', false );
    case 'grey'
        dimmedImageName = cellfun( @(x) [x '-grey.png'], imageName, 'UniformOutput', false );
    case 'yellow'
        dimmedImageName = cellfun( @(x) [x '-yellow.png'], imageName, 'UniformOutput', false );
end



texturesDir = 'textures\';
if ~exist(texturesDir, 'dir'), mkdir(texturesDir); end

%%
%==========================================================================
% eltMarginV  = round( ( scrPos(4) - (eltMatrix(1)-1)*eltGapV - eltMatrix(1)*eltSizeV ) / 2 );
% eltMarginH  = round( ( scrPos(3) - (eltMatrix(2)-1)*eltGapH - eltMatrix(2)*eltSizeH ) / 2 );
eltMarginV  = round( ( scrPos(4) - (eltMatrix(1)-1)*eltGapV - eltMatrix(1)*eltSizeV - vPaddT - vPaddB ) / 2 );
eltMarginH  = round( ( scrPos(3) - (eltMatrix(2)-1)*eltGapH - eltMatrix(2)*eltSizeH - hPaddL - hPaddR ) / 2 );
generateStimuli();
sc = generateScenarioAndStimuli();
sc.texturesDir = fullfile(cd, texturesDir);


    %==========================================================================
    %==========================================================================
    %
    %                       NESTED FUNCTIONS
    %
    %==========================================================================
    %==========================================================================

    %==========================================================================
    %==========================================================================
    function generateStimuli()

        %--------------------------------------------------------------------------
        % SSVEP pixel
        ssvepPixel = 255*uint8( reshape( ssvepColor, [1 1 3] ) );
        imwrite(ssvepPixel, [texturesDir 'ssvep-pixel.png'], 'Alpha', ssvepAlpha);
        
        
        %--------------------------------------------------------------------------
        % P3 stimuli
        hStart      = eltMarginH;
        vStart      = eltMarginV;
%         hEnd        = hStart + eltMatrix(2)*eltSizeH + (eltMatrix(2)-1)*eltGapH; % scrPos(3) - eltMarginH;
%         vEnd        = vStart + eltMatrix(1)*eltSizeV + (eltMatrix(1)-1)*eltGapV; % scrPos(4) - eltMarginV;
        hEnd        = hStart + eltMatrix(2)*eltSizeH + (eltMatrix(2)-1)*eltGapH + hPaddL + hPaddR;
        vEnd        = vStart + eltMatrix(1)*eltSizeV + (eltMatrix(1)-1)*eltGapV + vPaddT + vPaddB;
        
        hSize       = hEnd - hStart;
        vSize       = vEnd - vStart;
                
        % for each stimuli
        for iStim = 1:nItems
            
            stimImage = zeros(vSize, hSize, 3, 'uint8');
            stimAlpha = zeros(vSize, hSize, 'uint8');
            
            % draw all icons
            for iIcon = 1:nItems
                
                [vPosInMatrix hPosInMatrix] = ind2sub(eltMatrix, iIcon);
                
                distFromLeft    = (hPosInMatrix-1) * ( eltSizeH + eltGapH );
                distFromTop     = (vPosInMatrix-1) * ( eltSizeV + eltGapV );
                
                % if target icon
                if iIcon == iStim
                    
                    hRange          = distFromLeft + (1:eltSizeH_flash);
                    vRange          = distFromTop + (1:eltSizeV_flash);
                    switch flashStyle
                        case 'combine'
                            [A1, ~, alpha1]  = imread(dimmedImageName{iIcon});
                            A1               = imresize(A1, [eltSizeH_flash, eltSizeV_flash]);
                            alpha1           = imresize(alpha1, [eltSizeH_flash, eltSizeV_flash]);
                            
                            [A2, ~, alpha2]  = imread( fullfile(texturesDir, [flashImage '.png']) );
                            A2               = imresize(A2, [eltSizeH_flash, eltSizeV_flash]);
                            alpha2           = imresize(alpha2, [eltSizeH_flash, eltSizeV_flash]);

                            A = ( 1 - repmat(alpha2,[1 1 3]) / 255 ) .* A1 + ( repmat(alpha2,[1,1,3]) / 255 ) .* A2;
%                             alpha   = max(alpha1, alpha2);
                            
                            stimImage(vRange, hRange, :) = A;
                            stimAlpha(vRange, hRange)    = max(alphaFactorFlash*alpha1, alpha2);

                            
                        case 'newColor'
                            
                            switch flashColor
                                case 'white'
                                    flashImageName = [imageName{iIcon} '.png'];
                                case 'grey'
                                    flashImageName = [imageName{iIcon} '-grey.png'];
                                case 'yellow'
                                    flashImageName = [imageName{iIcon} '-yellow.png'];
                            end
                            
                            [A, ~, alpha]   = imread(flashImageName);
                            A               = imresize(A, [eltSizeH_flash, eltSizeV_flash]);
                            alpha           = imresize(alpha, [eltSizeH_flash, eltSizeV_flash]);
                            
                            stimImage( vRange, hRange, :) = A;
                            stimAlpha( vRange, hRange)    = alphaFactorFlash*alpha;
                            
                    end
                    
                % if non target icon
                else
                    hRange          = distFromLeft + hPaddL + (1:eltSizeH);
                    vRange          = distFromTop + vPaddT + (1:eltSizeV);
                    
                    [A, ~, alpha]   = imread(dimmedImageName{iIcon});
                    A               = imresize(A, [eltSizeH, eltSizeV]);
                    alpha           = imresize(alpha, [eltSizeH, eltSizeV]);

                    stimImage( vRange, hRange, :) = A;
                    stimAlpha( vRange, hRange)    = alphaFactorDim*alpha;

                end
                
                
            end
            
            % save the stimulus
            imwrite(stimImage, [texturesDir sprintf('stimulus-%.2d.png', iStim)], 'Alpha', stimAlpha);
        end
        
        % no flash stimulus
        stimImage = zeros(vSize, hSize, 3, 'uint8');
        stimAlpha = zeros(vSize, hSize, 'uint8');
        for iIcon = 1:nItems
            
            [vPosInMatrix hPosInMatrix] = ind2sub(eltMatrix, iIcon);
            
            distFromLeft    = (hPosInMatrix-1) * ( eltSizeH + eltGapH );
            distFromTop     = (vPosInMatrix-1) * ( eltSizeV + eltGapV );
            hRange          = distFromLeft + hPaddL + (1:eltSizeH);
            vRange          = distFromTop + vPaddT + (1:eltSizeV);
            
            [A, ~, alpha]   = imread(dimmedImageName{iIcon});
            A               = imresize(A, [eltSizeH, eltSizeV]);
            alpha           = imresize(alpha, [eltSizeH, eltSizeV]);
            
            stimImage( vRange, hRange, :) = A;
            stimAlpha( vRange, hRange)    = alpha/2;
            
        end
        imwrite(stimImage, [texturesDir sprintf('stimulus-%.2d.png', nItems+1)], 'Alpha', stimAlpha);
    
    end


    %==========================================================================
    %==========================================================================
    function sc = generateScenarioAndStimuli()
        
        %% Generate stimuli and calculate positions
        %==========================================================================
        
        %--------------------------------------------------------------------------
        % P300 and cue stimuli
        hStart      = eltMarginH;
        vStart      = eltMarginV;
%         hEnd        = hStart + eltMatrix(2)*eltSizeH + (eltMatrix(2)-1)*eltGapH; % scrPos(3) - eltMarginH;
%         vEnd        = vStart + eltMatrix(1)*eltSizeV + (eltMatrix(1)-1)*eltGapV; % scrPos(4) - eltMarginV;
        hEnd        = hStart + eltMatrix(2)*eltSizeH + (eltMatrix(2)-1)*eltGapH + hPaddL + hPaddR;
        vEnd        = vStart + eltMatrix(1)*eltSizeV + (eltMatrix(1)-1)*eltGapV + vPaddT + vPaddB;
        P300StimPos = [ hStart+1 vStart+1 hEnd vEnd ];
        
        CuePos      = zeros(nItems, 4); % for .xml scenario (and PTB)
        
        for iIcon = 1:nItems
            
            [vPosInMatrix hPosInMatrix] = ind2sub(eltMatrix, iIcon);
            
            distFromLeft    = (hPosInMatrix-1) * ( eltSizeH + eltGapH );
            distFromTop     = (vPosInMatrix-1) * ( eltSizeV + eltGapV ); 
            
            CuePos(iIcon, :) = ...
                [ eltMarginH + distFromLeft + hPaddL + 1, ...
                eltMarginV + distFromTop + vPaddT + 1, ...
                eltMarginH + distFromLeft + hPaddL + eltSizeH, ...
                eltMarginV + distFromTop + vPaddT + eltSizeV ];
            
        end
        
        %--------------------------------------------------------------------------
        % SSVEP stimuli
        hStart  = round( ( scrPos(3) - SSVEPSizeH ) / 2 );  % from left
        vStart  = round( ( scrPos(4) - SSVEPSizeV ) / 2 );  % from top
        hEnd    = hStart + SSVEPSizeH;
        vEnd    = vStart + SSVEPSizeV;
        SSVEPStimPos = [ hStart+1 vStart+1 hEnd vEnd ];
        
        
        %% Create scenario structure
        %==========================================================================
        sc = [];
        sc.description = 'Watch ERP with SSVEP flicker';
        sc.desired.scr.nCols = scrPos(3);
        sc.desired.scr.nRows = scrPos(4);
        
        %--------------------------------------------------------------------------
        % textures
        sc.textures(1).filename = 'ssvep-pixel.png';                       % SSVEP texture
        for iStim = 1:nItems+1
            sc.textures(iStim+1).filename = sprintf('stimulus-%.2d.png', iStim);    % P3 textures
        end
        sc.textures(nItems+3).filename = 'target-crosshair.png';                             % cue texture

        %--------------------------------------------------------------------------
        % Events
        sc.events(1).desc = 'start event';
        sc.events(1).id = 1;
        sc.events(2).desc = 'end event';
        sc.events(2).id = -1;
        
        sc.events(3).desc = 'Cue on';
        sc.events(3).id = 2;
        sc.events(4).desc = 'Cue off';
        sc.events(4).id = -2;
        
        sc.events(5).desc = 'SSVEP stim on';
        sc.events(5).id = 4;
        sc.events(6).desc = 'SSVEP stim off';
        sc.events(6).id = -4;
        
        sc.events(7).desc = 'P300 stim on';
        sc.events(7).id = 8;
        sc.events(8).desc = 'P300 stim off';
        sc.events(8).id = -8;

        %--------------------------------------------------------------------------
        % Additional info
        sc.iStartEvent                      = find( cellfun( @(x) strcmp(x, 'start event'), {sc.events(:).desc} ) );
        sc.iEndEvent                        = find( cellfun( @(x) strcmp(x, 'end event'), {sc.events(:).desc} ) );
        sc.frameBasedEventIdAdjust          = 0;
        sc.issueFrameBasedEvents            = 1;
        sc.issueTimeBasedEvents             = 0;
        sc.correctStimulusAppearanceTime    = 1;
        sc.useBinaryIntensity               = 0;
        
        %--------------------------------------------------------------------------
        % SSVEP stimuli
        sc.stimuli(1).description               = 'SSVEP stimulus';
        sc.stimuli(1).stateSequence             = 1;
        sc.stimuli(1).durationSequenceInSec     = Inf;
        sc.stimuli(1).desired.position          = SSVEPStimPos;
        sc.stimuli(1).states(1).frequency       = 15;
        sc.stimuli(1).states(1).initialPhase    = 0.00000000000000000000000000;
        sc.stimuli(1).states(1).views.iTexture  = 1;
        sc.stimuli(1).states(2).frequency       = 0;
        sc.stimuli(1).states(2).initialPhase    = 0.00000000000000000000000000;
        sc.stimuli(1).states(2).views.iTexture  = 0;
        sc.stimuli(1).eventMatrix               = [ 0  find( cellfun( @(x) strcmp(x, 'SSVEP stim off'), {sc.events(:).desc} ) ) ; ...
                                                    find( cellfun( @(x) strcmp(x, 'SSVEP stim on'), {sc.events(:).desc} ) ) 0  ];

        
        %--------------------------------------------------------------------------
        % P300 stimuli
        sc.stimuli(2).description               = 'P300 stimulus';
        sc.stimuli(2).stateSequence             = 1;
        sc.stimuli(2).durationSequenceInSec     = Inf;
        sc.stimuli(2).desired.position          = P300StimPos;
        iState = 1;
        sc.stimuli(2).eventMatrix = zeros(2*nItems+1);
        for iS = 1:nItems
            sc.stimuli(2).states(iState).views.iTexture  = iS+1;    % real
            sc.stimuli(2).states(iState+1).views.iTexture  = iS+1;  % fake
            
            sc.stimuli(2).eventMatrix(iState, 2:2:2*nItems) = find( cellfun( @(x) strcmp(x, 'P300 stim off'), {sc.events(:).desc} ) ); % from real to fake (reset binary marker)
            sc.stimuli(2).eventMatrix(iState+1, 2:2:2*nItems) = find( cellfun( @(x) strcmp(x, 'P300 stim on'), {sc.events(:).desc} ) ); % from fake to real (set binary marker)
            
            iState = iState+2;
        end
        
        sc.stimuli(2).states(iState).views.iTexture  = nItems+2;
        sc.stimuli(2).eventMatrix(2*nItems+1, 1:2:2*nItems-1) = ...
            find( cellfun( @(x) strcmp(x, 'P300 stim on'), {sc.events(:).desc} ) ); % from nothing to real (set binary marker)
        sc.stimuli(2).eventMatrix(1:2:2*nItems-1, 2*nItems+1) = ...
            find( cellfun( @(x) strcmp(x, 'P300 stim off'), {sc.events(:).desc} ) ); % from real to nothing (reset binary marker)

        
        
        %--------------------------------------------------------------------------
        % cue stimulus
        sc.stimuli(3).description               = 'Look here stimulus';
        sc.stimuli(3).stateSequence             = 1;
        sc.stimuli(3).durationSequenceInSec     = Inf;
        sc.stimuli(3).desired.position          = [0 0 0 0];
        for iEl = 1:nItems
            sc.stimuli(3).states(iEl).position = CuePos(iEl, :);
            sc.stimuli(3).states(iEl).views.iTexture = nItems+3;
        end
        sc.stimuli(3).states(nItems+1).position = [0 0 0 0];
        sc.stimuli(3).states(nItems+1).views.iTexture = 0;
        sc.stimuli(3).eventMatrix = zeros(nItems+1);
        sc.stimuli(3).eventMatrix(nItems+1, 1:nItems) = ...
            find( cellfun( @(x) strcmp(x, 'Cue on'), {sc.events(:).desc} ) );
        sc.stimuli(3).eventMatrix(1:nItems, nItems+1) = ...
            find( cellfun( @(x) strcmp(x, 'Cue off'), {sc.events(:).desc} ) );
        
        
    end


end







