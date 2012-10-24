function outImage = resizeImage( inImage, newImageSize )

    nLayers = size( inImage, 3 );
    
    outImage = zeros( newImageSize(1), newImageSize(2), nLayers );
    outXrange = linspace( 1, size( inImage, 2 ), newImageSize(2) );
    outYrange = linspace( 1, size( inImage, 1 ), newImageSize(1) );
    
    for iLayer = 1:nLayers,
        outImage(:,:,iLayer) = interp2( double( inImage(:,:,iLayer) ), outYrange, outYrange );
    end
    
    outImage = cast( outImage, class(inImage) );
    
end % of function RESIZEIMAGE


% %----------------------------------------------------------------
% function b = resize2DImage(A,m,method,h)
%     % Inputs:
%     %         A       Input Image
%     %         m       resizing factor or 1-by-2 size vector
%     %         method  'nearest','bilinear', or 'bicubic'
%     %         h       the anti-aliasing filter to use.
%     %                 if h is zero, don't filter
%     %                 if h is an integer, design and use a filter of size h
%     %                 if h is empty, use default filter
%     
%     if numel( m ) == 1,
%         bsize = floor(m*size(A));
%     else
%         bsize = m;
%     end
%     
%     if any(size(bsize)~=[1 2]),
%         error('M must be either a scalar multiplier or a 1-by-2 size vector.');
%     end
%     
%     % values in bsize must be at least 1.
%     bsize = max(bsize, 1);
%     
%     if (any((bsize < 4) & (bsize < size(A))) & ~strcmp(method, 'nea'))
%         fprintf('Input is too small for bilinear or bicubic method;\n');
%         fprintf('using nearest-neighbor method instead.\n');
%         method = 'nea';
%     end
%     
%     if isempty(h),
%         nn = 11; % Default filter size
%     else
%         if numel( h ) == 1,
%             nn = h;
%             h = [];
%         else
%             nn = 0;
%         end
%     end
%     
%     [m,n] = size(A);
%     
%     if nn>0 & method(1)=='b',  % Design anti-aliasing filter if necessary
%         if bsize(1)>1 || length(h2)>1,
%             h = h1'*h2;
%         else
%             h = [];
%         end
%         if length(h1)>1 || length(h2)>1,
%             a = filter2(h1',filter2(h2,A));
%         else
%             a = A;
%         end
%     elseif method(1)=='b' && (prod(size(h)) > 1),
%         a = filter2( h, A );
%     else
%         a = A;
%     end
%     
%     
%     uu = 1:(n-1)/(bsize(2)-1):n; vv = 1:(m-1)/(bsize(1)-1):m;
%     %
%     % Interpolate in blocks
%     %
%     nu = length(uu); nv = length(vv);
%     blk = bestblk([nv nu]);
%     nblks = floor([nv nu]./blk);
%     nrem = [nv nu] - nblks.*blk;
%     mblocks = nblks(1);
%     nblocks = nblks(2);
%     mb = blk(1);
%     nb = blk(2);
%     
%     rows = 1:blk(1); b = zeros(nv,nu);
%     for i=0:mblocks,
%         if i==mblocks,
%             rows = (1:nrem(1));
%         end
%         for j=0:nblocks,
%             if j==0,
%                 cols = 1:blk(2);
%             elseif j==nblocks,
%                 cols=(1:nrem(2));
%             end
%             if ~isempty(rows) && ~isempty(cols),
%                 [u,v] = meshgrid(uu(j*nb+cols),vv(i*mb+rows));
%                 b(i*mb+rows,j*nb+cols) = interp2(a,u,v,'*linear');
%             end
%         end
%     end
%     
%     end % of function RESIZE2DIMAGE
% 
