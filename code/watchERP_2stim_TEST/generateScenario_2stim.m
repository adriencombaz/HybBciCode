function sc = generateScenario_2stim( desiredScreenID )

ssvepColor = [1 1 1]; % white
% ssvepColor = [1 1 O]; % yellow
% ssvepColor = [.5 .5 .5]; % grey
% ssvepAlpha = .75; % 0: fully transparent, 1: fully opaque
ssvepAlpha = .4; % 0: fully transparent, 1: fully opaque
dimmedColor = 'white'; % 'white' 'grey' 'yellow'
% flashStyle = 'newColor'; % 'combine' 'newColor'
% flashImage = 'red-disk-medium'; % 'black-pixel' 'red-disk-medium', for 'overlap' case
% flashColor = 'yellow'; % 'white' 'grey' 'yellow' for 'newColor' case

alphaFactorDim = .5;
alphaFactorFlash = 1;
sizeFactorFlash = 1.2;

%% Init parameters
%==========================================================================
ssvepMatrix     = [1 2];
nSsvep          = prod( ssvepMatrix );
eltMatrix       = [3 2];
nItems          = prod(eltMatrix);
scrPos          = Screen('Rect', desiredScreenID);
% eltSizeH        = 175; % for 1920x1200
% eltSizeV        = 175; % for 1920x1200
% SSVEPMarginH    = 80; % for 1920x1200
% SSVEPMarginV    = 80; % for 1920x1200
eltSizeH        = 150; % for 1920x1200
eltSizeV        = 150; % for 1920x1200
SSVEPMarginH    = 70; % for 1920x1200
SSVEPMarginV    = 70; % for 1920x1200
eltGapH         = eltSizeH;
eltGapV         = eltSizeV;
SSVEPGapH       = 600;
SSVEPGapV       = 100; % not useful here as ssvepMatrix(1) = 1, but well, for later will be nice


eltSizeH_flash  = round( sizeFactorFlash * eltSizeH );
hPadd           = eltSizeH_flash - eltSizeH;
hPaddL          = round(hPadd/2);
% hPaddR          = hPadd - hPaddL;
eltSizeV_flash  = round( sizeFactorFlash * eltSizeV );
vPadd           = eltSizeV_flash - eltSizeV;
vPaddT          = round(vPadd/2);
% vPaddB          = vPadd - vPaddT;

if hPaddL > SSVEPMarginH || vPaddT > SSVEPMarginV
    error('generateScenario_2stim:outOfFlickerArea', 'flashed object will be out the flickering area. Increase SSVEP margin or decrease sizeFactorFlash');
end

SSVEPSizeH = 2*SSVEPMarginH + eltMatrix(2)*eltSizeH + (eltMatrix(2)-1)*eltGapH;
SSVEPSizeV = 2*SSVEPMarginV + eltMatrix(1)*eltSizeV + (eltMatrix(1)-1)*eltGapV;

ssvepStartV = round( scrPos(4) - ( ssvepMatrix(1)*(SSVEPSizeV+SSVEPGapV) - SSVEPGapV ) )/2;
if ssvepStartV <= 0
    error('generateScenario_2stim:OutScreen', 'ssvep stimuli is vertically out of the screen');
end
ssvepStartH = round( scrPos(3) - ( ssvepMatrix(2)*(SSVEPSizeH+SSVEPGapH) - SSVEPGapH ) )/2;
if ssvepStartH <= 0
    error('generateScenario_2stim:OutScreen', 'ssvep stimuli is horizontally out of the screen');
end
%%
%==========================================================================

