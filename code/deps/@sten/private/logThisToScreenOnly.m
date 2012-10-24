function logThisToScreenOnly( msg, varargin )
    fprintf( '[%04g-%02g-%02g-%02g-%02g-%06.3f]', clock() );
    fprintf( [' ' msg '\n'], varargin{:} );
end % of method LOGTHISTOSCREENONLY