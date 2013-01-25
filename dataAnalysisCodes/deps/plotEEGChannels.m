function plotEEGChannels(sig, varargin)

% addpath('d:\KULeuven\PhD\Work\hybrid-BCI\code\deps\'); % last version of getItFromGUI...

%% ========================================================================
%                        PARSE INPUT ARGUMENTS

allowedParameterList = {'eventLoc', 'eventType', 'samplingRate', 'chanLabels'};
eventLoc        = [];
eventType       = [];
samplingRate    = 1;
chanLabels      = cellstr( int2str( (1:size(sig, 2))' ) );

iArg = 1;
nParameters = numel( varargin );
while ( iArg <= nParameters ),
    parameterName = varargin{iArg};
    if (iArg < nParameters),
        parameterValue = varargin{iArg+1};
    else
        parameterValue = [];
    end
    iParameter = find( strncmpi( parameterName, allowedParameterList, numel( parameterName ) ) );
    if isempty( iParameter ),
        error( 'plotEEGChannels:UnknownParameterName', ...
            'Unknown parameter name: %s.', parameterName );
    elseif numel( iParameter ) > 1,
        error( 'plotEEGChannels:AmbiguousParameterName', ...
            'Ambiguous parameter name: %s.', parameterName );
    else
        switch( iParameter ),
            case 1,  % eventLoc
                if isnumeric( parameterValue ) ...
                        && sum(size( parameterValue )) == numel( parameterValue ) + 1 ...
                        && min( parameterValue ) >= 1 ...
                        && max( parameterValue) <= size(sig, 1),
                    eventLoc = parameterValue;
                else
                    error('plotEEGChannels:BadEventLocArray', ...
                        'Wrong event location array.');
                end
            case 2,  % eventType
                if isnumeric( parameterValue ) ...
                        && sum(size( parameterValue )) == numel( parameterValue ) + 1,
                    eventType = parameterValue;
                else
                    error('plotEEGChannels:BadEventType', ...
                        'Wrong event type array.');
                end
            case 3,  % SamplingRate
                if isnumeric( parameterValue ) && numel( parameterValue ) == 1,
                    samplingRate = parameterValue;
                else
                    error('plotEEGChannels:BadSamplingRate', ...
                        'Wrong sampling rate input.');
                end
            case 4,  % chanLabels
                if iscellstr( parameterValue ) && numel( parameterValue ) == size(sig, 2),
                    chanLabels = parameterValue;
                else
                    error('plotEEGChannels:chanLabels', ...
                        'Wrong channels labels input.');
                end
        end % of iParameter switch
    end % of unique acceptable iParameter found branch
    
    if isempty( parameterValue  ),
        iArg = iArg + 1;
    else
        iArg = iArg + 2;
    end
    
end % of parameter loop


if ~isempty(eventLoc) && ~isempty(eventType) && numel( eventType ) ~= numel( eventLoc )
    error('event locations and types arrays do not have the same size');
end

%% ========================================================================
%                       SET DEFAULT PARAMETERS

%--------------------------------------------------------------------------
% parameters for the gui layout
scrSize = get(0, 'ScreenSize');
nScrCols = scrSize(3);
nScrRows = scrSize(4);

pbLabelList = {'channels', 'x start', 'x window size', 'y zoom +', 'y zoom -', 'scale', 'slide >>', 'slide <<', 'save png'};
nPb                 = numel(pbLabelList);
FS                  = 12; % font size
maxCharPB           = max(cellfun(@numel, pbLabelList));
xPbsSizeInPoints    = (maxCharPB+2)*FS;
yPbsSizeInPoints    = 2*FS;
rightMarginInPoints = 2*FS;
leftMarginInPoints  = 4*FS;
topMarginInPoints   = 2*FS;
bottomMarginInPoints= 2*FS;
axPbSpaceInPoints   = FS;

%--------------------------------------------------------------------------
% default parameters for the display in axes
axProp.showChannel = true(1, numel(chanLabels));  % plot all channels by default

if samplingRate == 1
    axProp.winSizeInSeconds = 5000;
else
    axProp.winSizeInSeconds = 10;
end

axProp.xOffset         = 0; % in samples !!
axProp.ySpacingFactor  = 4;
axProp.yZoomStep       = 1;
axProp.yZoomFactor     = 2;
ySpacing        = 0; % intialize it to be able to share it among function
ySpacingUnit    = 0; % intialize it to be able to share it among function

axProp.LW = 2;

%% ========================================================================
%                           LAYOUT THE GUI
%--------------------------------------------------------------------------
% Lay out the main figure
mfig = figure( ...
    'Name', 'signal explorer', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'Toolbar', 'figure', ...
    'Units', 'pixels', ... % 'normalized', ...
    'Position', [0 0 nScrCols nScrRows] ... % [0 0 1 1] ...
    );
set(mfig, 'Units', 'points');
mfigPos = get(mfig, 'Position');
set(mfig, 'Units', 'pixels');

%--------------------------------------------------------------------------
% Lay out the axis
axPos = [ ...
    leftMarginInPoints, ...
    bottomMarginInPoints, ...
    mfigPos(3) - leftMarginInPoints - rightMarginInPoints - xPbsSizeInPoints - axPbSpaceInPoints, ...
    mfigPos(4) - bottomMarginInPoints - topMarginInPoints ...
    ];

ax = axes( ...
    'Parent', mfig, ...
    'Box', 'off', ...
    'xgrid', 'off', 'ygrid', 'off', ...
    'Units', 'points', ...
    'position', axPos ...
    );
hold(ax);

if ~isempty(eventType)
    cmap = colormap;
    nTyp = numel(unique(eventType));
    for iT = 1:nTyp
        colorTyp(iT,:) = cmap( round( iT*size(cmap,1) / (nTyp+1) ), : );
    end
else
    colorTyp = [1 0 0];
end

%--------------------------------------------------------------------------
% Lay out the scale axis
scaleAxPos = [ ...
    mfigPos(3) - rightMarginInPoints - xPbsSizeInPoints, ...
    bottomMarginInPoints ...
    xPbsSizeInPoints ...
    mfigPos(4) - bottomMarginInPoints - topMarginInPoints ...
    ];

scaleAx = axes( ...
    'Parent', mfig, ...
    'Units', 'points', ...
    'visible', 'off', ...
    'position', scaleAxPos ...
    );


%--------------------------------------------------------------------------
% push buttons
% pbYspaceInPoint = ( mfigPos(4) - topMarginInPoints - bottomMarginInPoints - nPb*yPbsSizeInPoints ) / ( nPb - 1 );
pbYspaceInPoint = yPbsSizeInPoints;
for iPb = 1:nPb
    
    pbPos = [ ...
        mfigPos(3) - rightMarginInPoints - xPbsSizeInPoints, ...
        mfigPos(4) - topMarginInPoints - iPb*yPbsSizeInPoints - (iPb-1)*pbYspaceInPoint, ...
        xPbsSizeInPoints, ...
        yPbsSizeInPoints ...
        ];
    
    pbh(iPb) = uicontrol( ...
        mfig, ...
        'Style', 'pushbutton', ...
        'String', pbLabelList{iPb}, ...
        'Unit', 'points', ...
        'Position', pbPos, ...
        'Callback', @pbCallback ...
        );
end

%--------------------------------------------------------------------------
%
plotData;

    %% ====================================================================
    %                         NESTED FUNCTION
    function plotData
        
        winSizeInSamples    = axProp.winSizeInSeconds*samplingRate + 1;
        chanInd             = find(axProp.showChannel);
        nChan               = numel(chanInd);
%         ySpacingUnit        = max( std( sig(:, chanInd), [], 1 ) );       % can lead to OUT OF MEMORY ERRORS
        temp = zeros(numel(chanInd), 1);
        for iCh = 1:numel(chanInd)
            temp(iCh) = std( sig(:, chanInd(iCh)) );
        end
        ySpacingUnit        = max( temp ); clear temp;
        ySpacing            = axProp.ySpacingFactor*ySpacingUnit;
        ylim                = [0 (nChan+1)*ySpacing];
        yticks              = ySpacing:ySpacing:nChan*ySpacing;
        currentChanList     = chanLabels(chanInd);
        ytickLabel          = currentChanList(end:-1:1);
        
        indSig = axProp.xOffset+1 : min(axProp.xOffset+winSizeInSamples, size(sig, 1));
        yData = sig( indSig, chanInd);
        xData = ( axProp.xOffset + (0:size(yData, 1)-1) ) / samplingRate;
        
        xLimAx = [axProp.xOffset axProp.xOffset+winSizeInSamples-1] / samplingRate;
        
        cla(ax);
        
        % plot EEG traces
        %------------------------------------------------------------------
%         hold on
        for iCh = 1:nChan
            plot(ax, ...
                xData, ...
                yData(:, nChan-iCh+1) + iCh*ySpacing, ...
                'LineWidth', axProp.LW, ...
                'clipping', 'on');
        end
        
        
        set(ax, ...
            'Ylim', ylim, ...
            'YTick', yticks, ...
            'YTickLabel', ytickLabel, ...
            'Xlim', xLimAx ...
            );
        
        axEventLoc = [];
        if ~isempty(eventLoc)
            axEventLoc = ( eventLoc( eventLoc >= axProp.xOffset+1 & eventLoc <= axProp.xOffset+winSizeInSamples ) - 1 ) / samplingRate;
            if ~isempty(eventType)
                axEventType = eventType( eventLoc >= axProp.xOffset+1 & eventLoc <= axProp.xOffset+winSizeInSamples );
            else
                axEventType = ones(size(axEventLoc));
            end
        end
        
        
        % display events
        %------------------------------------------------------------------
        for iEv = 1:numel(axEventLoc)
            
            if ~isempty(eventType)
                iC = find(unique(eventType) == axEventType(iEv));
            else
                iC = 1;
            end
            
            plot(ax, ...
                [axEventLoc(iEv) axEventLoc(iEv)], ...
                ylim, ...
                'Color', ...
                colorTyp(iC, :), ...
                'linestyle', '-', ...
                'linewidth', 1);
            
        end
               
        % plot scale axis
        %------------------------------------------------------------------        
        cla(scaleAx);
        Xl = [.2 .5; .35 .35; .2 .5];
        Yl = [ ySpacing ySpacing; ySpacing 0; 0 0];
        plot(scaleAx, Xl(1,:),Yl(1,:), 'k'); hold on;
        plot(scaleAx, Xl(2,:),Yl(2,:), 'k');
        plot(scaleAx, Xl(3,:),Yl(3,:), 'k');
        set(scaleAx, 'Xlim', [0 1], 'Ylim', ylim, 'visible', 'off');
        scaleAxXlim = get(scaleAx, 'xlim');
%         scaleTextPos = [ ...
%             (scaleAxXlim(2) - scaleAxXlim(1) ) / 2 ...
%             1.5*ySpacing ...
%             ];
%         scaleTextPos = [ .55 ySpacing ];
        text( ...
            'Parent', scaleAx, ...
            'position', [ .55 0 ], ...
            'VerticalAlignment', 'middle', ...
            'HorizontalAlignment', 'left', ...
            'String', '0' ...
            )
        text( ...
            'Parent', scaleAx, ...
            'position', [ .55 ySpacing ], ...
            'VerticalAlignment', 'middle', ...
            'HorizontalAlignment', 'left', ...
            'String', sprintf('%g', ySpacing) ...
            )
        
        
    end

    %% ====================================================================
    %                         CALLBACK FUNCTION
    function pbCallback(hObject,eventdata)
        
        hStr = get(hObject, 'String');
        
        switch hStr
            case 'channels'
%                 newList = getItFromGUI(chanLabels, num2cell(axProp.showChannel));
%                 axProp.showChannel = logical(cell2mat(newList));
                axProp.showChannel = chanSelectionGUI(chanLabels, axProp.showChannel);
                plotData;
                
            case 'x start'
                prompt          = {'Enter the desired offset:'};
                name            = 'Input for x window offset';
                numlines        = 1;
                defaultanswer   = {num2str(axProp.xOffset/samplingRate)};
                answer          = inputdlg(prompt, name, numlines, defaultanswer);
                newOffset       = str2double(answer) * samplingRate;
                if newOffset < size(sig, 1)
                    axProp.xOffset = max(0, newOffset);
                    plotData;
                end
                
            case 'x window size'
                prompt          = {'Enter the desired window size:'};
                name            = 'Input for x window window size';
                numlines        = 1;
                defaultanswer   = {num2str(axProp.winSizeInSeconds)};
                answer          = inputdlg(prompt, name, numlines, defaultanswer);
                axProp.winSizeInSeconds = str2double(answer);
                plotData;
                
            case 'y zoom -'
%                 axProp.ySpacingFactor = axProp.ySpacingFactor + axProp.yZoomStep;
                axProp.ySpacingFactor = axProp.ySpacingFactor * axProp.yZoomFactor;
                plotData;
                
            case 'y zoom +'    
%                 axProp.ySpacingFactor = max( axProp.ySpacingFactor - axProp.yZoomStep, axProp.yZoomStep );
                axProp.ySpacingFactor = axProp.ySpacingFactor / axProp.yZoomFactor;
                plotData;
                
            case 'scale'
                prompt          = {'Enter the desired scale:'};
                name            = 'Input for y scale';
                numlines        = 1;
                defaultanswer   = {num2str(ySpacing)};
                answer          = inputdlg(prompt, name, numlines, defaultanswer);
                newYspacing     = str2double(answer);
                axProp.ySpacingFactor  = newYspacing/ySpacingUnit;
                plotData;

            case 'slide >>'
                xTicks = get(ax, 'Xtick');
                newStartTick    = xTicks(end-1);
                newOffset       = newStartTick * samplingRate;
                if newOffset < size(sig, 1)
                    axProp.xOffset = newOffset;
                    plotData;
                end
                
            case 'slide <<'
                xTicks = get(ax, 'Xtick');
                newStartTick    = xTicks(2) - (numel(xTicks)-1)*(xTicks(2)-xTicks(1));
                newStartTick    = max(0, newStartTick);
                newOffset       = newStartTick * samplingRate;
                axProp.xOffset  = newOffset;
                plotData;
                
        end
        
    end
end


