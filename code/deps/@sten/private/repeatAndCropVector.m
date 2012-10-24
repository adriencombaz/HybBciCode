function u = repeatAndCropVector( v, desiredSize )
    u = repmat( v(:)', [1 ceil( desiredSize/numel( v ) )] );    % repeat vector v as many times as necessary
    u = u(1:desiredSize);                                       % crop vector u to have the desiredSize
end