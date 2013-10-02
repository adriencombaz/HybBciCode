cl;

Fs = 1024;
tMax = 20; % seconds
t  = 0:(1/Fs):(tMax-(1/Fs));

A0 = 0;
A  = 0.2*ones(1, numel(t)) + randn(1, numel(t)) .* ones(1, numel(t));   % Vpeak

tStart = 3;
tEnd = 5;
A2  = A;   % Vpeak
A2((tStart*Fs+1) : tEnd*Fs) = 0.2;
F1 = 10; % Hz

x  = A0 + A.*sin( 2*pi*t*F1 );
x2  = A0 + A2.*sin( 2*pi*t*F1 );
fBinW = 1;

OVERLAP_RATIO = 0.7;
nFFT = round( Fs );
windowLen = nFFT;
nOverlap = ceil( windowLen * OVERLAP_RATIO );
minFreq = 1;
maxFreq = 60;
timesInSec = 1:tMax;



bp = zeros(1, numel(timesInSec));
bp2 = zeros(1, numel(timesInSec));
for iT = 1:numel(timesInSec)
    bp(iT) = bandpower( x(1:(iT*Fs)), Fs, [F1-fBinW/2 F1+fBinW/2] );
    bp2(iT) = bandpower( x(((iT-1)*Fs)+1:(iT*Fs)), Fs, [F1-fBinW/2 F1+fBinW/2] );
end
figure,
subplot(3,1,1)
plot(t, x)
subplot(3,1,2)
spectrogram( ...
    x, ...  data
    windowLen, ...          windowLength is a Hamming window of length nFFT.
    nOverlap, ...           nOverlap is the number of samples that each segment overlaps. The default value is the number producing 50% overlap between segments.
    nFFT, ...               nFFT is the FFT length and is the maximum of 256 or the next power of 2 greater than the length of each segment of x. (Instead of nfft, you can specify a vector of frequencies, F. See below for more information.)
    Fs, ...     Fs is the sampling frequency, which defaults to normalized frequency.
    'yaxis' ...
    );
ylim( [minFreq maxFreq] );
subplot(3,1,3)
plot(bp, '+-')
hold on
plot(bp2, 'r+-')
% ylim( [0.4 0.6] );


% tStart = 3;
% tEnd = 5;
% tt = tEnd-tStart;
% Fnoise = F1;
% AFnoise = 5;
% x( (tStart*Fs+1) : tEnd*Fs ) = x( (tStart*Fs+1) : tEnd*Fs ) + AFnoise*sin( 2*pi*t((tStart*Fs+1) : tEnd*Fs)*Fnoise );
bp = zeros(1, numel(timesInSec));
for iT = 1:numel(timesInSec)
    bp(iT) = bandpower( x2(1:(iT*Fs)), Fs, [F1-fBinW/2 F1+fBinW/2] );
end
% bp
figure,
subplot(3,1,1)
plot(t, x2)
subplot(3,1,2)
spectrogram( ...
    x2, ...  data
    windowLen, ...          windowLength is a Hamming window of length nFFT.
    nOverlap, ...           nOverlap is the number of samples that each segment overlaps. The default value is the number producing 50% overlap between segments.
    nFFT, ...               nFFT is the FFT length and is the maximum of 256 or the next power of 2 greater than the length of each segment of x. (Instead of nfft, you can specify a vector of frequencies, F. See below for more information.)
    Fs, ...     Fs is the sampling frequency, which defaults to normalized frequency.
    'yaxis' ...
    );
ylim( [minFreq maxFreq] );
subplot(3,1,3)
plot(bp, '+-')
% ylim( [0.4 0.6] );





