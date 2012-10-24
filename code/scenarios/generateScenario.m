function generateScenario


%% Init parameters
%==========================================================================
nSSVEP      = 1;
SSVEPMatrix = [1 1];
eltMatrix   = [3 2];
nEltPerSSVEP= prod(eltMatrix);
nItems      = nEltPerSSVEP*nSSVEP;

scrPos      = get(0, 'ScreenSize');
eltSizeH    = 175; %150;%200;
eltSizeV    = 175; %150;%200;
eltGapH     = 175; %100;%200;
eltGapV     = 175; %100;%200;
eltMarginH  = 100; %100;%50;
eltMarginV  = 100; %100;%50;
SSVEPGapH   = 500;
SSVEPGapV   = 600;

SSVEPSizeH  = 2*eltMarginH + eltMatrix(2)*(eltSizeH+eltGapH) - eltGapH;
SSVEPSizeV  = 2*eltMarginV + eltMatrix(1)*(eltSizeV+eltGapV) - eltGapV;

SSVEPMarginH = round( ( scrPos(3) - SSVEPMatrix(2)*(SSVEPSizeH+SSVEPGapH) + SSVEPGapH ) / 2 );
if SSVEPMarginH < 0
    error('SSVEPMarginH < 0!!!');
end
SSVEPMarginV = round( ( scrPos(4) - SSVEPMatrix(1)*(SSVEPSizeV+SSVEPGapV) + SSVEPGapV ) / 2 );
if SSVEPMarginH < 0
    error('SSVEPMarginH < 0!!!');
end


%% Full icons scenario
%==========================================================================

imageDir    = 'pictures\';
imageName{1} = fullfile(imageDir, 'apple');
imageName{2} = fullfile(imageDir, 'medicine');
imageName{3} = fullfile(imageDir, 'lightBulb');
imageName{4} = fullfile(imageDir, 'shirt');
imageName{5} = fullfile(imageDir, 'toilet');
imageName{6} = fullfile(imageDir, 'bathtub');
imageName = cellfun( @(x) [x '.png'], imageName, 'UniformOutput', false );


texturesDir = 'textures\';
if ~exist(texturesDir, 'dir'), mkdir(texturesDir); end

