function plotERPsFromCutData2(avg, varargin)

%% ============================================================================================
%                               LIST OF INPUT ARGUMENTS
%
%   MANDATORY ARUGMENTS:
%   avg     : cell array containing nTimeSteps-by-nChannels numerical arrays representing ERPs
%
%   OPTIONAL ARGUMENTS:
%   samplingRate    : sampling rate of the signal (default = 1)
%   chanLabels      : cell of strings contaning the name of each EEG channel
%                       (default: the number of the channel)
%   timeBeforeOnset : time to plot before stimuli onset in seconds (default 0.2s)
%   title           : title of the figure (default: ERP Explorer)
%   nMaxChanPerAx   : Max number of channels to plot per axis, if this number is smaller
%                       than the number of channels to plot, as many additional axes as
%                       as necessary are added.
%                       (default: total number of channels of the input signal)
%   axisOfEvent    : Array with as many elements as there are types of event, each element contains 
%                       the index of the axis on which to draw the corresponding ERP.
%                       (e.g. axisOfEvent = [1 2 1 1 2 3], draw ERPs corresponding to
%                       events 1, 3 and 4 (as indexed in eventType) on axis 1, ERPs for
%                       events 2 and 5 on axis 3 and ERPs for event 6 on axis 3)
%                       (default: 1:numel(eventType) ).
%   axisTitles      :
%   legendStr       :
%   EventColors     : nEvents-by-3 array. Each line contains the RGB code of the color to be
%                       used for the corresponding event
%
% ==============================================================================================

if ~iscell(avg)
    avg = {avg};
end

nChan = unique( cellfun(@(x) size(x, 2), avg) );
if numel(nChan) > 1
    error('all epoch should have the same number of channels');
end


%% ========================================================================
%                        PARSE INPUT ARGUMENTS

colorList = [ ...    
    0 0 1 ; ... % blue
    1 0 0 ; ... % red
    0 1 0 ; ... % green
    0 0 0 ...   % black
    ];

