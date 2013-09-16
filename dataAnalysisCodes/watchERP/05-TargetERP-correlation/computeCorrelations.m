cl;

%================================================================================================================================
%================================================================================================================================

if isunix,
    envVarName = 'HOSTNAME';
else
    envVarName = 'COMPUTERNAME';
end
hostName = lower( strtok( getenv( envVarName ), '.') );

switch hostName,
    case 'kuleuven-24b13c',
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        resDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP\';
        codeDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        resDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciResults\watchERP\';
        codeDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\';
    case {'sunny', 'solaris', ''}
        addpath( genpath( '~/PhD/hybridBCI-stuffs/deps/' ) );
        rmpath( genpath('~/PhD/hybridBCI-stuffs/deps/eeglab10_0_1_0b/external/SIFT_01_alpha') );
        dataDir = '~/PhD/hybridBCI-stuffs/data/';
        resDir = '~/PhD/hybridBCI-stuffs/results/';
        codeDir = '~/PhD/hybridBCI-stuffs/code/';
    otherwise,
        error('host not recognized');
end

[~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
resDir = fullfile( resDir, folderName );
if ~exist(resDir, 'dir'), mkdir(resDir); end

%================================================================================================================================
%================================================================================================================================
load('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP\01-preprocess-plot\meanErpDataset.mat')
meanErpDataset = meanErpDataset( ismember(meanErpDataset.type, 'target'), : );

meanErpDataset.condition = cellfun(@(x) strrep(x, 'hybrid-8-57Hz', 'hybrid-08.57Hz'), meanErpDataset.condition, 'UniformOutput', false);

% meanErpDataset.condition = cellfun(@(x) strrep(x, 'oddball', 'odd'), meanErpDataset.condition, 'UniformOutput', false);
% meanErpDataset.condition = cellfun(@(x) strrep(x, 'hybrid-8-57Hz', 'h08'), meanErpDataset.condition, 'UniformOutput', false);
% meanErpDataset.condition = cellfun(@(x) strrep(x, 'hybrid-10Hz', 'h10'), meanErpDataset.condition, 'UniformOutput', false);
% meanErpDataset.condition = cellfun(@(x) strrep(x, 'hybrid-12Hz', 'h12'), meanErpDataset.condition, 'UniformOutput', false);
% meanErpDataset.condition = cellfun(@(x) strrep(x, 'hybrid-15Hz', 'h15'), meanErpDataset.condition, 'UniformOutput', false);

subjects = unique(meanErpDataset.subject);
conds = unique(meanErpDataset.condition);
conds = conds([5, 1:4]);
shortConds = conds;
shortConds = strrep(shortConds, 'oddball', 'odd');
shortConds = strrep(shortConds, 'hybrid-08.57Hz', 'h08');
shortConds = strrep(shortConds, 'hybrid-10Hz', 'h10');
shortConds = strrep(shortConds, 'hybrid-12Hz', 'h12');
shortConds = strrep(shortConds, 'hybrid-15Hz', 'h15');
nSub = numel(subjects);
nConds = numel(conds);


%================================================================================================================================
%================================================================================================================================
textFilename = fullfile(resDir, 'ERPcorrelations.txt');
fid = fopen(textFilename, 'wt');
fprintf(fid, 'subject, pair, channel, correlation');
for iC = 1:nConds
    fprintf(fid, ', is%s', shortConds{iC});
end
fprintf(fid, '\n');

%================================================================================================================================
%================================================================================================================================
allPairs = combnk(1:nConds, 2);
allPairs = allPairs(end:-1:1,:);
nPairs = size(allPairs, 1);
nChan = unique(cellfun(@(x) size(x, 2), meanErpDataset.meanERP));

for iS = 1:nSub
    for iP = 1:nPairs
        temp1 = meanErpDataset( ismember(meanErpDataset.subject, subjects{iS}) & ismember(meanErpDataset.condition, conds{allPairs(iP, 1)}), : );
        temp2 = meanErpDataset( ismember(meanErpDataset.subject, subjects{iS}) & ismember(meanErpDataset.condition, conds{allPairs(iP, 2)}), : );
        if (size(temp1, 1)~=1) ||  (size(temp1, 1)~=1), error('not only one mean ERP!!'); end
        if (~isequal(temp1.chanList{1}, temp2.chanList{1})), error('different chanList!!!'); end
        for iCh = 1:nChan
            corrVal = corr(temp1.meanERP{1}(:,iCh), temp2.meanERP{1}(:,iCh));
%             fprintf(fid, '%s, %s - %s, %s, %f' ...
%                 , subjects{iS} ...
%                 , conds{allPairs(iP, 1)} ...
%                 , conds{allPairs(iP, 2)} ...
%                 , temp1.chanList{1}{iCh} ...
%                 , corrVal ...
%                 );
            fprintf(fid, '%s, corr(%s/%s), %s, %f' ...
                , subjects{iS} ...
                , shortConds{allPairs(iP, 1)} ...
                , shortConds{allPairs(iP, 2)} ...
                , temp1.chanList{1}{iCh} ...
                , corrVal ...
                );
            for iC = 1:nConds
                fprintf(fid, ', %d', sum(ismember(conds(allPairs(iP,:)), conds{iC})));
            end
            fprintf(fid, '\n');

        end
    end
end

fclose(fid);