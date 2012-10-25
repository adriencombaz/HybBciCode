function logThis( msg, varargin )
% function LOGTHIS( MSG, ... )
% Simple logger for matlab.
%
% INPUT:
%   MSG   - message or format string (as in fprintf/sprintf)
%           followed by a list of arguments.
%           if MSG is not a string, then the following arguments
%           are treated as configuration commands. 
% 
% List of configuration commands:
%   logFilename, logToFile, logToScreen, logCallerInfo,
%   logTimestamps, timestampFormatStr and callerInfoFmtStr.
% 
% * 'logFilename' should be followed by a string containing a filename of
%   a (new) log-file. If the filename is empty, the logging to file is 
%   switched off.
%
% * 'logToFile' should be followed by a flag (any value convertable to logical type,
%   or one of the next strings 'on', 'yes', 'off', 'no', where: 'on' <=> 'yes' <=> true
%   and 'off' <=> 'no' <=> false) enabling/disabling logging to file.
% 
% * 'logToScreen' should be followed by a flag enabling/disabling logging to screen.
% 
% * 'logCallerInfo' should be followed by a flag enabling/disabling logging of the
%   caller information (name of the caller function and the line number of the call).
% 
% * 'logTimestamps' should be followed by a flag enabling/disabling logging of the
%   timestamps.
% 
% * 'timestampFormatStr ' should be followed by a format string to be used for logging
%   of the timestamps.
% 
% * 'callerInfoFmtStr ' should be followed by a format string to be used for logging
%   of the caller information.
% 
% EXAMPLES:
%   logThis( 'A simple line in the log.' ); % adds the line to the log
%   logThis( '2 + 2 = %02d', 2+2 );         % adds '2 + 2 = 04' to the log
%   logThis( '%s %s!', 'Hello', 'World' );  % adds 'Hello World!' to the log
% 
%   logThis( [], 'logFilename', 'new-log.txt' );    % sets up the log-file
% 
%   logThis( [], ...
%       'callerInfoFmtStr',   '%15s:%-4d ', ...
%       'timestampFormatStr', '%4d-%02d-%02d %02d:%02d:%06.3f ' );
%   changes the caller info format string to '%30s:%-4d ', which means the name
%   of the caller-function (no more than 15 characters in this case) followed by
%   the line number. An example of the log line, generated uding logThis( 'Hello!' )
%   and the looger is configured as is shown above:
% 2012-01-20 23:31:12.656    testLogThis@68   Hello
% 
%   logThis( [], 'logTimestamps', 'yes' ); % enables timestamps in the log.
% 
%   logThis( [], 'logCallerInfo', true ); % enables caller-info in the log.
% 
%
% Developed by Nikolay Chumerin
% http://sites.google.com/site/chumerin
%
    persistent firstCall logToFile logToScreen logFilename logCaller logTimestamps allowedParameterList ...
        timestampFormatStr callerInfoFmtStr callerFcnNameMaxLength
    
    if isempty( firstCall ) || firstCall,
        logToFile               = true;
        logToScreen             = true;
        logFilename             = 'log.txt';
        logCaller               = true;
        logTimestamps           = true;
        firstCall               = false;
        timestampFormatStr      = '[%04g-%02g-%02g-%02g-%02g-%06.3f] ';
        callerFcnNameMaxLength  = 34;
        callerInfoFmtStr        = sprintf( '[%%-%ds@%%5d] ', callerFcnNameMaxLength );
        allowedParameterList    = { 'logFilename'
                                    'logToFile'
                                    'logToScreen'
                                    'logCallerInfo'
                                    'logTimestamps'
                                    'timestampFormatStr'
                                    'callerInfoFmtStr' };
    end
    
    if ischar( msg ),
        %% Regular (non-setup) call
        timestampStr = '';
        if logTimestamps,
            timestampStr = sprintf( timestampFormatStr, clock() );
        end
        
        callerInfoStr = '';
        if logCaller,
            callerInfo = dbstack();
            if numel( callerInfo ) > 1,
                callerFcnName = callerInfo(2).name;
                if numel( callerFcnName ) > callerFcnNameMaxLength,
                    callerFcnName = ['<' callerFcnName(end-callerFcnNameMaxLength+2:end) ];
                end
                callerInfoStr = sprintf( callerInfoFmtStr, callerFcnName, callerInfo(2).line );
            end
        end
        
        logLine = [timestampStr callerInfoStr sprintf( msg, varargin{:} ) sprintf('\n')];
        
        if logToFile,
            logFile = fopen( logFilename, 'A' );
            fwrite( logFile, logLine );
            fclose( logFile );
        end
        
        if logToScreen,
            fwrite( 1, logLine );
        end

    else
        %% Setup call
        % parse parameters
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
                error( 'logThis:parseInputParameters:UnknownParameterName', ...
                    'logThis: Unknown parameter name: "%s"', parameterName );
            elseif numel( iParameter ) > 1,
                error( 'logThis:parseInputParameters:AmbiguousParameterName', ...
                    'logThis: Ambiguous parameter name: "%s"', parameterName );
            else
                switch( iParameter ),
                    case 1,  % filename
                        if ischar( parameterValue ),
                            logFilename = parameterValue;
                            logToFile   = ~isempty( logFilename );
                        else
                            error( 'logThis:parseInputParameters:BadFilename', ...
                                'logThis: Wrong or missing value for log filename.');
                        end
                        
                    case 2, % logToFile
                        if isempty( parameterValue )
                            logToFile = true;
                        else
                            if islogical( parameterValue ),
                                logToFile = parameterValue;
                            elseif isnumeric( parameterValue ),
                                logToFile = logical( parameterValue(1) );
                            elseif ischar( parameterValue ),
                                switch lower( parameterValue ),
                                    case {'on', 'yes'},
                                        logToFile = true;
                                    case {'off', 'no'},
                                        logToFile = false;                                       
                                end % of switch                                
                            else
                                error( 'logThis:parseInputParameters:BadLogToFile', ...
                                    'logThis: Wrong value for logToFile flag.' );
                            end                            
                        end % of ~isempty branch

                    case 3, % logToScreen
                        if isempty( parameterValue )
                            logToScreen = true;
                        else
                            if islogical( parameterValue ),
                                logToScreen = parameterValue;
                            elseif isnumeric( parameterValue ),
                                logToScreen = logical( parameterValue(1) );
                            elseif ischar( parameterValue ),
                                switch lower( parameterValue ),
                                    case {'on', 'yes'},
                                        logToScreen = true;
                                    case {'off', 'no'},
                                       logToScreen = false;                                       
                                end % of switch                                
                            else
                                error( 'logThis:parseInputParameters:BadLogToScreen', ...
                                    'logThis: Wrong value for logToScreen flag.' );
                            end
                        end % of ~isempty branch
                        
                    case 4, % logCaller
                        if isempty( parameterValue )
                            logCaller = true;
                        else
                            if islogical( parameterValue ),
                                logCaller = parameterValue;
                            elseif isnumeric( parameterValue ),
                                logCaller = logical( parameterValue(1) );
                            elseif ischar( parameterValue ),
                                switch lower( parameterValue ),
                                    case {'on', 'yes'},
                                        logCaller = true;
                                    case {'off', 'no'},
                                       logCaller = false;                                       
                                end % of switch                                
                            else
                                error( 'logThis:parseInputParameters:BadLogCaller', ...
                                    'logThis: Wrong value for logCaller flag.' );
                            end
                        end % of ~isempty branch

                    case 5, % logTimestamps
                        if isempty( parameterValue )
                            logTimestamps = true;
                        else
                            if isnumeric( parameterValue ),
                                logTimestamps = logical( parameterValue(1) );
                            elseif ischar( parameterValue ),
                                switch lower( parameterValue ),
                                    case {'on', 'yes'},
                                        logTimestamps = true;
                                    case {'off', 'no'},
                                       logTimestamps = false;                                       
                                end % of switch                                
                            else
                                error( 'logThis:parseInputParameters:BadLogTimestamps', ...
                                    'logThis: Wrong value for logTimestamps flag.' );
                            end
                        end % of ~isempty branch
                        
                    case 6, % timestampFormatStr
                        if ischar( parameterValue ) && ~isempty( parameterValue ),
                            timestampFormatStr = parameterValue;
                        else
                            error( 'logThis:parseInputParameters:BadTimestampFormatStr', ...
                                'logThis: Wrong value or missing for timestampFormatStr.' );
                        end % of timestampFormatStr check
                        
                    case 7, % callerInfoFmtStr
                        if ischar( parameterValue ) && ~isempty( parameterValue ),
                            callerInfoFmtStr = parameterValue;
                            
                            width = regexp( callerInfoFmtStr, '%-?(\d+)s', 'tokens' );
                            if numel( width ) > 0,
                                callerFcnNameMaxLength = str2double( width{1} );
                            else
                                callerFcnNameMaxLength = 34;
                            end
                        else
                            error( 'logThis:parseInputParameters:BadCallerInfoFmtStr', ...
                                'logThis: Wrong value or missing for callerInfoFmtStr.' );
                        end % of callerInfoFmtStr check

                end % of iParameter switch
            end % of unique acceptable iParameter found branch
        
            iArg = iArg + 2;
            
        end % of parameter loop

    end  % of control sequence detected branch

end % of function LOGTHIS