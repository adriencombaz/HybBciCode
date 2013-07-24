function buildSvmClassifier_perSubject( iS, aveList, targetFS, nFoldsSvm  )

%% ========================================================================================================

% init host name
%--------------------------------------------------------------------------
if isunix,
    envVarName = 'HOSTNAME';
else
    envVarName = 'COMPUTERNAME';
end
hostName = lower( strtok( getenv( envVarName ), '.') );

switch hostName,
    case 'kuleuven-24b13c',
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP_2stim\02-xxx-classify-erps\';
        codeDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP_2stim\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciProcessedData\watchERP_2stim\02-xxx-classify-erps\';
        codeDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP_2stim\';
    case {'sunny', 'solaris', ''}
        addpath( genpath( '~/PhD/hybridBCI-stuffs/deps/' ) );
        rmpath( genpath('~/PhD/hybridBCI-stuffs/deps/eeglab10_0_1_0b/external/SIFT_01_alpha') );
        dataDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/data/';
        resDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/results/02-classify-erps/';
        codeDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/code/';
    otherwise,
        error('host not recognized');
end

if isunix,
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset.csv');
    fileList    = dataset('File', TableName, 'Delimiter', ',');
else
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset.xlsx');
    fileList    = dataset('XLSFile', TableName);
end



%% ========================================================================================================

%--------------------------------------------------------------------------
sub     = unique( fileList.subjectTag );
fileList = fileList( ismember( fileList.subjectTag, sub{iS} ), : );
resDir = fullfile( resDir, sprintf('LinSvm_%dHz_%.2dcvSvm', targetFS, nFoldsSvm), sprintf('subject_%s', sub{iS}) );
if ~exist( resDir, 'dir' ), mkdir(resDir); end

