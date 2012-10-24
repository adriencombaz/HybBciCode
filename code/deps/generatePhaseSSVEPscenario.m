%% generate phase SSVEP scenario(s)
clc

outputDir           = 'scenarios/';
stimFrequency       = 15;
nTargetStimuliList  = [1 2 4 5 6 8 9 10 12];

% settings for screen 1024x768
screenSetupList(1).nScreenCols          = 1024;
screenSetupList(1).nScreenRows          = 768;
screenSetupList(1).stimWidth            = 200;
screenSetupList(1).stimHeight           = screenSetupList(1).stimWidth;
screenSetupList(1).horGap               = 64;
screenSetupList(1).verGap               = screenSetupList(1).horGap;
screenSetupList(1).nTargetStimuliList   = [1 2 4 5 6 8 9 10 12];
screenSetupList(1).filenameTemplate     = 'phaseSSVEP-%02g-stim@%gx%g.xml';

% settings for screen 1920x1200
screenSetupList(2).nScreenCols          = 1920;
screenSetupList(2).nScreenRows          = 1200;
screenSetupList(2).stimWidth            = 350;
screenSetupList(2).stimHeight           = screenSetupList(2).stimWidth;
screenSetupList(2).horGap               = 64;
screenSetupList(2).verGap               = screenSetupList(2).horGap;
screenSetupList(2).nTargetStimuliList   = [1 2 4 5 6 8 9 10 12];
screenSetupList(2).filenameTemplate     = 'phaseSSVEP-%02g-stim@%gx%g.xml';

% settings for screen 1920x1200 (without margins)
screenSetupList(3).nScreenCols          = 1920;
screenSetupList(3).nScreenRows          = 1200;
screenSetupList(3).stimWidth            = 350;
screenSetupList(3).stimHeight           = screenSetupList(3).stimWidth;
screenSetupList(3).horGap               = 435;
screenSetupList(3).verGap               = 450;
screenSetupList(3).nTargetStimuliList   = [5 6];
screenSetupList(3).filenameTemplate     = 'phaseSSVEP-%02g-stim@%gx%g-wide.xml';


for iSS = 1:numel( screenSetupList ),
    
    nScreenCols         = screenSetupList(iSS).nScreenCols;
    nScreenRows         = screenSetupList(iSS).nScreenRows;
    stimWidth           = screenSetupList(iSS).stimWidth;
    stimHeight          = screenSetupList(iSS).stimHeight;
    horGap              = screenSetupList(iSS).horGap;
    verGap              = screenSetupList(iSS).verGap;
    nTargetStimuliList  = screenSetupList(iSS).nTargetStimuliList;
    filenameTemplate    = screenSetupList(iSS).filenameTemplate;
    
    
    for nTargetStimuli = nTargetStimuliList;
        
        fprintf( 'Generating scenario for %g stimuli\n', nTargetStimuli );
        switch nTargetStimuli,
            case 9,
                nStimuliCols = 3;
                nStimuliRows = 3;
            case 10,
                nStimuliCols = 4;
                nStimuliRows = 3;
            case 16,
                nStimuliCols = 4;
                nStimuliRows = 4;
                
            otherwise,
                nStimuliRows = round( sqrt( nTargetStimuli * nScreenRows / nScreenCols ) );
                nStimuliCols = ceil( nTargetStimuli / nStimuliRows );
                %             nStimuliCols = round( sqrt( nTargetStimuli * nScreenCols / nScreenRows ) );
                %             nStimuliRows = ceil( nTargetStimuli / nStimuliCols );
        end
        scenarioFilename = sprintf( ['%s' filenameTemplate], outputDir, nTargetStimuli, nScreenCols, nScreenRows );
        
        stimRegionWidth = stimWidth*nStimuliCols + horGap*(nStimuliCols-1);
        stimRegionHeight= stimHeight*nStimuliRows + verGap*(nStimuliRows-1);
        
        topMargin       = floor( (nScreenRows - stimRegionHeight) / 2 );
        leftMargin      = floor( (nScreenCols - stimRegionWidth) / 2 );
        bottomMargin    = nScreenRows - stimRegionHeight - topMargin;
        rightMargin     = nScreenCols - stimRegionWidth - leftMargin;
        
        if (nTargetStimuli==8) && (nStimuliCols==3) && (nStimuliRows==3),
            skipCells   = [2 2]; % row, col
        elseif (nTargetStimuli==5) && (nStimuliCols==3) && (nStimuliRows==2),
            skipCells   = [2 3]; % row, col
        elseif (nTargetStimuli==10) && (nStimuliCols==4) && (nStimuliRows==3),
            skipCells   = [2 2; 2 3]; % row, col
        else
            skipCells   = [];
        end
        nSkipCells = size( skipCells, 1 );
        assert( nStimuliCols*nStimuliRows-nSkipCells == nTargetStimuli, ...
            'Number of stimuli and their arrangement don''t fit' );
        
        
        f = fopen( scenarioFilename, 'w' );
        fprintf( f, '<scenario class="struct">\n' );
        fprintf( f, '    <description>phase-based SSVEP scanner (%g stimuli)</description>\n\n', nTargetStimuli );
        fprintf( f, '    <!-- Desired parameter values section -->\n' );
        fprintf( f, '    <desired class="struct">\n' );
        fprintf( f, '        <stimulationDuration class="double">%g</stimulationDuration>\n', nTargetStimuli );
        fprintf( f, '        <scr class="struct">\n' );
        fprintf( f, '            <nCols class="double">%g</nCols>\n', nScreenCols );
        fprintf( f, '            <nRows class="double">%g</nRows>\n', nScreenRows );
        fprintf( f, '        </scr>\n' );
        fprintf( f, '    </desired>\n\n' );
        fprintf( f, '    <!-- Textures section -->\n' );
        fprintf( f, '    <textures class="struct">\n' );
        fprintf( f, '        <filename>yellow-pixel.png</filename>\n' );
