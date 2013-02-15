function [W, V] = beamformerSNR(X1, X2, nc, theta)
% Spatial filter for ERPs that maximizes the signal to noise ratio between
% two classes. The first class is regarded as signal+noise and the second
% class as noise only.
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
% nc    - Number of components to retain (defaults to 1)
% theta - Regularization parameter to prevent overfitting (0...1) defaults
%         to 1.
%
% Returns:
% W     - Matrix containing the spatial filter with the weights as rows and
%         components as columns.
% V     - Eigenvalues corresponding to each component.
%
% Example usage:
% nsamples = 100
% nchannels = 32
% ntrials = 10
% class1 = randn(nsamples, nchannels, ntrials)
% class2 = randn(nsamples, nchannels, ntrials)
% W,V = beamformerSNR(class1, class2, 4)

% Default values for optional parameters
if nargin < 3
    nc = 1;
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

R1 = zeros(nchannels, nchannels, ninstances1);
for i = 1:ninstances1
    X_cov = X1(:,:,i)' * X1(:,:,i);
    R1(:,:,i) = X_cov / trace(X_cov);
end
R1 = mean(R1, 3);

R2 = zeros(nchannels, nchannels, ninstances2);
for i = 1:ninstances2
    X_cov = X2(:,:,i)' * X2(:,:,i);
    R2(:,:,i) = X_cov / trace(X_cov);
end
R2 = mean(R2, 3);

% Solve eigen-decomposition
[W, V] = eig(R1, (R1 + theta*R2));

% Order resulting components by their corresponding eigenvalues
[V, order] = sort(diag(V), 1, 'Descend');
W = real(W(:, order));

% Select requested components
W = W(:,1:nc);
V = V(1:nc);

end