%--------------------------------------------------------------------------
run = unique( fileList.run );
if ~isequal(run(:), (1:max(run))'), error('wrong run numbering'); end
listTrainRuns = {1, 2, 3, [1 2], [2 3], [3 4], [1 2 3], [2 3 4]};

nClassifiers = numel(listTrainRuns);
listTestRuns = cell( nClassifiers, 1 );
for iCl = 1:nClassifiers
    listTestRuns{iCl} = run( run > max(listTrainRuns{iCl}) );
end

%--------------------------------------------------------------------------
% nAveMax = 10;
tBeforeOnset = 0;
tAfterOnset = .6;
nSPcomp = 4;
butterFilt.lowMargin = .5;
% butterFilt.highMargin = 30;
butterFilt.highMargin = 20;
butterFilt.order = 3;

%--------------------------------------------------------------------------

for iCl = 1:nClassifiers
    
    %==============================================================================
    %==============================================================================
    
    %% process the eeg data and generate the cuts for training
    
    %==============================================================================
    %==============================================================================
    nRunsForTraining    = numel( listTrainRuns{iCl} );
    cuts_proc           = cell(1, nRunsForTraining);
    labels_cuts         = cell(1, nRunsForTraining);
    targetSquare        = cell(1, nRunsForTraining);
    for iR = 1:nRunsForTraining
        
        %
        %--------------------------------------------------------------------------
        runId           = listTrainRuns{iCl}(iR);
        sessionDir      = fullfile(dataDir, fileList.sessionDirectory{ ismember(fileList.run,runId) });
        [~, name, ext]  = fileparts( ls(fullfile(sessionDir, [fileList.fileName{ ismember(fileList.run,runId) } '*.bdf'])) );
        filename        = strtrim( [name ext] );
        [~, name, ext]  = fileparts( ls(fullfile(sessionDir, [fileList.fileName{ ismember(fileList.run,runId) }(1:19) '*.mat'])) );
        paramFile       = strtrim( [name ext] );
        pars            = load( fullfile(sessionDir,paramFile), 'nP3item', 'nCuesToShow', 'nRepetitions', 'lookHereStateSeq', 'realP3StateSeqOnsets', 'ssvepFreq', 'scenario' );

        pars.scenario   = rmfield(pars.scenario, 'textures');
        
        onsetEventInd   = cellfun( @(x) strcmp(x, 'P300 stim on'), {pars.scenario.events(:).desc} );
        onsetEventValue = pars.scenario.events( onsetEventInd ).id;
        
        %
        %--------------------------------------------------------------------------
        erpData                 = eegDataset3( sessionDir, filename, 'onsetEventValue', onsetEventValue );
        erpData.tBeforeOnset    = tBeforeOnset;
        erpData.tAfterOnset     = tAfterOnset;
        nChans                  = numel( erpData.eegChanInd );

        % filter the eeg data
        %------------------------------------------------------------------------------
        erpData.butterFilter( butterFilt.lowMargin, butterFilt.highMargin, butterFilt.order );
        
        % get cuts
        %------------------------------------------------------------------------------
        cuts = erpData.getCuts(); % single( erpData.getCuts2() );
        cuts(:, ~ismember(1:erpData.nChan, erpData.eegChanInd), :) = [];

        % downsample cuts
        %------------------------------------------------------------------------------
        DSF = erpData.fs / targetFS;
        if DSF ~= floor(DSF), error('something wrong with the sampling rate'); end
        if DSF == 1
            cuts_proc{iR} = cuts;
        else
            nbins = floor( size(cuts, 1) / DSF );
            cuts_proc{iR} = zeros( nbins, size(cuts, 2), size(cuts, 3) ); % , 'single' );
            for i = 1:nbins
                cuts_proc{iR}(i,:,:) = mean( cuts( (i-1)*DSF+1:i*DSF, :, : ), 1 );
            end
        end
        
        % get labels
        %------------------------------------------------------------------------------
        labels_cuts{iR} = zeros(1, size(cuts, 3));
        targetSquare{iR}= zeros(1, size(cuts, 3));
        targetStateSeq  = pars.lookHereStateSeq( pars.lookHereStateSeq~=max(pars.lookHereStateSeq) );
        tempp           = repmat( targetStateSeq, pars.nP3item*pars.nRepetitions, 1);
        targetId        = tempp(:);
        for iF = 1:numel(pars.realP3StateSeqOnsets)
            stimId = (iF-1)*pars.nP3item + pars.realP3StateSeqOnsets{iF};
            labels_cuts{iR}( stimId(:) == targetId(:) ) = 1;
            targetSquare{iR}( ismember(targetId, (iF-1)*pars.nP3item+1:iF*pars.nP3item) ) = iF;
        end
        clear cuts
                
    end
    
    for iAve = aveList
    
        %==============================================================================
        %==============================================================================

        %% build the classifier based on the chosen number of averages

        %==============================================================================
        %==============================================================================
        fprintf('Subject %s, fold %d out of %d, %d averages\n', sub{iS}, iCl, nClassifiers, iAve);
        classifierFilename = 'svm-train';
        for iR = 1:nRunsForTraining
            classifierFilename = sprintf('%s%d', classifierFilename, listTrainRuns{iCl}(iR));
        end
        classifierFilename  = fullfile( resDir, sprintf('%s-%.2dAverages.mat',classifierFilename, iAve) );
        
        % select/balance/average trials w.r.t. the desired number of repetitions
        %------------------------------------------------------------------------------
        nT_train    = 1000;
        nNT_train   = 1000;
        SigTrainT   = zeros( nbins, nChans, nT_train ); %, 'single' );
        SigTrainNT  = zeros( nbins, nChans, nNT_train ); %, 'single' );
        nT_train_iR_iF  = round( nT_train / (nRunsForTraining*numel(pars.ssvepFreq)) );
        nNT_train_iR_iF = round( nNT_train / (nRunsForTraining*numel(pars.ssvepFreq)) );
        
        for iR = 1:nRunsForTraining
            
            for iF = 1:numel(pars.ssvepFreq)
            
                indTargetEvents = find( labels_cuts{iR} == 1 & targetSquare{iR} == iF );
                for i = 1:nT_train_iR_iF
                    ind = (iR-1)*numel(pars.ssvepFreq)*nT_train_iR_iF + (iF-1)*nT_train_iR_iF + i;
                    selection           = randperm( numel(indTargetEvents) );
                    selection           = selection(1:iAve);
                    SigTrainT(:,:,ind)  = mean( cuts_proc{iR}( :, :, indTargetEvents(selection) ), 3 );
                end
                
                indNonTargetEvents = find( labels_cuts{iR} == 0 & targetSquare{iR} == iF );
                for i = 1:nNT_train_iR_iF
                    ind = (iR-1)*numel(pars.ssvepFreq)*nNT_train_iR_iF + (iF-1)*nNT_train_iR_iF + i;
                    selection           = randperm( numel(indNonTargetEvents) );
                    selection           = selection(1:iAve);
                    SigTrainNT(:,:,ind) = mean( cuts_proc{iR}( :, :, indNonTargetEvents(selection) ), 3 );
                end
            
            end
    
        end
        
        % reshape
        %------------------------------------------------------------------------------
        featTrain_T     = reshape(SigTrainT, size(SigTrainT,1)*size(SigTrainT,2), size(SigTrainT,3))';
        featTrain_NT    = reshape(SigTrainNT, size(SigTrainNT,1)*size(SigTrainNT,2), size(SigTrainNT,3))';
        clear SigTrainT SigTrainNT
        
        % normalization
        %------------------------------------------------------------------------------
        Xtrain = [featTrain_T ; featTrain_NT];
        Ytrain = [ones(nT_train,1); -ones(nNT_train,1)];
        clear featTrain_T featTrain_NT
        
        maxx    = max(Xtrain);
        minx   = min(Xtrain);
        %             Xtrain  = (Xtrain - repmat(minxx,size(Xtrain,1),1)) ./ repmat(maxx-minxx,size(Xtrain,1),1);
        Xtrain  = bsxfun(@minus, Xtrain, minx);
        Xtrain  = bsxfun(@rdivide, Xtrain, maxx-minx);
        
        % train the SVM
        %------------------------------------------------------------------------------
        nfolds      = nFoldsSvm;	% Number of subsets for the cross-validation
        igam        = 1;    % Central value of the regularization paramter for the first line search
        if ~exist('B_init', 'var'), B_init = []; end
        error_type  = 1;    % 1: calculate mean square error on misclassified data
        % 2: calculate mean square error on active data (data that are not beyond the margin...even if correctly classified)
        
        ntrain      = size(Xtrain,1);
        Xtrain      = [Xtrain ones(ntrain,1)];
        Xtrain      = Xtrain; % double( Xtrain );
        
        [B_init iter_init]  = Lin_SVM_Keerthi(Xtrain,Ytrain,B_init,igam);
        linesearch_algo;
        close all
        best_gamma          = exp(Xm);
        [B iter_final]  = Lin_SVM_Keerthi(Xtrain,Ytrain,B_init,best_gamma);
        clear Xtrain
        
        % save data
        %------------------------------------------------------------------------------
        trainingRuns        = listTrainRuns{iCl};
        testingRuns         = listTestRuns{iCl};
        trainingFileNames   = fileList.fileName( ismember(fileList.run, trainingRuns) );
        testingFileNames    = fileList.fileName( ismember(fileList.run, testingRuns) );
        save( classifierFilename ...
            , 'butterFilt' ...
            , 'targetFS'...
            , 'maxx' ...
            , 'minx' ...
            , 'B' ...
            , 'tBeforeOnset' ...
            , 'tAfterOnset' ...
            , 'nSPcomp' ...
            , 'iAve' ...
            , 'trainingRuns' ...
            , 'testingRuns' ...
            , 'trainingFileNames' ...
            , 'testingFileNames' ...
            );

    end
end


end