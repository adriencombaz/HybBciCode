nRepetitions = 100;
pauseBetweenIterations = 0.05;
[LPTportIOaddress LPTportName] = getLPTportIOAddress('LPT1'); % find first existing LPT port
LPTPortStatusIOaddress  = LPTportIOaddress + 1;

assert( ~isempty( LPTportIOaddress ), 'Couldn''t find any LPT port!' );
fprintf( 'Found a parallel port %s with IO address: 0x%04X (%d)\n', LPTportName, LPTportIOaddress, LPTportIOaddress );

% warming up
a = 0;
lptwrite( LPTportIOaddress, a );        % write a (byte) value [a] to LPT port [LPTportIOaddress]
% b = lptread( ioObj );                 % read a (byte) value [b] from LPT port [LPTPortStatusIOaddress]
c = lptread( LPTportIOaddress );        % read a (byte) value [c] from LPT port [LPTportIOaddress]
tStart = GetSecs();
tStart = GetSecs();
WaitSecs( pauseBetweenIterations );


fprintf( 'Collecting data from %d consecutive %s port write/reads.\n', nRepetitions, LPTportName );
durations = zeros( nRepetitions, 1 );
nCorrectResponses = 0;
tStart = GetSecs();
for i = 1:nRepetitions,
    
    a = uint16( rand()*255 );
    t1 = GetSecs();

    lptwrite( LPTportIOaddress, a );         % write a (byte) value [a] to LPT port [LPTportIOaddress]
%     b = IOxx( ioObj, LPTPortStatusIOaddress );  % read a (byte) value [b] from LPT port [LPTPortStatusIOaddress]
    c = lptread( LPTportIOaddress );        % read a (byte) value [c] from LPT port [LPTportIOaddress]

    t2 = GetSecs();
    durations(i) = t2 - t1;
	WaitSecs( pauseBetweenIterations );

    if (a == c),
        nCorrectResponses = nCorrectResponses + 1;
    end
    
end
tEnd = GetSecs();

durations = 1000 * durations;  % seconds -> milliseconds
elapsed = 1000 * (tEnd - tStart);

fprintf( 'Total elapsed time:   %10.4f ms\n', elapsed );
fprintf( 'Mean latency:         %10.6f ms\n', mean( durations ) );
fprintf( 'Median latency:       %10.6f ms\n', median( durations ) );
fprintf( 'Std latency:          %10.6f ms\n', std( durations ) );
fprintf( 'Max observed:         %10.6f ms  [at iteration #%g]\n', max( durations ), find( max( durations ) == durations, 1 ) );
fprintf( 'Correctness:          %7.3f%%\n', 100 * nCorrectResponses / nRepetitions );
    