imageDir    = 'images\';
imageName{1} = fullfile(imageDir, 'apple');
imageName{2} = fullfile(imageDir, 'medicine');
imageName{3} = fullfile(imageDir, 'lightBulb');
imageName{4} = fullfile(imageDir, 'shirt');
imageName{5} = fullfile(imageDir, 'toilet');
imageName{6} = fullfile(imageDir, 'bathtub');
imageName{7} = fullfile(imageDir, 'bed');
imageName{8} = fullfile(imageDir, 'envelope');
imageName{9} = fullfile(imageDir, 'glass');
imageName{10} = fullfile(imageDir, 'phone');
imageName{11} = fullfile(imageDir, 'television');
imageName{12} = fullfile(imageDir, 'window');

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
% imStartV    = round( ( scrPos(4) - (ssvepMatrix(1)-1)*SSVEPGapV - ssvepMatrix(1)*SSVEPSizeV + vPaddT + vPaddB ) / 2 );
% imStartH    = round( ( scrPos(3) - (ssvepMatrix(2)-1)*S SVEPGapH - ssvepMatrix(2)*SSVEPSizeH + hPaddL + hPaddR ) / 2 );
% imEndV      = scrPos(4) - imStartV;
% imEndH      = scrPos(3) - imStartH;

% imSizeH = ssvepMatrix(2)*SSVEPSizeH + (ssvepMatrix(2)-1)*SSVEPGapH - 2*SSVEPMarginH + hPaddL + hPaddR;
% imSizeV = ssvepMatrix(1)*SSVEPSizeV + (ssvepMatrix(1)-1)*SSVEPGapV - 2*SSVEPMarginV + vPaddT + vPaddB;
imSizeH = SSVEPSizeH;
imSizeV = SSVEPSizeV;

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
        for iSsvep = 1:nSsvep % for each ssvep square
        
            for iStim = 1:nItems+1 % for each stimulus
        
                stimImage = zeros(imSizeV, imSizeH, 3, 'uint8');
                stimAlpha = zeros(imSizeV, imSizeH, 'uint8');
        
                for iIcon = 1:nItems % for each icon composing the stimulus
        
                    indImToRead     = (iSsvep-1)*nItems + iIcon;
                    [vPosInMatrix hPosInMatrix] = ind2sub(eltMatrix, iIcon);
                    
                    distFromLeft    = SSVEPMarginH + (hPosInMatrix-1) * ( eltSizeH + eltGapH );
                    distFromTop     = SSVEPMarginV + (vPosInMatrix-1) * ( eltSizeV + eltGapV );
        
                    if iIcon == iStim % if target icon
                        hRange          = distFromLeft - hPaddL + (1:eltSizeH_flash);
                        vRange          = distFromTop - vPaddT + (1:eltSizeV_flash);
                        
                        flashImageName = [imageName{indImToRead} '-yellow.png'];
                        
                        [A, ~, alpha]   = imread(flashImageName);
                        A               = imresize(A, [eltSizeH_flash, eltSizeV_flash]);
                        alpha           = imresize(alpha, [eltSizeH_flash, eltSizeV_flash]);
                        
                        stimImage( vRange, hRange, : ) = A;
                        stimAlpha( vRange, hRange )    = alphaFactorFlash*alpha;
                        
                        
                    else % if non-target icon
                        
                        hRange          = distFromLeft + (1:eltSizeH);
                        vRange          = distFromTop + (1:eltSizeV);
                        
                        [A, ~, alpha]   = imread(dimmedImageName{indImToRead});
                        A               = imresize(A, [eltSizeH, eltSizeV]);
                        alpha           = imresize(alpha, [eltSizeH, eltSizeV]);
                        
                        stimImage( vRange, hRange, : ) = A;
                        stimAlpha( vRange, hRange )    = alphaFactorDim*alpha;
                        
                    end
                    
                end % OF iIcon LOOP
                
                if ~isequal(size(stimImage), [imSizeV, imSizeH, 3]), error('wrong image size'); end
                indStim = (iSsvep-1)*(nItems+1) + iStim;
                imwrite(stimImage, [texturesDir sprintf('stimulus-%.2d.png', indStim)], 'Alpha', stimAlpha);

            end % OF iStim LOOP
        
        end % OF iSsvep LOOP
        
    end


    %==========================================================================
    %==========================================================================
    function sc = generateScenarioAndStimuli()
        
        %% Generate stimuli and calculate positions
        %==========================================================================
        
        %--------------------------------------------------------------------------
        % P300 stimuli
        P300StimPos = zeros(nSsvep, 4);
        for iSsvep = 1:nSsvep
            
            [vIndSsvep hIndSsvep]   = ind2sub(ssvepMatrix, iSsvep);
            distFromLeft            = ssvepStartH + (hIndSsvep-1)*(SSVEPSizeH+SSVEPGapH);
            distFromTop             = ssvepStartV + (vIndSsvep-1)*(SSVEPSizeV+SSVEPGapV);
            hEnd                    = distFromLeft + imSizeH;
            vEnd                    = distFromTop + imSizeV;
            P300StimPos(iSsvep, :)  = [ distFromLeft+1 distFromTop+1 hEnd vEnd ];
            
        end
        %--------------------------------------------------------------------------
        % Cue stimuli
        CuePos      = zeros(nSsvep*nItems, 4); % for .xml scenario (and PTB)
        for iSsvep = 1:nSsvep
            
            [vIndSsvep hIndSsvep] = ind2sub(ssvepMatrix, iSsvep);
            distFromLeft    = ssvepStartH + (hIndSsvep-1)*(SSVEPSizeH+SSVEPGapH);
            distFromTop     = ssvepStartV + (vIndSsvep-1)*(SSVEPSizeV+SSVEPGapV);
            
            for iIcon = 1:nItems
                
                [vPosInMatrix hPosInMatrix] = ind2sub(eltMatrix, iIcon);
                
                distFromLeft2    = distFromLeft + SSVEPMarginH + (hPosInMatrix-1) * ( eltSizeH + eltGapH );
                distFromTop2     = distFromTop  + SSVEPMarginV + (vPosInMatrix-1) * ( eltSizeV + eltGapV );
                
                CuePos( (iSsvep-1)*nItems + iIcon, :) = ...
                    [ distFromLeft2 + 1, ...
                    distFromTop2 + 1, ...
                    distFromLeft2 + eltSizeH, ...
                    distFromTop2 + eltSizeV ];
                
            end
        end
        
        %--------------------------------------------------------------------------
        % SSVEP stimuli
        SSVEPStimPos = zeros(nSsvep, 4);
        for iSsvep = 1:nSsvep
            
            [vIndSsvep hIndSsvep] = ind2sub(ssvepMatrix, iSsvep);
            hStart = ssvepStartH +(hIndSsvep-1)*(SSVEPSizeH+SSVEPGapH);
            vStart = ssvepStartV +(vIndSsvep-1)*(SSVEPSizeV+SSVEPGapV);
            SSVEPStimPos(iSsvep, :) = [ ...
                hStart + 1 ...
                vStart + 1 ...
                hStart + SSVEPSizeH ...
                vStart + SSVEPSizeV ...
                ];
                
        end        
        
        
        %% Create scenario structure
        %==========================================================================
        sc = [];
        sc.description = 'Watch ERP with 2 SSVEP flicker';
        sc.desired.scr.nCols = scrPos(3);
        sc.desired.scr.nRows = scrPos(4);
        
        %--------------------------------------------------------------------------
        % textures
        sc.textures(1).filename = 'ssvep-pixel.png';                                % SSVEP texture
        for iStim = 1:nSsvep*(nItems+1)
            sc.textures(iStim+1).filename = sprintf('stimulus-%.2d.png', iStim);    % P3 textures
        end
