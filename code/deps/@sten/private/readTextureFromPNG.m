function texture = readTextureFromPNG( textureImageFilename, textureDesiredSize )
    
    [texture, ~, h ] = readPNG( textureImageFilename, 'none', true );
    texture = permute( texture, ndims( texture ):-1:1 );
    
    % A one-row image needs to have this dimension re-imposed.
    if h == 1,
        texture = reshape( texture, [1 size( texture )] );
    end
    
    if nargin < 2,
        textureDesiredSize = [size( texture, 1 ) size( texture, 2 )];
    end
    if numel( textureDesiredSize ) == 1,
        textureDesiredSize(2) = textureDesiredSize(1);
    end
    
    texture = imresize( texture, textureDesiredSize(1:2) );
    
    if mod( size( texture, 3 ), 2 ) == 1,
        texture(:,:,end+1) = 255;  % add alpha layer
    end

end % of LOADTEXTUREFROMPNG function