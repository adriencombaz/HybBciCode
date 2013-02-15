function [W, V] = beamformerFC(Xs, nc, theta)
% Spatial filter for ERPs that maximizes Fisher's discriminant:
%   var between classes
%   -------------------
%    var within class
%
% Gabriel Pires, Urbano Nunes, and Miguel Castelo-Brance. Statistical spatial
% filtering for a P300-based BCI: Test in able-bodied, and patient with cerebral
% palsy and amyotrophic lateral sclerosis. Journal of Neuroscience Methods, 
% 195:270-281, 2011.
%
% Parameters:
% Xs    - Cell array containing for each class a matrix containing the EEG 
%         data (samples x channels x trials). The number of samples and the
%         number of channels should be equal for each class. The number of
%         trials may vary.
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
% class3 = randn(nsamples, nchannels, ntrials)
% W,V = beamformerFC({class1, class2, class3}, 4)

% Default values for optional parameters
if nargin < 2
    nc = 1;
end
if nargin < 3
    theta = 1.0;
end

% Data dimensions
nclasses = length(Xs);
ninstances = zeros(1,nclasses);
for i = 1:nclasses
    ninstances(i) = size(Xs{i}, 3);
end
[nsamples, nchannels, ~] = size(Xs{1});

% Sanity check
for i = 1:nclasses
    if size(Xs{i}, 1) ~= nsamples
        error('Classes have unequal amount of samples');
    end
    
    if size(Xs{i}, 2) ~= nchannels
        error('Classes have unequal amount of channels');
    end
end

% Class probability
p = zeros(1,nclasses);
for i = 1:nclasses
    p(i) = ninstances(i) / sum(ninstances);
end

% Calculate ERPs
means = zeros(nsamples, nchannels, nclasses);
for i = 1:nclasses
    means(:,:,i) = mean(Xs{i}, 3);
end
grand_avg = mean(means, 3);

% Calculate between class co-variation
S_b = zeros(nchannels, nchannels);
for i = 1:nclasses
    diff = means(:,:,i) - grand_avg;
    S_b = S_b + p(i) * (diff' * diff);
end

% Calculate within class co-variation
S_w = zeros(nchannels, nchannels);
for i = 1:nclasses
    for k = 1:ninstances(i)
        diff = Xs{i}(:,:,k) - means(:,:,i);
        S_w = S_w + (diff' * diff);
    end
end

% Solve eigen-decomposition
I = eye(nchannels);
[W, V] = eig(S_b, (I-theta) * S_w + (theta * I));

% Order resulting components by their corresponding eigenvalues
[V, order] = sort(diag(V), 1, 'Descend');
W = real(W(:, order));

% Select requested components
W = W(:,1:nc);
V = V(1:nc);

end