%         sc.textures(nSsvep*(nItems+1)+2).filename = 'target-crosshair.png';                    % cue texture
        sc.textures(nSsvep*(nItems+1)+2).filename = 'target-crosshair-yellow2.png';                             % cue texture
        
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
        for iSsvep = 1:nSsvep
            sc.stimuli(iSsvep).description               = 'SSVEP stimulus';
            sc.stimuli(iSsvep).stateSequence             = 1;
            sc.stimuli(iSsvep).durationSequenceInSec     = Inf;
            sc.stimuli(iSsvep).desired.position          = SSVEPStimPos(iSsvep, :);
            sc.stimuli(iSsvep).states(1).frequency       = 15;
            sc.stimuli(iSsvep).states(1).initialPhase    = 0.00000000000000000000000000;
            sc.stimuli(iSsvep).states(1).views.iTexture  = 1;
            sc.stimuli(iSsvep).states(2).frequency       = 0;
            sc.stimuli(iSsvep).states(2).initialPhase    = 0.00000000000000000000000000;
            sc.stimuli(iSsvep).states(2).views.iTexture  = 0;
            sc.stimuli(iSsvep).eventMatrix               = [ 0  find( cellfun( @(x) strcmp(x, 'SSVEP stim off'), {sc.events(:).desc} ) ) ; ...
                find( cellfun( @(x) strcmp(x, 'SSVEP stim on'), {sc.events(:).desc} ) ) 0  ];
        end
        
        %--------------------------------------------------------------------------
        % P300 stimuli
        for iSsvep = 1:nSsvep
            
            sc.stimuli(nSsvep+iSsvep).description               = 'P300 stimulus';
            sc.stimuli(nSsvep+iSsvep).stateSequence             = 1;
            sc.stimuli(nSsvep+iSsvep).durationSequenceInSec     = Inf;
            sc.stimuli(nSsvep+iSsvep).desired.position          = P300StimPos( iSsvep, : );
            iState = 1;
            sc.stimuli(nSsvep+iSsvep).eventMatrix = zeros(2*nItems+1);
            for iS = 1:nItems
                sc.stimuli(nSsvep+iSsvep).states(iState).views.iTexture     = (iSsvep-1)*(nItems+1)+iS+1;       % real
                sc.stimuli(nSsvep+iSsvep).states(iState+1).views.iTexture   = (iSsvep-1)*(nItems+1)+iS+1;       % fake
                
                sc.stimuli(nSsvep+iSsvep).eventMatrix(iState, 2:2:2*nItems) = find( cellfun( @(x) strcmp(x, 'P300 stim off'), {sc.events(:).desc} ) ); % from real to fake (reset binary marker)
                sc.stimuli(nSsvep+iSsvep).eventMatrix(iState+1, 1:2:2*nItems-1) = find( cellfun( @(x) strcmp(x, 'P300 stim on'), {sc.events(:).desc} ) ); % from fake to real (set binary marker)
                
                iState = iState+2;
            end
            
            sc.stimuli(nSsvep+iSsvep).states(iState).views.iTexture  = iSsvep*(nItems+1)+1; 
            sc.stimuli(nSsvep+iSsvep).eventMatrix(2*nItems+1, 1:2:2*nItems-1) = ...
                find( cellfun( @(x) strcmp(x, 'P300 stim on'), {sc.events(:).desc} ) ); % from nothing to real (set binary marker)
            sc.stimuli(nSsvep+iSsvep).eventMatrix(1:2:2*nItems-1, 2*nItems+1) = ...
                find( cellfun( @(x) strcmp(x, 'P300 stim off'), {sc.events(:).desc} ) ); % from real to nothing (reset binary marker)
            
        end
        
        %--------------------------------------------------------------------------
        % cue stimulus
        sc.stimuli(2*nSsvep+1).description               = 'Look here stimulus';
        sc.stimuli(2*nSsvep+1).stateSequence             = 1;
        sc.stimuli(2*nSsvep+1).durationSequenceInSec     = Inf;
        sc.stimuli(2*nSsvep+1).desired.position          = [0 0 0 0];
        for iEl = 1:nSsvep*nItems
            sc.stimuli(2*nSsvep+1).states(iEl).position         = CuePos(iEl, :);
            sc.stimuli(2*nSsvep+1).states(iEl).views.iTexture   = nSsvep*(nItems+1)+2;
            sc.stimuli(2*nSsvep+1).states(iEl).frequency      = 2;
        end
        sc.stimuli(2*nSsvep+1).states(nSsvep*nItems+1).position = [0 0 0 0];
        sc.stimuli(2*nSsvep+1).states(nSsvep*nItems+1).views.iTexture = 0;
        sc.stimuli(2*nSsvep+1).eventMatrix = zeros(nSsvep*nItems+1);
        sc.stimuli(2*nSsvep+1).eventMatrix(nSsvep*nItems+1, 1:nSsvep*nItems) = ...
            find( cellfun( @(x) strcmp(x, 'Cue on'), {sc.events(:).desc} ) );
        sc.stimuli(2*nSsvep+1).eventMatrix(1:nSsvep*nItems, nSsvep*nItems+1) = ...
            find( cellfun( @(x) strcmp(x, 'Cue off'), {sc.events(:).desc} ) );
        
    end


end







