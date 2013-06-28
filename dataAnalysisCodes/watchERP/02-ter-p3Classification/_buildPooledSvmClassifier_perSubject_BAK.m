function buildPooledSvmClassifier_perSubject_BAK( iS )

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

sub     = unique( fileList.subjectTag );
cond    = unique( fileList.condition );
nSub    = numel(sub);
nCond   = numel(cond);
nAveMax = 10;
allRuns = unique(fileList.run);
nRuns   = numel( allRuns );

[dum1 folderName dum2] = fileparts(cd);
resDir = fullfile( resDir, folderName, 'LinSvmPooled', sprintf('subject_%s', sub{iS}) );
if ~exist( resDir, 'dir' ), mkdir(resDir); end

tBeforeOnset = 0;
tAfterOnset = .6;
nSPcomp = 4;
butterFilt.lowMargin = .5;
butterFilt.highMargin = 30;
butterFilt.order = 3;
targetFS = 128;
nT_train_perCond    = 250;
nNT_train_perCond   = 250;


for iRun = 1:nRuns
    
    for iAve = 1:nAveMax

        %================================================================================================================================
        %  BUILD FEATURES FROM ALL CONDITIONS
        %================================================================================================================================

        featTrain_T     = cell(1, nCond);
        featTrain_NT    = cell(1, nCond);
        
        for  iC = 1:nCond
            
            % read data
            %------------------------------------------------------------------------------
            subsetTrain         = fileList( ismember( fileList.subjectTag, sub{iS} ) & ismember( fileList.condition, cond{iC} ) & ismember( fileList.run, allRuns(iRun) ), : );
            sessionDir          = fullfile(dataDir, subsetTrain.sessionDirectory{1});
            [dum, name, ext]    = fileparts( ls( fullfile(sessionDir, [subsetTrain.fileName{1} '*.bdf']) ) );
            filename            = strtrim( [name ext] );
            
            erpData             = eegDataset( sessionDir, filename );
            
            erpData.tBeforeOnset    = tBeforeOnset;
            erpData.tAfterOnset     = tAfterOnset;
            
            iT  = find(ismember(erpData.eventLabel, 'target'));
            iNT = find(ismember(erpData.eventLabel, 'nonTarget'));
            
            % filter the eeg data
            %------------------------------------------------------------------------------
            erpData.butterFilter( butterFilt.lowMargin, butterFilt.highMargin, butterFilt.order );
            
            % get cuts
            %------------------------------------------------------------------------------
            cuts = erpData.getCuts2(); % single( erpData.getCuts2() );
            cuts(:, ~ismember(1:erpData.nChan, erpData.eegChanInd), :) = [];
            
            % spatial filtering
            %------------------------------------------------------------------------------
            %             W = beamformerCFMS( cuts( :, :, erpData.eventId == iT ), cuts( :, :, erpData.eventId == iNT ), nSPcomp, 1 );
            nSPcomp = size(cuts, 2);
            W = eye( nSPcomp );
            newCuts = zeros( size(cuts, 1), nSPcomp, size(cuts, 3) ); % , 'single' );
            for iTr = 1:size(cuts, 3)
                newCuts( :, :, iTr ) = cuts( :, :, iTr ) * W;
            end
            clear cuts
            
            % downsample
            %------------------------------------------------------------------------------
            DSF = erpData.fs / targetFS;
            if DSF ~= floor(DSF), error('something wrong with the sampling rate'); end
            if DSF == 1
                cuts_DS = newCuts;
            else
                nbins = floor( size(newCuts, 1) / DSF );
                cuts_DS = zeros( nbins, size(newCuts, 2), size(newCuts, 3) ); % , 'single' );
                for i = 1:nbins
                    cuts_DS(i,:,:) = mean( newCuts( (i-1)*DSF+1:i*DSF, :, : ), 1 );
                end
            end
            clear newCuts
            SigTrainT   = zeros( size(cuts_DS, 1), size(cuts_DS, 2), nT_train_perCond ); %, 'single' );
            SigTrainNT  = zeros( size(cuts_DS, 1), size(cuts_DS, 2), nNT_train_perCond ); %, 'single' );
            
            indTargetEvents = find( erpData.eventId == iT );
            
            % restrict the number of available indices in order to be fair with the baseline condition
            subsetInd       = randperm( numel(indTargetEvents) );
            nIndsToKeep     = round( numel(indTargetEvents) / nCond );
            indTargetEvents = indTargetEvents( subsetInd(1:nIndsToKeep) );
            
            for i = 1:nT_train_perCond
                selection           = randperm( numel(indTargetEvents) );
                selection           = selection(1:iAve);
                SigTrainT(:,:,i)    = mean( cuts_DS( :, :, indTargetEvents(selection) ), 3 );
            end
            
            indNonTargetEvents = find( erpData.eventId == iNT );
            for i = 1:nNT_train_perCond
                selection           = randperm( numel(indNonTargetEvents) );
                selection           = selection(1:iAve);
                SigTrainNT(:,:,i)   = mean( cuts_DS( :, :, indNonTargetEvents(selection) ), 3 );
            end
            %             clear cuts_DS
            
            % reshape
            %------------------------------------------------------------------------------
            featTrain_T{iC}  = reshape(SigTrainT, size(SigTrainT,1)*size(SigTrainT,2), size(SigTrainT,3))';
            featTrain_NT{iC} = reshape(SigTrainNT, size(SigTrainNT,1)*size(SigTrainNT,2), size(SigTrainNT,3))';
            clear SigTrainT SigTrainNT
            
        end
        
        sizesT = unique( cell2mat( cellfun(@(x) size(x, 2), featTrain_T, 'UniformOutput', false) ) );
        sizesNT = unique( cell2mat( cellfun(@(x) size(x, 2), featTrain_NT, 'UniformOutput', false) ) );
        if numel( sizesT ) ~= 1, error('run %d, feature spaces across conditions have different dimensions', iRun); end
        if numel( sizesNT ) ~= 1, error('run %d, feature spaces across conditions have different dimensions', iRun); end
        if ~isequal( sizesT, sizesNT ), error('run %d, feature spaces across conditions have different dimensions for target and non-target', iRun); end
        
        featTrain_T_pool = zeros( nCond*nT_train_perCond, sizesT );
        featTrain_NT_pool = zeros( nCond*nNT_train_perCond, sizesNT );
        for  iC = 1:nCond
            featTrain_T_pool( (iC-1)*nT_train_perCond+1:iC*nT_train_perCond, :) = featTrain_T{iC};
            featTrain_NT_pool( (iC-1)*nT_train_perCond+1:iC*nT_train_perCond, :) = featTrain_NT{iC};
        end

        %================================================================================================================================
        %  TRAIN THE SVM
        %================================================================================================================================
            
        % normalization
        %------------------------------------------------------------------------------
        Xtrain = [featTrain_T_pool ; featTrain_NT_pool];
        Ytrain = [ones(nCond*nT_train_perCond,1); -ones(nCond*nNT_train_perCond,1)];
        clear featTrain_T featTrain_NT
        
        maxx    = max(Xtrain);
        minx   = min(Xtrain);
        %             Xtrain  = (Xtrain - repmat(minxx,size(Xtrain,1),1)) ./ repmat(maxx-minxx,size(Xtrain,1),1);
        Xtrain  = bsxfun(@minus, Xtrain, minx);
        Xtrain  = bsxfun(@rdivide, Xtrain, maxx-minx);
        
        % train the SVM
        %------------------------------------------------------------------------------
        nfolds      = 10;	% Number of subsets for the cross-validation
        igam        = 1;    % Central value of the regularization paramter for the first line search
        B_init      = [];
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
        
        % save classifier for run iRun and iAve averages
        %------------------------------------------------------------------------------
        classifierFilename  = fullfile( resDir, sprintf('pooledSvm-run%d-%.2dAverages.mat', iRun, iAve) );
        save( classifierFilename, 'butterFilt', 'W', 'targetFS', 'maxx', 'minx', 'B', 'tBeforeOnset', 'tAfterOnset', 'nSPcomp' );
        
    end
    
end


end