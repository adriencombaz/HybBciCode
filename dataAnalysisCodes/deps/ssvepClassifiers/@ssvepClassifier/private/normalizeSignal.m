function normalizedA = normalizeSignal( A )
    normalizedA = bsxfun( @minus, A, mean( A, 2 ) );
    for iRow = 1:size( A, 1 )
        normalizedA(iRow,:) = A(iRow,:) - mean( A(iRow,:), 2 );
        stdOfRow = std( normalizedA(iRow,:) );
        if( stdOfRow < 1e-16 ),
            warning( 'Possible matrix normalizaion problem...' );
        end
        normalizedA(iRow,:) = normalizedA(iRow,:) / stdOfRow;
    end % loop over rows of matrix A
end % of normalizeSignal function