generateBackgroundImage(imageName);
generateScenarioAndStimuli_Hybrid();


    %==========================================================================
    %==========================================================================
    %
    %                       NESTED FUNCTIONS
    %
    %==========================================================================
    %==========================================================================

    %==========================================================================
    %==========================================================================
    function generateBackgroundImage(imageName)
    
        %--------------------------------------------------------------------------
        % background images
        hStart      = SSVEPMarginH + eltMarginH;
        vStart      = SSVEPMarginV + eltMarginV;
        hEnd        = scrPos(3) - SSVEPMarginH - eltMarginH;
        vEnd        = scrPos(4) - SSVEPMarginV - eltMarginV;
        
        hSize       = hEnd - hStart;
        vSize       = vEnd - vStart;
        
        imToRead  = imageName;
        stimImage = zeros(vSize, hSize, 3, 'uint8');
        stimAlpha = zeros(vSize, hSize, 'uint8');
        for iIcon = 1:nItems
            
            [iInSquare iSquare] = ind2sub([nEltPerSSVEP, nSSVEP], iIcon);
            [vPosInMatrix hPosInMatrix] = ind2sub(eltMatrix, iInSquare);
            
            distFromLeft    = (iSquare-1) *(SSVEPSizeH + SSVEPGapH) + (hPosInMatrix-1) * ( eltSizeH + eltGapH );
            distFromTop     = (vPosInMatrix-1) * ( eltSizeV + eltGapV );
            hRange          = distFromLeft + (1:eltSizeH);
            vRange          = distFromTop + (1:eltSizeV);
            
            [A, ~, alpha]   = imread(imToRead{iIcon});
            A               = imresize(A, [eltSizeH, eltSizeV]);
            alpha           = imresize(alpha, [eltSizeH, eltSizeV]);
            
            stimImage( vRange, hRange, :) = A;
            stimAlpha( vRange, hRange)    = alpha/2;
            
        end
        
        imwrite(stimImage, [texturesDir 'icons-background.png'], 'Alpha', stimAlpha);
    
    end


    %==========================================================================
    %==========================================================================
    function generateScenarioAndStimuli_Hybrid()
        
        %% Generate stimuli and calculate positions
        %==========================================================================
        
        %--------------------------------------------------------------------------
        % P300 and cue stimuli
        hStart      = SSVEPMarginH + eltMarginH;
        vStart      = SSVEPMarginV + eltMarginV;
        hEnd        = scrPos(3) - SSVEPMarginH - eltMarginH;
        vEnd        = scrPos(4) - SSVEPMarginV - eltMarginV;
        P300StimPos = [ hStart+1 vStart+1 hEnd vEnd ];
        
        CuePos      = zeros(nItems, 4); % for .xml scenario (and PTB)
        
        for iIcon = 1:nItems
            
            [iInSquare iSquare] = ind2sub([nEltPerSSVEP, nSSVEP], iIcon);
            [vPosInMatrix hPosInMatrix] = ind2sub(eltMatrix, iInSquare);
            
            distFromLeft    = (iSquare-1) *(SSVEPSizeH + SSVEPGapH) + (hPosInMatrix-1) * ( eltSizeH + eltGapH );
            distFromTop     = (vPosInMatrix-1) * ( eltSizeV + eltGapV ); 
            
            CuePos(iIcon, :) = ...
                [ SSVEPMarginH + eltMarginH + distFromLeft + 1, ...
                SSVEPMarginV + eltMarginV + distFromTop + 1, ...
                SSVEPMarginH + eltMarginH + distFromLeft + eltSizeH, ...
                SSVEPMarginV + eltMarginV + distFromTop + eltSizeV ];
            
        end
        
        %--------------------------------------------------------------------------
        % SSVEP stimuli
        SSVEPStimPos    = zeros(nSSVEP, 4);
        for iSSVEP = 1:nSSVEP
            [ivS ihS] = ind2sub(SSVEPMatrix, iSSVEP);
            hStart  = SSVEPMarginH + (ihS-1)*(SSVEPSizeH+SSVEPGapH);  % from left
            vStart  = SSVEPMarginV + (ivS-1)*(SSVEPSizeV+SSVEPGapV);  % from top
            hEnd    = hStart + SSVEPSizeH;
            vEnd    = vStart + SSVEPSizeV;
            SSVEPStimPos(iSSVEP, :) = [ hStart+1 vStart+1 hEnd vEnd ];
        end
        
        
        %% Write .xml scenario
        %==========================================================================
        scFileName = sprintf('Hybrid-%.2d-SSVEP-%.2d-P300-stim@%dx%d.xml', nSSVEP, nEltPerSSVEP, scrPos(3), scrPos(4));
        scFile = fopen(scFileName, 'w');
        
        fprintf(scFile, '<scenario class="struct">\n');
        fprintf(scFile, '    <description>Hybrid scanner (%d SSVEP, %d items)</description>\n\n', nSSVEP, nEltPerSSVEP);
        
        
        fprintf(scFile, '    <!-- Desired parameter values section -->\n');
        fprintf(scFile, '    <desired class="struct">\n');
        fprintf(scFile, '        <scr class="struct">\n');
        fprintf(scFile, '            <nCols class="double">%d</nCols>\n', scrPos(3));
        fprintf(scFile, '            <nRows class="double">%d</nRows>\n', scrPos(4));
        fprintf(scFile, '        </scr>\n');
        fprintf(scFile, '    </desired>\n\n');
        
        %--------------------------------------------------------------------------
        % textures
        fprintf(scFile, '    <!-- Textures section -->\n');
        fprintf(scFile, '    <textures class="struct">\n');
        fprintf(scFile, '        <filename>icons-background.png</filename>\n');
        fprintf(scFile, '        <filename>yellow-pixel.png</filename>\n');
        fprintf(scFile, '        <filename>target-crosshair.png</filename>\n');
        fprintf(scFile, '        <filename>red-disk.png</filename>\n');
        fprintf(scFile, '    </textures>\n\n');
        
        %--------------------------------------------------------------------------
        % Events
        fprintf(scFile, '    <!-- Events section -->\n');
        fprintf(scFile, '	<events class="struct">\n');
        fprintf(scFile, '		<desc>start event</desc>        <id class="double">1</id>\n');
        fprintf(scFile, '		<desc>end event</desc>          <id class="double">-1</id>\n');
        fprintf(scFile, '		<desc>Cue on</desc>             <id class="double">2</id>\n');
        fprintf(scFile, '		<desc>Cue off</desc>            <id class="double">-2</id>\n');
        fprintf(scFile, '		<desc>SSVEP stim on</desc>      <id class="double">4</id>\n');
        fprintf(scFile, '		<desc>SSVEP stim off</desc>     <id class="double">-4</id>\n');
        fprintf(scFile, '		<desc>P300 stim on</desc>       <id class="double">8</id>\n');
        fprintf(scFile, '		<desc>P300 stim off</desc>      <id class="double">-8</id>\n');
        fprintf(scFile, '    </events>\n');
        fprintf(scFile, '    <iStartEvent class="double">1</iStartEvent>\n');
        fprintf(scFile, '    <iEndEvent class="double">2</iEndEvent>\n');
        fprintf(scFile, '    <frameBasedEventIdAdjust class="double">0</frameBasedEventIdAdjust>\n');
        fprintf(scFile, '    <issueFrameBasedEvents class="logical">1</issueFrameBasedEvents>\n');
        fprintf(scFile, '    <issueTimeBasedEvents class="logical">0</issueTimeBasedEvents>\n');
        fprintf(scFile, '    <correctStimulusAppearanceTime class="logical">1</correctStimulusAppearanceTime>\n');
        fprintf(scFile, '    <useBinaryIntensity class="logical">0</useBinaryIntensity>\n\n');
        
        fprintf(scFile, '    <!-- Stimuli section -->\n');
        fprintf(scFile, '    <stimuli class="struct">\n');
        
        %--------------------------------------------------------------------------
        % SSVEP stimuli
        for iSSVEP = 1:nSSVEP
            fprintf(scFile, '        <!-- SSVEP stimulus %d -->\n', iSSVEP);
            fprintf(scFile, '        <description>SSVEP stimulus</description>\n');
            fprintf(scFile, '        <stateSequence class="double">1</stateSequence>\n');
            fprintf(scFile, '        <durationSequenceInSec class="double">Inf</durationSequenceInSec>\n');
            fprintf(scFile, '        <desired class="struct">\n');
            fprintf(scFile, '            <position class="double">%d %d %d %d</position>\n', SSVEPStimPos(iSSVEP, :));
            fprintf(scFile, '        </desired>\n');
            fprintf(scFile, '        <states class="struct">\n');
            fprintf(scFile, '            <frequency class="double">15</frequency>\n');
            fprintf(scFile, '            <initialPhase class="double">0.00000000000000</initialPhase>\n');
            fprintf(scFile, '            <views class="struct">\n');
            fprintf(scFile, '                <iTexture class="double">2</iTexture>\n');
            fprintf(scFile, '            </views>\n');
            fprintf(scFile, '            <frequency class="double">15</frequency>\n');
            fprintf(scFile, '            <initialPhase class="double">0.00000000000000</initialPhase>\n');
            fprintf(scFile, '            <views class="struct">\n');
            fprintf(scFile, '                <iTexture class="double">0</iTexture>\n');
            fprintf(scFile, '            </views>\n');
            fprintf(scFile, '        </states>\n');
            fprintf(scFile, '        <eventMatrix class="double" size="2 2">0 5 6 0</eventMatrix>\n\n');
        end
        
        %--------------------------------------------------------------------------
        % icons background
        fprintf(scFile, '        <!-- Icons background -->\n');
        fprintf(scFile, '        <description>Icons background</description>\n');
        fprintf(scFile, '        <stateSequence class="double">1</stateSequence>\n');
        fprintf(scFile, '        <durationSequenceInSec class="double">0.1</durationSequenceInSec>\n');
        fprintf(scFile, '        <desired class="struct">\n');
        fprintf(scFile, '            <position class="double">%d %d %d %d</position>\n', P300StimPos);
        fprintf(scFile, '        </desired>\n');
        fprintf(scFile, '        <states class="struct">\n');
        fprintf(scFile, '            <views class="struct">\n');
        fprintf(scFile, '                <iTexture class="double">1</iTexture>\n');
        fprintf(scFile, '            </views>\n');
        fprintf(scFile, '        </states>\n');
        fprintf(scFile, '        <eventMatrix class="double" size="1 1">0</eventMatrix>\n\n');
        
        %--------------------------------------------------------------------------
        % P300 stimuli
        fprintf(scFile, '        <!-- P300 stimulus -->\n');
        fprintf(scFile, '        <description>P300 stimulus</description>\n');
        fprintf(scFile, '        <stateSequence class="double">');
        for iEl = 1:nItems
            fprintf(scFile, '%d ', iEl);
        end
        fprintf(scFile, '</stateSequence>\n');
        fprintf(scFile, '        <durationSequenceInSec class="double">1</durationSequenceInSec>\n');
        fprintf(scFile, '        <desired class="struct">\n');
        fprintf(scFile, '            <position class="double">0 0 0 0</position>\n');
        fprintf(scFile, '        </desired>\n');
        fprintf(scFile, '        <states class="struct">\n');
        for iEl = 1:nItems
            for i = 1:2
                fprintf(scFile, '            <position class="double">%d %d %d %d</position>\n', CuePos(iEl, :));
                fprintf(scFile, '            <views class="struct">\n');
                fprintf(scFile, '                <iTexture class="double">4</iTexture>\n');
                fprintf(scFile, '            </views>\n');
            end
        end
        fprintf(scFile, '            <position class="double">0 0 0 0</position>\n');
        fprintf(scFile, '            <views class="struct">\n');
        fprintf(scFile, '                <iTexture class="double">0</iTexture>\n');
        fprintf(scFile, '            </views>\n');
        fprintf(scFile, '        </states>\n');
        fprintf(scFile, '        <eventMatrix class="double" size="%d %d">\n', 2*nItems+1, 2*nItems+1);
        for iEl = 1:nItems
            fprintf(scFile, '              ');
            for jEl = 1:nItems
                fprintf(scFile, '0 7 ');
            end
            fprintf(scFile, '7\n');
            fprintf(scFile, '              ');
            for jEl = 1:nItems
                fprintf(scFile, '8 0 ');
            end
            fprintf(scFile, '0\n');
        end
        fprintf(scFile, '              ');
        for jEl = 1:nItems
            fprintf(scFile, '8 0 ');
        end
        fprintf(scFile, '0\n');
        fprintf(scFile, '        </eventMatrix>\n\n');
        
        %--------------------------------------------------------------------------
        % cue stimulus
        fprintf(scFile, '        <!-- cue stimulus -->\n');
        fprintf(scFile, '        <description>Look here stimulus</description>\n');
        fprintf(scFile, '        <stateSequence class="double">');
        for iEl = 1:nItems
            fprintf(scFile, '%d ', iEl);
        end
        fprintf(scFile, '</stateSequence>\n');
        fprintf(scFile, '        <durationSequenceInSec class="double">1</durationSequenceInSec>\n');
        fprintf(scFile, '        <desired class="struct">\n');
        fprintf(scFile, '            <position class="double">0 0 0 0</position>\n');
        fprintf(scFile, '        </desired>\n');
        fprintf(scFile, '        <states class="struct">\n');
        for iEl = 1:nItems
            fprintf(scFile, '            <position class="double">%d %d %d %d</position>\n', CuePos(iEl, :));
            fprintf(scFile, '            <views class="struct">\n');
            fprintf(scFile, '                <iTexture class="double">3</iTexture>\n');
            fprintf(scFile, '            </views>\n');
        end
        fprintf(scFile, '            <position class="double">0 0 0 0</position>\n');
        fprintf(scFile, '            <views class="struct">\n');
        fprintf(scFile, '                <iTexture class="double">0</iTexture>\n');
        fprintf(scFile, '            </views>\n');
        fprintf(scFile, '        </states>\n');
        fprintf(scFile, '        <eventMatrix class="double" size="%d %d">\n', nItems+1, nItems+1);
        for iEl = 1:nItems
            fprintf(scFile, '              ');
            for jEl = 1:nItems
                fprintf(scFile, '0 ');
            end
            fprintf(scFile, '3\n');
        end
        fprintf(scFile, '              ');
        for jEl = 1:nItems
            fprintf(scFile, '4 ');
        end
        fprintf(scFile, '0\n');
        fprintf(scFile, '        </eventMatrix>\n\n');
        
        %--------------------------------------------------------------------------
        % Finishing
        fprintf(scFile, '    </stimuli>\n\n');
        fprintf(scFile, '</scenario>\n');
        
        fclose(scFile);
        
    end


end







