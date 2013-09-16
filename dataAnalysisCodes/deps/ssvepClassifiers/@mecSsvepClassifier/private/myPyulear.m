function Pxx = myPyulear( x, order, nFFT )
%   PYULEAR Power Spectral Density (PSD) estimate via Yule-Walker's method.
%   Pxx = PYULEAR( X, ORDER ) returns the PSD of a discrete-time signal vector
%   X in the vector Pxx.  Pxx is the distribution of power per unit frequency.
%   The frequency is expressed in units of radians/sample.  ORDER is the
%   order of the autoregressive (AR) model used to produce the PSD.  PYULEAR
%   uses a default FFT length of 256 which determines the length of Pxx.
%
%   For real signals, PYULEAR returns the one-sided PSD by default; for
%   complex signals, it returns the two-sided PSD.  Note that a one-sided
%   PSD contains the total power of the input signal.
%
%   Pxx = PYULEAR(X,ORDER,NFFT) specifies the FFT length used to calculate
%   the PSD estimates.  For real X, Pxx has length (NFFT/2+1) if NFFT is
%   even, and (NFFT+1)/2 if NFFT is odd.  For complex X, Pxx always has
%   length NFFT.  If empty, the default NFFT is 256.
%

    % inlining the line:  R = biasedXcorrVec( x, order ); --------------------
    M = numel( x );
    x = x(:);

    if( order > M ),
        order = M;
    end
    
    % Compute correlation via FFT
    X = fft( x, 2^nextpow2( 2*M - 1 ) );
    R = real( ifft( abs( X ).^2 ) );
    R = R(1:order+1,:) / M;
    %--------------------------------
    % inlining the line:  R = biasedXcorrVec( x, order ); --------------------
%     R = zeros( order, 1 );
%     xx = [x; x(1:order)]';
%     for i = 1:order+1,
%         R(i) = xx(i:i+M-1)*x;
%     end
%     R = R / M;
    %--------------------------------
    [a, v] = myLevinson( R, order );    
    
    % inlining the line h = myFreqz( a, nFFT ); --------
    na = order + 1;
    if( nFFT < na ),
        % Data is larger than FFT points, wrap modulo nfft
        % inlining the line a = myDatawrap( a, nFFT ); ---------
        nValuesToPad = mod( numel( a ), nFFT );
        if( nValuesToPad > 0 ),
            a = [a zeros( 1, nValuesToPad) ];
        end
        a = sum( reshape( a, nFFT, [] ), 2 )';
    end
    h = ( ones( 1, nFFT ) ./ fft( a, nFFT ) )';
    %-------------
    
    Sxx = v * abs( h ).^2; % This is the power spectrum [Power] (input variance*power of AR model)
    
    % Compute the 1-sided or 2-sided PSD [Power/freq], or mean-square [Power].
    % Also, compute the corresponding frequency and frequency units.
    %     [Pxx,w,units] = computepsd( Sxx, w, options.range, options.nfft, options.Fs, 'psd' );
    %     Pxx = computepsd( Sxx, w, 'onesided', nFFT, [], 'psd' );
    % Generate the one-sided spectrum [Power]
    if( rem( nFFT, 2) ), % nFFT is ODD
        Sxx_unscaled = Sxx(1:(nFFT+1)/2,:); % Take only [0,pi] or [0,pi)
        Sxx = [Sxx_unscaled(1,:); 2*Sxx_unscaled(2:end,:)];  % Only DC is a unique point and doesn't get doubled
    else % nFFT is EVEN
        Sxx_unscaled = Sxx(1:nFFT/2+1,:); % Take only [0,pi] or [0,pi)
        Sxx = [Sxx_unscaled(1,:); 2*Sxx_unscaled(2:end-1,:); Sxx_unscaled(end,:)]; % Don't double unique Nyquist point
    end
    
    Pxx = Sxx ./ (2.*pi); % Scale the power spectrum by 2*pi to obtain the psd

end % of myPyulear( x, order, nFFT )