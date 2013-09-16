cl;
% rmpath(genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps'));
% rmpath(genpath('d:\KULeuven\PhD\Matlab\MatlabPath\eeglab10_0_1_0b'));
addpath('d:\KULeuven\PhD\Matlab\MatlabPath\spm8\');

resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP\01-preprocess-plot\';
load(fullfile(resultsDir, 'meanErpDataset.mat'));

meanErpDataset = meanErpDataset(ismember(meanErpDataset.type, 'target'), :);
meanErpDataset = meanErpDataset(~ismember(meanErpDataset.subject, 'S08'), :);
meanErpDataset.subject(ismember(meanErpDataset.subject, 'S09'), :) = {'S08'};
meanErpDataset.subject(ismember(meanErpDataset.subject, 'S10'), :) = {'S09'};

allSub = unique(meanErpDataset.subject);
nSub = numel(allSub);
allCond = unique(meanErpDataset.condition);
nCond = numel(allCond);

% for iS = 1:nSub
%     for iC = 1:nCond
%         
%         temp = meanErpDataset(ismember(meanErpDataset.subject, allSub(iS)) & ismember(meanErpDataset.condition, allCond{iC}), :);
%         if size(temp, 1) ~= 1, error('something wrong here'); end
%         
%         clear dataStruct
%         dataStruct.fsample = temp.fs(1);
%         dataStruct.trial = {temp.meanERP{1}'};
%         dataStruct.time = { ((1:size(temp.meanERP{1}, 1))-1) / temp.fs(1) - temp.tBeforeOnset}; % substract tBeforeOnset
%         dataStruct.label = temp.chanList{1};
%         % dataStruct.dimord = 'chan_time';
%         
%         filename = sprintf('meanERP_%s_%s.mat', allSub{iS}, allCond{iC});
%         D = spm_eeg_ft2spm(dataStruct, filename);        
% %         save('D')
%         
%     end
% end

clear dataStruct
dataStruct.fsample  = meanErpDataset.fs(1);
dataStruct.trial    = cellfun(@(x) x', meanErpDataset.meanERP, 'UniformOutput', false);
dataStruct.time     = cellfun(@(x) ((1:size(x, 1))-1) / meanErpDataset.fs(1) - meanErpDataset.tBeforeOnset(1), meanErpDataset.meanERP, 'UniformOutput', false);
dataStruct.label    = meanErpDataset.chanList{1};
D = spm_eeg_ft2spm(dataStruct, 'erpdatafile');
conds = cellfun(@(x,y) sprintf('%s_%s', x, y), meanErpDataset.subject, meanErpDataset.condition, 'UniformOutput', false);
D = conditions(D, [], conds);
save('spm8_erpDataset', 'D');

% toto = D.selectdata('Cz', [0.1 0.5], 'S09_oddball');





