classdef biosemiLabelChannel < handle
   
    %----------------------------------------------------------------------------
    properties ( SetAccess = 'protected' )
        currentLabel    = 0;
        iCurrentLabel   = 1;
        listLabels      = [];
        sizeListLabels  = 10000; % default value
        useTriggerCable = false;
        lptAddress
    end % of public-read/protected-write properties section
    
    properties ( Constant )
        allowedParameterList    = { 'sizeListLabels' , 'useTriggerCable' };
        DEFAULT_LIST_VALUES     = -256;
        DEFAULT_MARKER_ID       = 0;
    end % of constant properties section
    

    %----------------------------------------------------------------------------    
    methods
        
        %-----------------------------------------------
        function obj = biosemiLabelChannel( varargin )
            obj.currentLabel = 0;
            parseInputParameters( obj, varargin{:} );
            obj.listLabels   = obj.DEFAULT_LIST_VALUES * ones(2, obj.sizeListLabels);
            if obj.useTriggerCable
                obj.initLptCommunication;
            end
            logThis( 'Biosemi label channel object created' );
        end % of constructor BIOSEMILABELCHANNEL
        
        %-----------------------------------------------
        function markEvent( obj, markerId, timeStamp )
            if nargin < 3,
                timeStamp = GetSecs();
            end
            markers             = sum(unique(markerId));
            obj.currentLabel    = obj.currentLabel + markers;          
            if obj.useTriggerCable
                if obj.currentLabel >= 0 && obj.currentLabel < 256
                    lptwrite(obj.lptAddress, obj.currentLabel);
                else
                    logThis( 'Out of range event values (not sent to lpt port)' );
                end 
            end
            
            obj.listLabels(:,obj.iCurrentLabel) = [ timeStamp ; obj.currentLabel ];
            obj.iCurrentLabel = obj.iCurrentLabel + 1;
        end % of MARKEVENT method

        %-----------------------------------------------
        function labelList = getListLabels( obj )
            labelList = obj.listLabels;
            labelList( : , labelList(2,:) == obj.DEFAULT_LIST_VALUES ) = [];
        end   
        
        %-----------------------------------------------
        function initLptCommunication( obj )
            obj.useTriggerCable = true;
            obj.lptAddress      = getLPTportIOAddress;
            lptwrite(obj.lptAddress, obj.DEFAULT_MARKER_ID);
        end
        
        %-----------------------------------------------
        function parseInputParameters( obj, varargin )
            iArg = 1;
            nParameters = numel( varargin );
            while ( iArg <= nParameters ),
                parameterName = varargin{iArg};
                if (iArg < nParameters),
                    parameterValue = varargin{iArg+1};
                else
                    parameterValue = [];
                end
                iParameter = find( strncmpi( parameterName, obj.allowedParameterList, numel( parameterName ) ) );
                if isempty( iParameter ),
                    error( 'biosemiLabelChannel:parseInputParameters:UnknownParameterName', ...
                        'Unknown parameter name: %s.', parameterName );
                elseif numel( iParameter ) > 1,
                    error( 'biosemiLabelChannel:parseInputParameters:AmbiguousParameterName', ...
                        'Ambiguous parameter name: %s.', parameterName );
                else
                    switch( iParameter ),
                        case 1,  % sizeListLabels
                            if isnumeric( parameterValue ) && isfinite( parameterValue ) && (parameterValue > 0),
                                obj.sizeListLabels = parameterValue;
                            else
                                error('biosemiLabelChannel:parseInputParameters:BadSerialPortName', ...
                                    'Wrong or missing value for serialPortName parameter.');
                            end
                        case 2,  % useTriggerCable
                            if parameterValue == 0 || parameterValue== 1,
                                obj.useTriggerCable = parameterValue;
                            else
                                error('biosemiLabelChannel:parseInputParameters:BadSerialPortName', ...
                                    'Wrong or missing value for serialPortName parameter.');
                            end
                    end % of iParameter switch
                end % of unique acceptable iParameter found branch
                
                if isempty( parameterValue  ),
                    iArg = iArg + 1;
                else
                    iArg = iArg + 2;
                end
                
            end % of parameter loop
        end % of function parseInputParameters
        
        
        
    end % of methods section 
end % of BIOSEMILABELCHANNEL class definition