function buildPooledSvmClassifier_perSubject( iS, nRunsForTraining, targetFS, nFoldsSvm )

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
        resDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watch-ERP\';
        codeDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        resDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciProcessedData\watch-ERP\';
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

if isunix,
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset2.csv');
    fileList    = dataset('File', TableName, 'Delimiter', ',');
else
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset2.xlsx');
    fileList    = dataset('XLSFile', TableName);
end
fileList( ismember( fileList.condition, 'oddball' ), : ) = [];

%================================================================================================================================
%================================================================================================================================

%--------------------------------------------------------------------------
cond    = unique( fileList.condition );
nCond   = numel(cond);
sub     = unique( fileList.subjectTag );
nAveMax = 10;
fileList= fileList( ismember( fileList.subjectTag, sub{iS} ), : );

%--------------------------------------------------------------------------
[~, folderName, ~] = fileparts(cd);
resDir = fullfile( resDir, folderName, sprintf('LinSvmPooled_%dRunsForTrain_%dHz_%.2dcvSvm', nRunsForTraining, targetFS, nFoldsSvm), sprintf('subject_%s', sub{iS}) );
if ~exist( resDir, 'dir' ), mkdir(resDir); end

%--------------------------------------------------------------------------
run = unique( fileList.run );
if ~isequal(run(:), (1:max(run))'), error('wrong run numbering'); end
listTrainRuns = combntns(run, nRunsForTraining);
nCv = size(listTrainRuns, 1);
listTestRuns = zeros( nCv, numel(run)-size(listTrainRuns, 2) );
for iCv = 1:nCv
    listTestRuns(iCv, :) = run( ~ismember(run, listTrainRuns(iCv,:)) );
end

%--------------------------------------------------------------------------
tBeforeOnset = 0;
tAfterOnset = .6;
nSPcomp = 4;
butterFilt.lowMargin = .5;
butterFilt.highMargin = 20;
butterFilt.order = 3;

for iCv = 1:nCv
    
    %==============================================================================
    %==============================================================================
    
    %% process the eeg data and generate the cuts for training
    
    %==============================================================================
    %==============================================================================
    cuts_proc   = cell(nRunsForTraining, nCond);
    labels_cuts = cell(nRunsForTraining, nCond);
    
    for iR = 1:nRunsForTraining
        for iC = 1:nCond
            
            %
            %--------------------------------------------------------------------------
            runId           = listTrainRuns(iCv, iR);
            subFileList     = fileList( ismember( fileList.condition, cond{iC} ) & ismember( fileList.run, runId ), : );
            if size(subFileList)~=1, error('size should be 1!!'); end
            
            sessionDir      = fullfile(dataDir, subFileList.sessionDirectory{1});
            [dum name ext]  = fileparts( ls(fullfile(sessionDir, [subFileList.fileName{1} '*.bdf'])) );
            filename        = strtrim( [name ext] );
            [dum name ext]  = fileparts( ls(fullfile(sessionDir, [subFileList.fileName{1}(1:19) '*.mat'])) );
            paramFile       = strtrim( [name ext] );
            pars            = load( fullfile(sessionDir,paramFile), 'nCuesToShow', 'nRepetitions', 'lookHereStateSeq', 'realP3StateSeqOnsets', 'ssvepFreq', 'scenario' );
            
            pars.scenario = rmfield(pars.scenario, 'textures');
            
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
                cuts_proc{iR, iC} = cuts;
            else
                nbins = floor( size(cuts, 1) / DSF );
                cuts_proc{iR, iC} = zeros( nbins, size(cuts, 2), size(cuts, 3) ); % , 'single' );
                for i = 1:nbins
                    cuts_proc{iR, iC}(i,:,:) = mean( cuts( (i-1)*DSF+1:i*DSF, :, : ), 1 );
                end
            end
            
            % get labels
            %------------------------------------------------------------------------------
            labels_cuts{iR, iC} = zeros(1, size(cuts, 3));
            targetStateSeq  = pars.lookHereStateSeq( pars.lookHereStateSeq~=max(pars.lookHereStateSeq) );
            nP3item         = max( targetStateSeq );
            tempp           = repmat( targetStateSeq, nP3item*pars.nRepetitions, 1);
            targetId        = tempp(:);
            labels_cuts{iR, iC}( pars.realP3StateSeqOnsets(:) == targetId(:) ) = 1;
            clear cuts
            
            % restrict the number of available epoch in order to be fair with the baseline condition
            %------------------------------------------------------------------------------------------
            indTargetEvents = find( labels_cuts{iR, iC} == 1 );
            subsetInd       = randperm( numel(indTargetEvents) );
            nIndsToKeep     = round( numel(indTargetEvents) / (nRunsForTraining*nCond) );
            indTargetEvents = indTargetEvents( subsetInd(1:nIndsToKeep) );
            
            indNonTargetEvents  = find( labels_cuts{iR, iC} == 0 );
            subsetInd           = randperm( numel(indNonTargetEvents) );
            nIndsToKeep         = round( numel(indNonTargetEvents) / (nRunsForTraining*nCond) );
            indNonTargetEvents  = indNonTargetEvents( subsetInd(1:nIndsToKeep) );
            
            labels_cuts{iR, iC} = labels_cuts{iR, iC}( [indTargetEvents(:) ; indNonTargetEvents(:)] );
            cuts_proc{iR, iC}   = cuts_proc{iR, iC}( :, :, [indTargetEvents(:) ; indNonTargetEvents(:)] );
            
        end % OF CONDITION LOOP
    end % OF NRUNSFORTRAINING LOOP
    
    
    for iAve = nAveMax:-1:1
        
        %==============================================================================
        %==============================================================================
        
        %% build the classifier based on the chosen number of averages
        
        %==============================================================================
        %==============================================================================
        fprintf('Subject %s, fold %d out of %d, %d averages\n', sub{iS}, iCv, nCv, iAve);
        classifierFilename  = fullfile( resDir, sprintf('svm-%.2dAverages-fold%.2d.mat', iAve, iCv) );
        
        % select/balance/average trials w.r.t. the desired number of repetitions
        %------------------------------------------------------------------------------
        nT_train    = 1000;
        nNT_train   = 1000;
        SigTrainT   = zeros( nbins, nChans, nT_train ); %, 'single' );
        SigTrainNT  = zeros( nbins, nChans, nNT_train ); %, 'single' );
        nT_train_iR_iC  = round( nT_train / (nRunsForTraining*nCond) );
        nNT_train_iR_iC = round( nNT_train / (nRunsForTraining*nCond) );
        
        for iR = 1:nRunsForTraining
            for iC = 1:nCond
                
                indTargetEvents = find( labels_cuts{iR, iC} == 1 );
                for i = 1:nT_train_iR_iC
                    ind = (iR-1)*nCond*nT_train_iR + (iC-1)*nT_train_iR + i;
                    selection           = randperm( numel(indTargetEvents) );
                    selection           = selection(1:iAve);
                    SigTrainT(:,:,ind)  = mean( cuts_proc{iR, iC}( :, :, indTargetEvents(selection) ), 3 );
                end
                
                indNonTargetEvents = find( labels_cuts{iR, iC} == 0 );
                for i = 1:nNT_train_iR_iC
                    ind = (iR-1)*nCond*nNT_train_iR_iC + (iC-1)*nNT_train_iR_iC + i;
                    selection           = randperm( numel(indNonTargetEvents) );
                    selection           = selection(1:iAve);
                    SigTrainNT(:,:,ind) = mean( cuts_proc{iR, iC}( :, :, indNonTargetEvents(selection) ), 3 );
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
        
        trainingFileNames = fileList_iC.fileName( ismember( fileList_iC.run, listTrainRuns( iCv, : ) ) );
        testingFileNames = fileList_iC.fileName( ismember( fileList_iC.run, listTestRuns( iCv, : ) ) );
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
            , 'trainingFileNames' ...
            , 'testingFileNames' ...
            );
        
    end % OF IAVE LOOP 
end % OF ICV LOOP
end % OF FUNCTION