%         fprintf( f, '        <filename>red-dot.png</filename>\n' );
        fprintf( f, '        <filename>target-stimulus-marker.png</filename>\n' );
        fprintf( f, '    </textures>\n\n' );
        
        fprintf( f, '    <!-- Events section -->\n' );
        fprintf( f, '	<events class="struct">\n' );
        for iSt = 1:nTargetStimuli,
            fprintf( f, '		<desc>stimulus %g marked</desc>  <id class="double">%g</id>\n', iSt, iSt );
        end
        fprintf( f, '		<desc>no stimuli marked</desc>  <id class="double">0</id>\n' );
        fprintf( f, '		<desc>round finished</desc>     <id class="double">0.15</id>\n' );
        fprintf( f, '		<desc>out of main loop</desc>   <id class="double">0.2</id>\n' );
        fprintf( f, '		<desc>preparation</desc>        <id class="double">-1</id>\n' );
        fprintf( f, '		<desc>finishing</desc>          <id class="double">-2</id>\n' );
        fprintf( f, '    </events>\n' );
        fprintf( f, '    <iMainLoopStopEvent class="double">%g</iMainLoopStopEvent>\n', nTargetStimuli+3 );
        fprintf( f, '    <frameBasedEventIdAdjust class="double">0.1</frameBasedEventIdAdjust>\n' );
        fprintf( f, '    <issueFrameBasedEvents class="logical">1</issueFrameBasedEvents>\n' );
        fprintf( f, '    <issueTimeBasedEvents class="logical">1</issueTimeBasedEvents>\n' );
        fprintf( f, '    <correctStimulusAppearanceTime class="logical">1</correctStimulusAppearanceTime>\n' );
        fprintf( f, '    <useBinaryIntensity class="logical">0</useBinaryIntensity>\n\n' );
        
        fprintf( f, '    <!-- Stimuli section -->\n' );
        fprintf( f, '    <stimuli class="struct">\n' );
        
        iSt = 0;
        stPositions = zeros( nTargetStimuli, 4 ); % position vectors of the target stimuli
        
        for iStCol = 1:nStimuliCols,
            for iStRow = 1:nStimuliRows,
                if nSkipCells>0 && any( (iStRow == skipCells(:,1)) .* (iStCol == skipCells(:,2)) ),
                    fprintf( 'Skipping cell (row=%g, col=%g)\n', iStRow, iStCol );
                    continue
                end
                iSt = iSt + 1;
                fprintf( 'Generating stimulus #%g (row=%g, col=%g)\n', iSt, iStRow, iStCol );
                stPositions(iSt,1:2) = [ leftMargin+(iStCol-1)*(stimWidth+horGap)+1  topMargin+(iStRow-1)*(stimHeight+verGap)+1 ];
                stPositions(iSt,3:4) = stPositions(iSt,1:2) + [stimWidth-1 stimHeight-1];
                
                fprintf( f, '        <!-- Stimulus %g -->\n', iSt );
                fprintf( f, '        <description>(%g*pi/%g)-phase stimulus</description>\n', 2*(iSt-1), nTargetStimuli );
                fprintf( f, '        <stateSequence class="double">1</stateSequence>\n' );
                fprintf( f, '        <durationSequenceInSec class="double">Inf</durationSequenceInSec>\n' );
                fprintf( f, '        <desired class="struct">\n' );
                fprintf( f, '            <position class="double">%g %g %g %g</position>\n', stPositions(iSt,:) );
                fprintf( f, '        </desired>\n' );
                fprintf( f, '        <states class="struct">\n' );
                fprintf( f, '            <frequency class="double">%g</frequency>\n', stimFrequency );
                fprintf( f, '            <initialPhase class="double">%16.14f</initialPhase>\n', 2*pi*(iSt-1)/nTargetStimuli );
                fprintf( f, '            <views class="struct">\n' );
                fprintf( f, '                <iTexture class="double">1</iTexture>\n' );
                fprintf( f, '            </views>\n' );
                fprintf( f, '            <frequency class="double">%g</frequency>\n', stimFrequency );
                fprintf( f, '            <initialPhase class="double">%16.14f</initialPhase>\n', 2*pi*(iSt-1)/nTargetStimuli );
                fprintf( f, '            <views class="struct">\n' );
                fprintf( f, '                <iTexture class="double">0</iTexture>\n' );
                fprintf( f, '            </views>\n' );
                fprintf( f, '        </states>\n' );
                fprintf( f, '        <eventMatrix class="double" size="2 2">0 0 0 0</eventMatrix>\n\n' );
            end % of loop over stimluli grid rows
        end % of loop over stimluli grid columns
        
        
        fprintf( f, '        <!-- Last ("look here") stimulus -->\n' );
        fprintf( f, '        <description>Look here stimulus</description>\n' );
        fprintf( f, '        <stateSequence class="double">%s</stateSequence>\n', sprintf( '%g ', 1:nTargetStimuli ) );
        fprintf( f, '        <durationSequenceInSec class="double">1</durationSequenceInSec>\n' );
        fprintf( f, '        <desired class="struct">\n' );
        fprintf( f, '            <position class="double">0 0 0 0</position>\n' );
        fprintf( f, '        </desired>\n' );
        fprintf( f, '        <states class="struct">\n' );
        for iSt = 1:nTargetStimuli,
            fprintf( f, '            <position class="double">%g %g %g %g</position>\n', stPositions(iSt,:) );
            fprintf( f, '            <views class="struct">\n' );
            fprintf( f, '                <iTexture class="double">2</iTexture>\n' );
            fprintf( f, '            </views>\n' );
        end % of loop over target stimuli
        
        fprintf( f, '            <position class="double">0 0 0 0</position>\n' );
        fprintf( f, '            <views class="struct">\n' );
        fprintf( f, '                <iTexture class="double">2</iTexture>\n' );
        fprintf( f, '            </views>\n' );
        fprintf( f, '        </states>\n' );
        
        fprintf( f, '        <eventMatrix class="double" size="%g %g">\n', nTargetStimuli+1, nTargetStimuli+1 );
        for iSt = 1:nTargetStimuli+1,
            fprintf( f, '            %s\n', sprintf( ' %2g', iSt(ones( 1, nTargetStimuli+1 )) ) );
        end
        fprintf( f, '        </eventMatrix>\n\n' );
        fprintf( f, '    </stimuli>\n\n' );
        fprintf( f, '</scenario>' );
        
        fclose( f );
    end % of loop over scenarios
    
end % of loop over screen setups