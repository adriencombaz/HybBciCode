function W = beamformerCFMS(X1, X2, nc, theta)
% A combination of the BeamformerFC and BeamformerSNR classes that combines
% both methods in a suboptimum way. First BeamformerFC is run to generate the
% first nc/2 components. Then, BeamformerSNR is run on the FC result to
% generate the last nc/2 components.
%
% Gabriel Pires, Urbano Nunes, and Miguel Castelo-Brance. Statistical spatial
% filtering for a P300-based BCI: Test in able-bodied, and patient with cerebral
% palsy and amyotrophic lateral sclerosis. Journal of Neuroscience Methods, 
% 195:270-281, 2011.
%
% Parameters:
% X1    - Matrix containing for each class a matrix containing the EEG 
%         data (samples x channels x trials) for class 1 (signal + noise).
%         The number of samples and the number of channels should be equal
%         to X2. The number of trials may vary.
% X2    - Matrix containing for each class a matrix containing the EEG 
%         data (samples x channels x trials) for class 2 (noise).
%         The number of samples and the number of channels should be equal
%         to X1. The number of trials may vary.
% nc    - Number of components to retain, should be an even number
%         (defaults to 2)
% theta - Regularization parameter to prevent overfitting (0...1) defaults
%         to 1.
%
% Returns:
% W     - Matrix containing the spatial filter with the weights as rows and
%         components as columns.
%
% Example usage:
% nsamples = 100
% nchannels = 32
% ntrials = 10
% class1 = randn(nsamples, nchannels, ntrials)
% class2 = randn(nsamples, nchannels, ntrials)
% W = beamformerCFMS(class1, class2, 4)

% Default values for optional parameters
if nargin < 3
    nc = 2;
end
if nargin < 4
    theta = 1.0;
end

% Data dimensions
[nsamples, nchannels, ninstances1] = size(X1);
ninstances2 = size(X2, 3);

% Sanity check
if size(X2, 1) ~= nsamples
    error('Classes have unequal amount of samples');
end
    
if size(X2, 2) ~= nchannels
    error('Classes have unequal amount of channels');
end

if mod(nc, 2) ~= 0
    error('NC parameter should be even');
end

% Calculate FC beamformer
W_fc = beamformerFC({X1, X2}, nchannels, theta);

% Apply FC beamformer
X1_fc = zeros(nsamples, nchannels, ninstances1);
X2_fc = zeros(nsamples, nchannels, ninstances2);
for i = 1:ninstances1
    X1_fc(:,:,i) = X1(:,:,i) * W_fc;
end
for i = 1:ninstances2
    X2_fc(:,:,i) = X2(:,:,i) * W_fc;
end

% Calculate SNR beamformer on the result (skip first nc/2 components)
W_snr = beamformerSNR(X1_fc(:,nc/2+1:end,:), X2_fc(:,nc/2+1:end,:), nc/2, theta);

% Prepend nc/2 zero-rows in order to make W_snr a proper spatial filter
W_snr = cat(1, zeros(nc/2, size(W_snr,2)), W_snr);

% Construct filter that will take the first nc/2 FC components applied
% to the EEG data, and then the first nc/2 SNR components applied to the
% FC filtered data.
I = eye(nchannels);
W = W_fc * cat(2, I(:,1:nc/2), W_snr);