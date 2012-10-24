function output = getItFromGUI( ctrlLabels, ctrlValues, ctrlVariableNames, prefGroupName, guiTitle, setCallerVariables )
    % function OUTPUT = GETITFROMGUI( CTRLLABELS, CTRLVALUES, CTRLVARIABLENAMES, PREFGROUPNAME )
    % Dynamically generates a GUI to enter parameters and returns the values of these parameters,
    % when user closes the GUI dialog or presses Continue button.
    %
    % INPUT:
    %   CTRLLABELS          - cell array of strings containting the label describing each GUI control element
    %   CTRLVALUES          - cell array of default values for each GUI control element:
    %                           - a string for an editable text,
    %                           - a cell array {'Choice1', ..., 'ChoiceN'} for a popup menu
    %                           - a logical value (true/false) for a checkbox
    %   CTRLVARIABLENAMES   - [optional] cell array of strings containting the variable names corresponding to the GUI control elements
    %   PREFGROUPNAME       - [optional] name of the Matlab preference group (to save the values for the next time)
    %
    % OUTPUT:
    %   OUTPUT          - result data as cell array or an empty matrix if user pressed escape.
    %
    
    assert( nargin>1, 'getItFromGUI:missingArgument', 'You must call function %s with at least one input (ctrlLabels)', mfilename );
    
    nControls = numel( ctrlLabels );
    
    if ~exist( 'ctrlValues', 'var' ) || isempty( ctrlValues ) || ~iscell( ctrlValues ),
        warning( 'getItFromGUI:StrangeControlTypes', 'ctrlValues must be a cell array, resetting to default type (TextEdit)' );
        ctrlValues = cell( 1, nControls );
    end
    
    if numel( ctrlValues ) > nControls,
        warning( 'getItFromGUI:TooManyControlTypes', 'ctrlValues must have no more then ctrlLabels cells' );
        ctrlValues = ctrlValues(1:nControls);
    end
    
    % padd ctrlValues with empty cells (if necessary), which would be treated as default ctrls (TextEdit)
    ctrlValues = [ctrlValues cell( 1, nControls-numel(ctrlValues) )];
    if ~exist( 'setCallerVariables', 'var' ),
        setCallerVariables = exist( 'ctrlVariableNames', 'var' ) && ~isempty( ctrlVariableNames ) && iscellstr( ctrlVariableNames );
    end
    
    if setCallerVariables,
        if numel( ctrlVariableNames ) > nControls,
            warning( 'getItFromGUI:TooManyControlVariables', 'ctrlVariableNames must have no more then ctrlLabels cells' );
            ctrlVariableNames = ctrlVariableNames(1:nControls);
        end
        
        % padd ctrlVariableNames with empty cells (if necessary)
        ctrlVariableNames = [ctrlVariableNames cell( 1, nControls-numel(ctrlVariableNames) )];
    end
    
    if ~exist( 'guiTitle', 'var' ) || isempty( guiTitle ) || ~ischar( guiTitle ),
        guiTitle = 'Input the values, please';
    end
    
    usePrefs = (nargin > 2) && ~isempty( prefGroupName ) && ischar( prefGroupName );
    prefNames = cell( 1, nControls );
    nMaxLabelChar = 0;
    for iC = 1:nControls,
        ctrlLabelText = lower( ctrlLabels{iC} );
        nMaxLabelChar = max( nMaxLabelChar, numel( ctrlLabelText ) );
        %         fprintf( 'ctrlLabelText = "%s" nMaxLabelChar = %g\n', ctrlLabelText, nMaxLabelChar );
        % generate preference name list from labels (by selecting only letters)
        prefNames{iC} = ctrlLabelText( (ctrlLabelText>='a' & ctrlLabelText<='z')|(ctrlLabelText>='0' & ctrlLabelText<='9') );
        while prefNames{iC}(1)<'a', prefNames{iC}(1)=[]; end
    end
    output = cell( 1, nControls );
    
    ctrlHeight          = 20;
    marginV             = 4;
    marginH             = 10;
    charWidth           = 12;%8;
    labelWidth          = nMaxLabelChar*charWidth;
    startButtonHeight   = 40;
    dialogHeight        = marginV + nControls*(ctrlHeight+marginV) + startButtonHeight + marginV;
    dialogWidth         = 3*marginH + 2*labelWidth;
    
    % Layout the GUI
    color = [0.831372549019608 0.815686274509804 0.784313725490196];
    colorEdit = [1 1 1];
    
    % Main Figure
    hDialog = figure( 'Name', guiTitle, ...
        'Color', color, ...
        'NumberTitle', 'off', ...
        'Units', 'pixels', ...
        'Position', [400 300 dialogWidth dialogHeight], ...
        'Menu', 'none', ...
        'Toolbar', 'none', ...
        'Resize', 'off', ...
        'WindowStyle', 'modal', ...
        'Visible', 'off' );
    
    hCtrlList = zeros( 1, nControls );
    for iC = 1:nControls,
        if usePrefs,
            defaultValue = getpref( prefGroupName, prefNames{iC}, ctrlValues{iC} );
        else
            defaultValue = ctrlValues{iC};
        end
        
        ctrlDescription = struct( 'index', iC, 'class', class( ctrlValues{iC} ) );
        
        switch ctrlDescription.class,
            case 'cell', % pop-up menu
                % ctrl's label (static text)
                uicontrol( hDialog, 'Style', 'text', ...
                    'String', [ctrlLabels{iC} ':'], ...
                    'HorizontalAlignment', 'right', ...
                    'BackgroundColor', color, ...
                    'Position', [marginH dialogHeight-iC*(ctrlHeight+marginV) labelWidth ctrlHeight]);
                
                % pop-up menu ctrl
                if iscell( defaultValue ),
                    defaultValue = defaultValue{1};
                end
                if ischar( defaultValue ),
                    defaultValue = find( strcmpi( defaultValue, ctrlValues{iC} ), 1 );
                end
                if isempty( defaultValue ) || defaultValue < 1,
                    defaultValue = 1;
                end
                
                hCtrlList(iC) = uicontrol( hDialog, 'Style', 'popupmenu',...
                    'String', ctrlValues{iC}, ...
                    'Value', defaultValue, ...
                    'BackgroundColor', colorEdit, ...
                    'Position', [2*marginH+labelWidth dialogHeight-iC*(ctrlHeight+marginV) labelWidth ctrlHeight], ...
                    'Callback', {@uiCallback}, ...
                    'UserData', ctrlDescription );
                defaultValue = ctrlValues{iC}{defaultValue};
                
            case {'char', 'double'},
                if isnumeric( defaultValue ),
                    defaultValue = num2str( defaultValue );
                end
                % ctrl's label (static text)
                uicontrol( hDialog, 'Style','text', ...
                    'String', [ctrlLabels{iC} ':'] , ...
                    'HorizontalAlignment', 'right', ...
                    'BackgroundColor', color, ...
                    'Position', [marginH dialogHeight-iC*(ctrlHeight+marginV) labelWidth ctrlHeight]);
                
                % editable text ctrl
                hCtrlList(iC) = uicontrol( hDialog, 'Style','edit',...
                    'String', defaultValue, ...
                    'HorizontalAlignment', 'left', ...
                    'BackgroundColor', colorEdit, ...
                    'Position', [2*marginH+labelWidth dialogHeight-iC*(ctrlHeight+marginV) labelWidth ctrlHeight], ...
                    'Callback', {@uiCallback}, ...
                    'UserData', ctrlDescription );
                
            case 'logical',
                % checkbox
                hCtrlList(iC) = uicontrol( hDialog, 'Style', 'checkbox',...
                    'String', ctrlLabels{iC},...
                    'Value', defaultValue, ...
                    'HorizontalAlignment', 'right', ...
                    'BackgroundColor', color, ...
                    'Position', [round(dialogWidth/2-labelWidth/2) dialogHeight-iC*(ctrlHeight+marginV) labelWidth ctrlHeight],  ...
                    'Callback', {@uiCallback}, ...
                    'UserData', ctrlDescription );
                
            case 'struct',
                % button 
                hCtrlList(iC) = uicontrol( hDialog, 'Style', 'pushbutton',...
                    'String', ctrlLabels{iC},...
                    'HorizontalAlignment', 'center', ...
                    'BackgroundColor', color, ...
                    'Position', [marginH dialogHeight-iC*(ctrlHeight+marginV) 2*labelWidth+marginH ctrlHeight],  ...
                    'Callback', {@uiCallback, defaultValue }, ...
                    'UserData', ctrlDescription );
                
        end % of ctrl class switch
        output{iC} = defaultValue;
        
    end % of loop over ctrls
    
    % ok button
    uicontrol( hDialog, 'Style', 'pushbutton', ...
        'String', 'Continue', ...
        'Position', [marginH marginV 2*labelWidth+marginH startButtonHeight], ...
        'BackgroundColor', color, ...
        'Callback', @continueButtonCallback );
    
    set( findobj( hDialog ), 'KeyPressFcn', @guiKeyPressFunction );
    set( hDialog, 'Visible', 'on' );
    uiwait( hDialog );
    
    % Setup variables
    if setCallerVariables,
        for jC = 1:nControls,
            assignin( 'caller', ctrlVariableNames{jC}, output{jC} );
        end % of loop over GUI control elements
    end
    %---------------------------------------------------------------------------------------------------
    function uiCallback( hObject, ~, subGUIdata )
        ctrlInfo = get( hObject, 'UserData' );
        switch get( hObject, 'Style' ),
            case 'popupmenu',
                items = get( hObject, 'String' );
                output{ctrlInfo.index} = items{get( hObject, 'Value' )};
            case 'edit',
                value = get( hObject, 'String' );
                switch ctrlInfo.class,
                    case {'double'},
                        output{ctrlInfo.index} = str2double( value );
                    otherwise
                        output{ctrlInfo.index} = value;
                end
            case 'checkbox',
                output{ctrlInfo.index} = get( hObject, 'Value' );
            case 'pushbutton',
                iCtrl = [];
                newGUItitle = 'Enter values...';
                if ~isfield( subGUIdata, 'dependsOn' ) || isempty( subGUIdata.dependsOn ),
                    iNewGUIoption = 1;
                else
                    if ischar( subGUIdata.dependsOn ),
                        iCtrl = find( strcmp(  subGUIdata.dependsOn, ctrlLabels ), 1 );
                    end
                    if isnumeric( subGUIdata.dependsOn ) && ( subGUIdata.dependsOn >= 1 ) && ( subGUIdata.dependsOn <= nControls ),
                        iCtrl = round( subGUIdata.dependsOn );
                    end
                    
                    if ~isempty( iCtrl ),
                        iNewGUIoption = get( hCtrlList(iCtrl), 'Value' );
                        optionNamesList = get( hCtrlList(iCtrl), 'String' );
                        newGUItitle = [optionNamesList{iNewGUIoption} '''s setup'];
                    else
                        iNewGUIoption = 1;
                    end
                end
                iNewGUIoption = max( 1, min( numel( subGUIdata.option ), iNewGUIoption ) );
                subGUIdata.output = getItFromGUI( ...
                    subGUIdata.option(iNewGUIoption).labels, ...
                    subGUIdata.option(iNewGUIoption).values, ...
                    subGUIdata.option(iNewGUIoption).varNames, ...
                    subGUIdata.option(iNewGUIoption).prefGroupName, ...
                    newGUItitle, ...
                    false ...
                    );
                output{ctrlInfo.index} = subGUIdata;
        end % of ctrl style switch
        
    end % of UICALLBACK function
    
    %---------------------------------------------------------------
    function continueButtonCallback( ~, ~ )
        ctrlList = findobj( gcbf, 'Style', 'edit', '-or', 'Style', 'popupmenu', '-or', 'Style', 'checkbox' );
        for hObj = ctrlList(:)',
            uiCallback( hObj );
        end
        
        if usePrefs,
            setpref( prefGroupName, prefNames, output );
        end
        uiresume( gcbf );
        close( gcbf );
    end % of STARTBUTTONCALLBACK nested function
    
    %---------------------------------------------------------------
    function guiKeyPressFunction( ~, eventdata, ~ )
        if isstruct( eventdata ),
            key = eventdata.Character;
        else
            key = get( gcbf, 'CurrentCharacter' );
        end
        switch key,
            case 13,
                continueButtonCallback( gcbo, eventdata );
            case 27,
                output = [];
                setCallerVariables = false;
                delete( gcbf );
        end
    end % of GUIKEYPRESSFUNCTION nested function
    %---------------------------------------------------------------
end % of GETITFROMGUI function