allowedParameterList = {'samplingRate', 'chanLabels', 'timeBeforeOnset', 'title', 'nMaxChanPerAx', 'axisOfEvent', 'axisTitles', 'legendStr', 'EventColors', 'scale'};
samplingRate    = 1;
chanLabels      = cellstr( int2str( (1:nChan)' ) );
axisTitles      = {};
legendStr       = {};
tl              = 0;
mfigTitle       = 'ERP Explorer';
nMaxChanPerAx   = nChan;
axisOfEvent     = [];
colorOfEvent    = [];
ySpacing        = 0; % intialize it to be able to share it among functions

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
        error( 'plotERPs:UnknownParameterName', ...
            'Unknown parameter name: %s.', parameterName );
    elseif numel( iParameter ) > 1,
        error( 'plotERPs:AmbiguousParameterName', ...
            'Ambiguous parameter name: %s.', parameterName );
    else
        switch( iParameter ),
            case 1,  % SamplingRate
                if isnumeric( parameterValue ) && numel( parameterValue ) == 1,
                    samplingRate = parameterValue;
                else
                    error('plotERPs:BadSamplingRate', ...
                        'Wrong sampling rate input.');
                end
            case 2,  % chanLabels
                if iscellstr( parameterValue ) && numel( parameterValue ) == nChan,
                    chanLabels = parameterValue;
                else
                    error('plotERPs:chanLabels', ...
                        'Wrong channels labels input.');
                end
            case 3, %timeBeforeOnset
                if isnumeric( parameterValue ) && numel( parameterValue ) == 1,
                    tl = parameterValue;
                else
                    error('plotERPs:eventLabel', ...
                        'Wrong tl input.');
                end
            case 4, %title
                if ischar( parameterValue ),
                    mfigTitle = parameterValue;
                else
                    error('plotERPs:eventLabel', ...
                        'Wrong th input.');
                end
            case 5, %nMaxChanPerAx
                if isnumeric( parameterValue ) && numel( parameterValue ) == 1,
                    nMaxChanPerAx = parameterValue;
                else
                    error('plotERPs:eventLabel', ...
                        'Wrong nMaxChanPerAx input.');
                end
            case 6, %axisOfEvent
                if isnumeric( parameterValue ) ...
                        && sum(size( parameterValue )) == numel( parameterValue ) + 1,
                    axisOfEvent = parameterValue;
                else
                    error('plotERPs:axisOfEvent', ...
                        'Wrong axisOfEvent array.');
                end
            case 7, %axisTitles
                if iscellstr( parameterValue ) ...
                        && sum(size( parameterValue )) == numel( parameterValue ) + 1,
                    axisTitles = parameterValue;
                else
                    error('plotERPs:axisTitles', ...
                        'Wrong axisOfEvent array.');
                end
            case 8, %legendStr
                if iscellstr( parameterValue ) ...
                        && sum(size( parameterValue )) == numel( parameterValue ) + 1,
                    legendStr = parameterValue;
                else
                    error('plotERPs:axisOfEvent', ...
                        'Wrong legendStr array.');
                end
            case 9, %colorOfEvent
                if isnumeric( parameterValue ) ...
                        && size( parameterValue, 2 ) == 3 ...
                        && min( parameterValue(:) ) >= 0 ...
                        && max( parameterValue(:) ) <= 1,
                    colorOfEvent = parameterValue;
                else
                    error('plotERPs:colorList', ...
                        'Wrong colorList array.');
                end
            case 10, %scale
                if isnumeric( parameterValue ) && numel( parameterValue ) == 1,
                    ySpacing = parameterValue;
                else
                    error('plotERPs:eventLabel', ...
                        'Wrong ySpacing input.');
                end
                
        end % of iParameter switch
    end % of unique acceptable iParameter found branch
    
    if isempty( parameterValue  ),
        iArg = iArg + 1;
    else
        iArg = iArg + 2;
    end
    
end % of parameter loop


nEventType = numel(avg);
if isempty(axisOfEvent)
    axisOfEvent = 1:nEventType;
end

if nEventType ~= numel(axisOfEvent)
    error('the amount of event codes and axis of event do not match');
end

if ~isequal( unique(axisOfEvent), 1:max(axisOfEvent) )
    error('wrong axisOfEvent');
end

range = unique( cellfun(@(x) size(x, 1), avg) );
if numel(range) > 1
    error('all epoch should have the same size in samples');
end

if isempty( colorOfEvent )
    colorOfEvent = zeros(nEventType, 3);
    axisList = unique(axisOfEvent);
    for i = axisList
        eventsOnAx = find(axisOfEvent == i);
        for j = 1:numel(eventsOnAx)
            colorOfEvent(eventsOnAx(j), :) = colorList(j, :);
        end
    end
elseif size( colorOfEvent, 1) ~= nEventType
    error('there is not exaclty one color per event');
end

nEventAx    = max(axisOfEvent);
nAxPerEvent = ceil(nChan / nMaxChanPerAx);

nl      = round(tl*samplingRate);
nh      = range - nl - 1;
th      = nh/samplingRate;

%% ========================================================================
%                           LAYOUT THE GUI

%--------------------------------------------------------------------------
% parameters for the gui layout
scrSize = get(0, 'ScreenSize');
nScrCols = scrSize(3);
nScrRows = scrSize(4);

pbLabelList = {'channels', 'y zoom +', 'y zoom -', 'scale', 'fft'};
nPb                 = numel(pbLabelList);
FS                  = 12; % font size
LW                  = 2;
maxCharPB           = max(cellfun(@numel, pbLabelList));
xPbsSizeInPoints    = (maxCharPB+2)*FS;
yPbsSizeInPoints    = 2*FS;
rightMarginInPoints = 2*FS;
leftMarginInPoints  = 4*FS;
spaceBetweenAxesInPoints = 3*FS;
topMarginInPoints   = 2*FS;
bottomMarginInPoints= 2*FS;

%--------------------------------------------------------------------------
% default parameters for the display in axes
showChannel     = true(1, numel(chanLabels));  % plot all channels by default
ySpacingFactor  = 4;
yZoomFactor     = 2;
ySpacingUnit    = 0; % intialize it to be able to share it among functions

if ySpacing ~= 0
    dum = cellfun(@(x) max(std(x, [], 1)), avg);
    dum = max(dum);
    ySpacingFactor = ySpacing / dum;
end
%--------------------------------------------------------------------------
% Lay out the main figure
mfig = figure( ...
    'Name', mfigTitle, ...
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

nTotalAxis = nEventAx*nAxPerEvent;
axLengthInPoints = ( mfigPos(3) ...
    - leftMarginInPoints ...
    - nTotalAxis*spaceBetweenAxesInPoints ...
    - xPbsSizeInPoints ...
    -rightMarginInPoints ) / nTotalAxis;

for i1 = 1:nEventAx
    for i2 = 1:nAxPerEvent
        
        iAx = (i1-1)*nAxPerEvent + i2;
        axPos = [ ...
            leftMarginInPoints + (iAx-1)*(spaceBetweenAxesInPoints + axLengthInPoints) ...
            bottomMarginInPoints ...
            axLengthInPoints ...
            mfigPos(4) - bottomMarginInPoints - topMarginInPoints ...
            ];
        
        ax(i1, i2) = axes( ...
            'Parent', mfig, ...
            'Box', 'off', ...
            'xgrid', 'off', 'ygrid', 'off', ...
            'Units', 'points', ...
            'position', axPos ...
            );
%         title( eventLabel{i1} );
        
        hold(ax(i1, i2));
        
    end
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

plotData;


    %% ====================================================================
    %                         NESTED FUNCTION
    
    
    function plotData
        
        for iEa = 1:nEventAx
            for iAe = 1:nAxPerEvent
                cla(ax(iEa, iAe));
            end
        end
        delete(findobj(mfig, 'tag', 'legend'));
        
        chanInd             = find(showChannel);
        nChansToShow        = numel(chanInd);
        nChanPerAx          = min(nChansToShow, nMaxChanPerAx);
        currentChanList     = chanLabels(chanInd);

        stdmax              = cellfun(@(x) max(std(x, [], 1)), avg);
        ySpacingUnit        = max(stdmax);
        ySpacing            = ySpacingFactor*ySpacingUnit;
        ylim                = [0 (nChanPerAx+1)*ySpacing];
        
        nAxToShowPerEvent   = ceil(nChansToShow / nMaxChanPerAx);
        nAxisToShow         = nEventAx*nAxToShowPerEvent;
        axLengthInPoints    = ( mfigPos(3) ...
            - leftMarginInPoints ...
            - nAxisToShow*spaceBetweenAxesInPoints ...
            - xPbsSizeInPoints ...
            -rightMarginInPoints ) / nAxisToShow;
        
        
        for iEvC = 1:nEventType
            
            for iApE = 1:nAxToShowPerEvent
                
                iAxOfEvent = axisOfEvent(iEvC);
                                
                iAx = (iAxOfEvent-1)*nAxToShowPerEvent + iApE;
                axPos = [ ...
                    leftMarginInPoints + (iAx-1)*(spaceBetweenAxesInPoints + axLengthInPoints) ...
                    bottomMarginInPoints ...
                    axLengthInPoints ...
                    mfigPos(4) - bottomMarginInPoints - topMarginInPoints ...
                    ];
                
                set( ax(iAxOfEvent, iApE), 'visible', 'on', 'position', axPos);
                firstChan   = (iApE-1)*nMaxChanPerAx + 1;
                lastChan    = min(iApE*nMaxChanPerAx, nChansToShow);
                yData       = avg{iEvC}(:, chanInd(firstChan:lastChan));
                yticks      = ySpacing * ( nChanPerAx-size(yData, 2)+1 : nChanPerAx );
                ytickLabel  = currentChanList(lastChan:-1:firstChan);
            
                % plot EEG traces
                for iCh = 1:size(yData, 2)
                    
                    trace = plot(ax(iAxOfEvent, iApE), ...
                        (-nl:nh)/samplingRate, ...
                        yData(:, iCh) + (nChanPerAx-iCh+1)*ySpacing, ...
                        'Color', colorOfEvent(iEvC, :), ...
                        'LineWidth', LW, ...
                        'clipping', 'on');
                    
                    zeroLine = plot(ax(iAxOfEvent, iApE), ...
                        [-tl th], ...
                        [(nChanPerAx-iCh+1)*ySpacing (nChanPerAx-iCh+1)*ySpacing], ...
                        'Color', [0 0 0], ...
                        'linestyle', '-', ...
                        'linewidth', LW/2 ...
                        );
                    
                    set( get(get(zeroLine, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off' ); % Exclude line from legend
                    if iCh ~= 1
                        set( get(get(trace, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off' ); % Exclude line from legend
                    end
                    
                end
                set( ax(iAxOfEvent, iApE), ...
                    'Xlim', [-tl th], ...
                    'Ylim', ylim, ...
                    'YTick', yticks, ...
                    'YTickLabel', [] ...
                    );
                if iAxOfEvent == 1
                    set( ax(iAxOfEvent, iApE), 'YTickLabel', ytickLabel );
                end
                
                % plot ERP onset (vertical line)
                onsetLine = plot(ax(iAxOfEvent, iApE), ...
                    [0 0], ...
                    ylim, ...
                    'Color', [0 0 0], ...
                    'linestyle', '-', ...
                    'linewidth', LW/2 ...
                    );
                set( get(get(onsetLine, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off' ); % Exclude line from legend
            
            end
            for iApE = nAxToShowPerEvent+1:nAxPerEvent
                cla(ax(iAxOfEvent, iApE));
                set( ax(iAxOfEvent, iApE), 'visible', 'off');
            end
        end
        
        cla(scaleAx);
        Xl = [.2 .5; .35 .35; .2 .5];
        Yl = [ ySpacing ySpacing; ySpacing 0; 0 0];
        plot(scaleAx, Xl(1,:),Yl(1,:), 'k'); hold on;
        plot(scaleAx, Xl(2,:),Yl(2,:), 'k');
        plot(scaleAx, Xl(3,:),Yl(3,:), 'k');
        set(scaleAx, 'Xlim', [0 1], 'Ylim', ylim, 'visible', 'off');
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
                
        for iEa = 1:nEventAx
            if ~isempty( axisTitles )
                title(ax(iEa, 1), axisTitles{iEa});
            end
        end
        if ~isempty( legendStr )
            hl = legend(ax(1, nAxToShowPerEvent), legendStr, 'location', 'best');
        end

        
    end


    %% ====================================================================
    %                         CALLBACK FUNCTION
    function pbCallback(hObject,eventdata)
        
        hStr = get(hObject, 'String');
        
        switch hStr
            case 'channels'
%                 newList = getItFromGUI(chanLabels, num2cell(showChannel));
%                 showChannel = logical(cell2mat(newList));
                showChannel = chanSelectionGUI(chanLabels, showChannel);
                plotData;

            case 'y zoom -'
%                 axProp.ySpacingFactor = axProp.ySpacingFactor + axProp.yZoomStep;
                ySpacingFactor = ySpacingFactor * yZoomFactor;
                plotData;
                
            case 'y zoom +'    
%                 axProp.ySpacingFactor = max( axProp.ySpacingFactor - axProp.yZoomStep, axProp.yZoomStep );
                ySpacingFactor = ySpacingFactor / yZoomFactor;
                plotData;
                
            case 'scale'
                prompt          = {'Enter the desired scale:'};
                name            = 'Input for y scale';
                numlines        = 1;
                defaultanswer   = {num2str(ySpacing)};
                answer          = inputdlg(prompt, name, numlines, defaultanswer);
                newYspacing     = str2double(answer);
                ySpacingFactor  = newYspacing/ySpacingUnit;
                plotData;
                
            case 'fft'
                minFreq = 1;
                maxFreq = 35;
                L = nl+nh+1;
                NFFT = 2^nextpow2(L);
                f = samplingRate/2*linspace(0,1,NFFT/2+1);
                fplot = f(f>=minFreq & f<=maxFreq);
                
                temp = cellfun(@(x) x(:, showChannel), avg, 'UniformOutput', false);
                ampSpec = cell(size(temp));
                for iData = 1:numel(temp)
                    ampSpec{iData} = zeros( numel(fplot), size(temp{iData}, 2) );
                    for iChan = 1:size(temp{iData}, 2)
                        Y = fft(temp{iData}(:,iChan),NFFT)/L;
                        Y = 2*abs(Y(1:NFFT/2+1));
                        ampSpec{iData}(:,iChan) = Y(f>=minFreq & f<=maxFreq)';
                    end
                end
%                 ampSpec = cellfun(@(x) fft(x,NFFT)/L, ampSpec, 'UniformOutput', false);
%                 ampSpec = cellfun(@(x) 2*abs(x(1:NFFT/2+1)), ampSpec, 'UniformOutput', false);
%                 ampSpec = cellfun(@(x) x(f>=minFreq & f<=maxFreq, :), ampSpec, 'UniformOutput', false);

                if isempty(axisTitles),
                    axisTitlesFft = {'fft'};
                else
                    axisTitlesFft = cellfun( @(x) sprintf('fft %s', x), axisTitles, 'UniformOutput', false );
                end
                plotFfts2( ...
                    fplot, ...
                    ampSpec, ...
                    'chanLabels', chanLabels(showChannel), ...
                    'title', mfigTitle, ...
                    'nMaxChanPerAx', nMaxChanPerAx, ...
                    'axisOfEvent', axisOfEvent, ...
                    'axisTitles', axisTitlesFft, ...
                    'legendStr',  legendStr, ...
                    'LW', 2, ...
                    'scale', 2 ...
                    );


        end
    end

end