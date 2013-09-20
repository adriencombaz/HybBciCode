cl;
% rmpath(genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps'));
% rmpath(genpath('d:\KULeuven\PhD\Matlab\MatlabPath\eeglab10_0_1_0b'));
% addpath('d:\KULeuven\PhD\Matlab\MatlabPath\spm8\');

dataDir     = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
resultsDir  = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP\';
[~, folderName, ~]  = fileparts( fileparts(mfilename('fullpath')) );
resultsDir          = fullfile( resultsDir, folderName );
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

TableName   = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\01-preprocess-plot\watchErpDataset2.xlsx';
fileList    = dataset('XLSFile', TableName);

subjects = unique( fileList.subjectTag );
conditions = unique( fileList.condition );
% conditionValues = 1000*(1:numel(conditions));
nSub = numel(subjects);
nCond = numel(conditions);
spm('defaults', 'eeg');


for iS = 1%:nSub
    resultsDirSi = fullfile(resultsDir, sprintf('subject_%s', subjects{iS}));
    if ~exist(resultsDirSi, 'dir'), mkdir(resultsDirSi); end
    for iC = 1:nCond
        subset = fileList( ismember( fileList.subjectTag, subjects{iS} ) & ismember( fileList.condition, conditions{iC} ), : );
        filesToMerge = cell( size(subset, 1), 1 );
        for iR = 1:size(subset, 1)
            
            %--------------------------------------------------------------------------------------------------------------------------------
            % create EEG object from .bdf and parameter files
            %--------------------------------------------------------------------------------------------------------------------------------
            fprintf('\nreading data\n');
            sessionDir  = fullfile(dataDir, subset.sessionDirectory{iR});
            filename    = ls(fullfile(sessionDir, [subset.fileName{iR} '*.bdf']));
            outfile     = fullfile(resultsDirSi, ['spm8_' filename(1:end-4)]);
            S = [];
            S.dataset = fullfile(sessionDir, filename);
            S.outfile = outfile;
            S.channels = 'all';
            S.continuous = true;
            paramfile = fullfile(sessionDir, [filename(1:19) '.mat']);
            [D, targetValue, nonTargetValue] = spm_eeg_convert_custom(S, paramfile);
            clear paramfile
            
            %--------------------------------------------------------------------------------------------------------------------------------
            % specify montage
            %--------------------------------------------------------------------------------------------------------------------------------
            fprintf('\nadjust montage\n');
            refChanNames        = {'EXG1', 'EXG2'};
            discardChanNames    = {'EXG1', 'EXG2', 'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8', 'Status'};
            indChansToDiscard   = ismember(D.chanlabels, discardChanNames);
            indRefChans         = ismember(D.chanlabels, refChanNames);
            
            tempFilename = fullfile(resultsDirSi, D.fname);
            
            S = [];
            S.D = fullfile(resultsDirSi, D.fname);
            S.montage.labelorg    = D.chanlabels;
            S.montage.tra = eye( numel( S.montage.labelorg ) );
            S.montage.tra(:, indRefChans) = -1/numel(refChanNames);
            S.montage.tra(indChansToDiscard, :) = [];
            S.montage.labelnew = S.montage.labelorg( ~indChansToDiscard );
            S.keepothers = 'no';
            D = spm_eeg_montage(S);
            delete(tempFilename);
            delete([tempFilename(1:end-4) '.dat']);
            
            %--------------------------------------------------------------------------------------------------------------------------------
            % bandpass filter
            %--------------------------------------------------------------------------------------------------------------------------------
            fprintf('\nfilter\n');
            tempFilename = fullfile(resultsDirSi, D.fname);
            S = [];
            S.D = fullfile(resultsDirSi, D.fname);
            S.filter.type = 'but';
            S.filter.order = 4;
            S.filter.band = 'bandpass';
            S.filter.PHz = [1 30];
            S.filter.dir = 'twopass';
            D = spm_eeg_filter(S);
            delete(tempFilename);
            delete([tempFilename(1:end-4) '.dat']);
            
            %--------------------------------------------------------------------------------------------------------------------------------
            % cut epochs
            %--------------------------------------------------------------------------------------------------------------------------------
            fprintf('\nepoch\n');
            tempFilename = fullfile(resultsDirSi, D.fname);
            S = [];
            S.D = fullfile(resultsDirSi, D.fname);
            S.pretrig = 0;
            S.posttrig = 800;
            S.trialdef(1).conditionlabel = sprintf('target-%s', conditions{iC});
            S.trialdef(1).eventvalue = targetValue;
            S.trialdef(1).eventtype = 'STATUS';
%             S.trialdef(2).conditionlabel = 'non-target';
%             S.trialdef(2).eventvalue = nonTargetValue;
%             S.trialdef(2).eventtype = 'STATUS';
            S.reviewtrials = 0;
            S.save = 0;
            D = spm_eeg_epochs(S);
            delete(tempFilename);
            delete([tempFilename(1:end-4) '.dat']);

            %--------------------------------------------------------------------------------------------------------------------------------
            % downsample
            %--------------------------------------------------------------------------------------------------------------------------------
            fprintf('\nepoch\n');
            tempFilename = fullfile(resultsDirSi, D.fname);
            S = [];
            S.D = fullfile(resultsDirSi, D.fname);
            S.fsample_new = 256;
            D = spm_eeg_downsample(S);            
            delete(tempFilename);
            delete([tempFilename(1:end-4) '.dat']);
            filesToMerge{iR} = fullfile(resultsDirSi, D.fname);
            
        end
        
        %--------------------------------------------------------------------------------------------------------------------------------
        % merge trials from the same condition
        %--------------------------------------------------------------------------------------------------------------------------------
        S = [];
%         S.D = cell2mat(cellfun(@(x) fullfile(resultsDirSi, x), filesToMerge, 'UniformOutput', false));
        S.D = cell2mat(filesToMerge);
        S.recode = 'same';
        D = spm_eeg_merge(S);
        cellfun(@delete, filesToMerge);
        cellfun(@(x) delete([x(1:end-4) '.dat']), filesToMerge);
        close(gcf);
        tempFilename = D.fname;
        movefile(tempFilename, fullfile(resultsDirSi, tempFilename));
        movefile([tempFilename(1:end-4) '.dat'], fullfile(resultsDirSi, [tempFilename(1:end-4) '.dat']));
    
        %--------------------------------------------------------------------------------------------------------------------------------
        % identify and remove artifacts
        %--------------------------------------------------------------------------------------------------------------------------------
        tempFilename = fullfile(resultsDirSi, D.fname);
        S = [];
        S.D = fullfile(resultsDirSi, D.fname);
        S.badchanthresh = 0.2;
        S.methods.channels = {'all'};
        S.methods.fun = 'peak2peak';
        S.methods.settings.threshold = 50;
        D = spm_eeg_artefact(S);
        delete(tempFilename);
        delete([tempFilename(1:end-4) '.dat']);
        
        tempFilename = fullfile(resultsDirSi, D.fname);
        S = [];
        S.D = fullfile(resultsDirSi, D.fname);
        D = spm_eeg_remove_bad_trials(S);
        delete(tempFilename);
        delete([tempFilename(1:end-4) '.dat']);
        
        %--------------------------------------------------------------------------------------------------------------------------------
        % rename the .mat and .dat spm file
        %--------------------------------------------------------------------------------------------------------------------------------
        tempFilename = D.fname;
        spm_changepath( fullfile(resultsDirSi, tempFilename), tempFilename(1:end-4), conditions{iC} );
        movefile( ...
            fullfile( resultsDirSi, tempFilename ) ...
            , fullfile( resultsDirSi, sprintf('%s.mat', conditions{iC}) )...
            );
        movefile( ...
            fullfile( resultsDirSi, [tempFilename(1:end-4) '.dat'] ) ...
            , fullfile( resultsDirSi, sprintf('%s.dat', conditions{iC}) ) ...
            );
        delete( fullfile( resultsDirSi, [tempFilename '.old'] ) );
    
    end
end

