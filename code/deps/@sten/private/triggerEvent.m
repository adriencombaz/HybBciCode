function triggerEvent( eventsList, timestamp )
    persistent prevTimestamp
    if isempty( prevTimestamp ),
        prevTimestamp = timestamp;
    end
    
    fprintf( '        timestamp: %10.3f    dt:%8.3f ms    event-ID(s): %s\n', ...
        timestamp, 1000*(timestamp-prevTimestamp), sprintf( '%g ', eventsList ) );
    
    prevTimestamp = timestamp;
    
end % of function TRIGGEREVENT