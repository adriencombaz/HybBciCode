function img = loadTexture( textureImageFilename, textureSize )

[img , ~, alpha] = imread( textureImageFilename );

if nargin<2,
    textureSize = [size( img, 1 ) size( img, 2 )];
end

img = imresize( img, [textureSize(1) textureSize(end)] );
if ~isempty( alpha ),
    img(:,:,end+1) = imresize( alpha, [textureSize(1) textureSize(end)] );
else
    img(:,:,end+1) = 255;
end
end % of nested function LOADTEXTURE
