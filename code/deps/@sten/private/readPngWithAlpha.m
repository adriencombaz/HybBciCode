function X = readPngWithAlpha(filename, varargin)

    [X, ~, h ] = pngreadc( filename, [], false );
    
    X = permute( X, ndims( X ):-1:1 );

    % A one-row image needs to have this dimension re-imposed.
    if h == 1,
        X = reshape( X, [1 size( X )] );
    end

end % of READPNGWITHALPHA function