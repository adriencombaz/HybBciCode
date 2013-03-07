function p3Classif_blda

hostName = lower( strtok( getenv( 'COMPUTERNAME' ), '.') );

switch hostName,
    case 'kuleuven-24b13c',
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
    otherwise,
        error('host not recognized');
end

% TableName   = '..\01-preprocess-plot\watchErpDataset.xlsx';
TableName   = '..\01-preprocess-plot\watchErpDataset2.xlsx';
fileList    = dataset('XLSFile', TableName);

iSubs   = 1;    % 1:numel( unique( fileList.subjectTag ) );
iConds  = 1;    % 1:numel( unique( fileList.condition ) );
iAves   = 1:10;   % 1:10;

nSub    = numel( iSubs );
nCond   = numel(iConds );
nAveMax = numel( iAves );

nIterations = nSub*nCond*nAveMax;
iSlist      = zeros(nIterations, 1);
iClist      = zeros(nIterations, 1);
iAvelist    = zeros(nIterations, 1);

ind = 1;
for iS = 1:nSub
    for iC = 1:nCond
        for iAve = 1:nAveMax
            iSlist(ind)     = iSubs( iS );
            iClist(ind)     = iConds( iC );
            iAvelist(ind)   = iAves( iAve );
            ind = ind+1;
        end
    end
end

classifyData(iSlist, iClist, iAvelist, TableName);

end

%% =========================================================================================================
%% =========================================================================================================
%% =========================================================================================================
%% =========================================================================================================
%% =========================================================================================================


function classifyData(iSL, iCL, iAveL, TableName)


if numel(iSL) ~= numel(iCL) || numel(iSL) ~= numel(iAveL)
    error('iSL, iCL and iAveL must have the number of elements');
end

%% =========================================================================================================

hostName = lower( strtok( getenv( 'COMPUTERNAME' ), '.') );

switch hostName,
    case 'kuleuven-24b13c',
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
    case 'neu-wrk-0158',
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
    otherwise,
        error('host not recognized');
end

%% =========================================================================================================

fileList    = dataset('XLSFile', TableName);

sub     = unique( fileList.subjectTag );
cond    = unique( fileList.condition );
nSub    = numel(sub);
nCond   = numel(cond);
nAveMax = 10;

if max(iSL) > nSub, error('invalid subject index'); end
if max(iCL) > nCond, error('invalid condition index'); end

resFilename = sprintf( 'Results_blda_sub%dto%d_cond%dto%d_ave%dto%d.txt', min(iSL), max(iSL), min(iCL), max(iCL), min(iAveL), max(iAveL) );
resDir = fullfile(cd, 'bldaResults');
if ~exist(resDir, 'dir'), mkdir(resDir); end
fid = fopen( fullfile(resDir, resFilename), 'wt' );
% fid = fopen('Results.txt','at');
fprintf(fid, 'subject, condition, nAverages, accuracy, nCorrect, nCued\n');

tBeforeOnset = 0;
tAfterOnset = .6;
nSPcomp = 4;

for ii = 1:numel(iSL)
    
    iS = iSL(ii);
    iC = iCL(ii);
    iAve = iAveL(ii);
    
    nCorrectii    = 0;
    nCuedii       = 0;

            subset = fileList( ismember( fileList.subjectTag, sub{iS} ) & ismember( fileList.condition, cond{iC} ), : );
            
            runIds = unique( subset.run );
            nRuns = numel( runIds );
            
            for iRunTrain = 1:nRuns
                                
                %==============================================================================
                %==============================================================================
                
                %% train the classifier on run nb 1
                
                %==============================================================================
                %==============================================================================
                
                % read data
                %------------------------------------------------------------------------------
                subsetTrain = subset( ismember( subset.run, iRunTrain ), : );
                sessionDir  = fullfile(dataDir, subsetTrain.sessionDirectory{1});
                filename    = ls(fullfile(sessionDir, [subsetTrain.fileName{1} '*.bdf']));
                erpData     = eegDataset( sessionDir, filename );
                
                erpData.tBeforeOnset = tBeforeOnset;
                erpData.tAfterOnset = tAfterOnset;
                
                iT  = find(ismember(erpData.eventLabel, 'target'));
                iNT = find(ismember(erpData.eventLabel, 'nonTarget'));
                
                % filter the eeg data
                %------------------------------------------------------------------------------
                erpData.butterFilter(.5, 30, 3);
                
                % get cuts
                %------------------------------------------------------------------------------
                cuts = erpData.getCuts2(); % single( erpData.getCuts2() );
                cuts(:, ~ismember(1:erpData.nChan, erpData.eegChanInd), :) = [];
                
                % select channels
                %------------------------------------------------------------------------------
                
                
                
                % spatial filtering
                %------------------------------------------------------------------------------
%                 W = beamformerCFMS( cuts( :, :, erpData.eventId == iT ), cuts( :, :, erpData.eventId == iNT ), nSPcomp, 1 );
                nSPcomp = size(cuts, 2);
                W = eye( nSPcomp );
                newCuts = zeros( size(cuts, 1), nSPcomp, size(cuts, 3) ); % , 'single' );
                for iTr = 1:size(cuts, 3)
                    newCuts( :, :, iTr ) = cuts( :, :, iTr ) * W;
                end
                clear cuts
                
                % downsample
                %------------------------------------------------------------------------------
%                 targetFS = 64;
                targetFS = 128;
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
                
                % select/balance/average trials w.r.t. the desired number of repetitions
                %------------------------------------------------------------------------------
% % % %                 if iAve == 1
% % % %                     SigTrainT   = cuts_DS(:, :,erpData.eventId == iT);
% % % %                     SigTrainNT  = cuts_DS(:, :,erpData.eventId == iNT);
% % % %                     nT_train    = size(SigTrainT, 3);
% % % %                     nNT_train   = size(SigTrainNT, 3);
% % % %                 else
% % % %                     
% % % %                     indTargetEvents = find( erpData.eventId == iT );
% % % %                     nT_train        = floor( numel( indTargetEvents ) / iAve );
% % % %                     SigTrainT       = zeros( size(cuts_DS, 1), size(cuts_DS, 2), nT_train );
% % % %                     randInds        = indTargetEvents( randperm( numel( indTargetEvents ) ) );
% % % %                     for i = 1:nT_train
% % % %                         inds                = randInds( (i-1)*iAve+1 : i*iAve );
% % % %                         SigTrainT(:,:,i)    = mean( cuts_DS( :, :, inds ), 3 );
% % % %                     end
% % % %                     
% % % %                     indNonTargetEvents  = find( erpData.eventId == iNT );
% % % %                     nNT_train           = floor( numel( indNonTargetEvents ) / iAve );
% % % %                     SigTrainNT          = zeros( size(cuts_DS, 1), size(cuts_DS, 2), nNT_train );
% % % %                     randInds            = indNonTargetEvents( randperm( numel( indNonTargetEvents ) ) );
% % % %                     for i = 1:nNT_train
% % % %                         inds                = randInds( (i-1)*iAve+1 : i*iAve );
% % % %                         SigTrainNT(:,:,i)   = mean( cuts_DS( :, :, inds ), 3 );
% % % %                     end
% % % %                     
% % % %                 end
% % % %                 clear cuts_DS
                
                
                if iAve == 1
                    SigTrainT   = cuts_DS(:, :,erpData.eventId == iT);
                    SigTrainNT  = cuts_DS(:, :,erpData.eventId == iNT);
                    nT_train    = size(SigTrainT, 3);
                    nNT_train   = size(SigTrainNT, 3);
                else
                    nT_train    = 1000;
                    nNT_train   = 1000;
                    SigTrainT   = zeros( size(cuts_DS, 1), size(cuts_DS, 2), nT_train ); %, 'single' );
                    SigTrainNT  = zeros( size(cuts_DS, 1), size(cuts_DS, 2), nNT_train ); %, 'single' );
                    
                    indTargetEvents = find( erpData.eventId == iT );
                    for i = 1:nT_train
                        selection           = randperm( numel(indTargetEvents) );
                        selection           = selection(1:iAve);
                        SigTrainT(:,:,i)    = mean( cuts_DS( :, :, indTargetEvents(selection) ), 3 );
                    end
                    
                    indNonTargetEvents = find( erpData.eventId == iNT );
                    for i = 1:nNT_train
                        selection           = randperm( numel(indNonTargetEvents) );
                        selection           = selection(1:iAve);
                        SigTrainNT(:,:,i)   = mean( cuts_DS( :, :, indNonTargetEvents(selection) ), 3 );
                    end
                end
                clear cuts_DS
                
                
                % winsorize, normalize and train the bayesian lda
                %------------------------------------------------------------------------------
                xTrain = cat(3, SigTrainT, SigTrainNT);
                xTrain = permute(xTrain, [2 1 3]);
                
                w = windsor;
                w = train(w,xTrain,0.1);
                xTrain = apply(w,xTrain);
                
                n = normalize;
                n = train(n,xTrain,'minmax');
                xTrain = apply(n,xTrain);

                xTrain = reshape(xTrain, size(xTrain,2)*size(xTrain,1),size(xTrain,3)); % size: nSamples*nChannels by nTrials
                yTrain = [ones(1, nT_train) -ones(1, nNT_train)];
                b = bayeslda(1);
                b = train(b, xTrain, yTrain);
                
                
% % % % %                 % reshape
% % % % %                 %------------------------------------------------------------------------------
% % % % %                 featTrain_T     = reshape(SigTrainT, size(SigTrainT,1)*size(SigTrainT,2), size(SigTrainT,3))';
% % % % %                 featTrain_NT    = reshape(SigTrainNT, size(SigTrainNT,1)*size(SigTrainNT,2), size(SigTrainNT,3))';
% % % % %                 clear SigTrainT SigTrainNT
% % % % %                 
% % % % %                 % normalization
% % % % %                 %------------------------------------------------------------------------------
% % % % %                 xTrain = [featTrain_T ; featTrain_NT];
% % % % %                 yTrain = [ones(nT_train,1); -ones(nNT_train,1)];
% % % % %                 clear featTrain_T featTrain_NT
% % % % %                 
% % % % %                 maxx    = max(xTrain);
% % % % %                 minxx   = min(xTrain);
% % % % %                             xTrain  = (xTrain - repmat(minxx,size(xTrain,1),1)) ./ repmat(maxx-minxx,size(xTrain,1),1);
% % % % %                 xTrain  = bsxfun(@minus, xTrain, minxx);
% % % % %                 xTrain  = bsxfun(@rdivide, xTrain, maxx-minxx);
% % % % %                 
% % % % %                 xTrain = xTrain';
% % % % %                 yTrain = yTrain';
% % % % %                 b = bayeslda(1);
% % % % %                 b = train(b, xTrain, yTrain);

                
% % % % % % % % % % % % % % % % % % % % % % %                 % reshape
% % % % % % % % % % % % % % % % % % % % % % %                 %------------------------------------------------------------------------------
% % % % % % % % % % % % % % % % % % % % % % %                 featTrain_T     = reshape(SigTrainT, size(SigTrainT,1)*size(SigTrainT,2), size(SigTrainT,3))';
% % % % % % % % % % % % % % % % % % % % % % %                 featTrain_NT    = reshape(SigTrainNT, size(SigTrainNT,1)*size(SigTrainNT,2), size(SigTrainNT,3))';
% % % % % % % % % % % % % % % % % % % % % % %                 clear SigTrainT SigTrainNT
% % % % % % % % % % % % % % % % % % % % % % %                 
% % % % % % % % % % % % % % % % % % % % % % %                 % normalization
% % % % % % % % % % % % % % % % % % % % % % %                 %------------------------------------------------------------------------------
% % % % % % % % % % % % % % % % % % % % % % %                 Xtrain = [featTrain_T ; featTrain_NT];
% % % % % % % % % % % % % % % % % % % % % % %                 Ytrain = [ones(nT_train,1); -ones(nNT_train,1)];
% % % % % % % % % % % % % % % % % % % % % % %                 clear featTrain_T featTrain_NT
% % % % % % % % % % % % % % % % % % % % % % %                 
% % % % % % % % % % % % % % % % % % % % % % %                 maxx    = max(Xtrain);
% % % % % % % % % % % % % % % % % % % % % % %                 minxx   = min(Xtrain);
% % % % % % % % % % % % % % % % % % % % % % %                 %             Xtrain  = (Xtrain - repmat(minxx,size(Xtrain,1),1)) ./ repmat(maxx-minxx,size(Xtrain,1),1);
% % % % % % % % % % % % % % % % % % % % % % %                 Xtrain  = bsxfun(@minus, Xtrain, minxx);
% % % % % % % % % % % % % % % % % % % % % % %                 Xtrain  = bsxfun(@rdivide, Xtrain, maxx-minxx);
% % % % % % % % % % % % % % % % % % % % % % %                 
% % % % % % % % % % % % % % % % % % % % % % %                 % train the SVM
% % % % % % % % % % % % % % % % % % % % % % %                 %------------------------------------------------------------------------------
% % % % % % % % % % % % % % % % % % % % % % %                 nfolds      = 10;	% Number of subsets for the cross-validation
% % % % % % % % % % % % % % % % % % % % % % %                 igam        = 1;    % Central value of the regularization paramter for the first line search
% % % % % % % % % % % % % % % % % % % % % % %                 B_init      = [];
% % % % % % % % % % % % % % % % % % % % % % %                 error_type  = 1;    % 1: calculate mean square error on misclassified data
% % % % % % % % % % % % % % % % % % % % % % %                                     % 2: calculate mean square error on active data (data that are not beyond the margin...even if correctly classified)
% % % % % % % % % % % % % % % % % % % % % % %                 
% % % % % % % % % % % % % % % % % % % % % % %                 ntrain      = size(Xtrain,1);
% % % % % % % % % % % % % % % % % % % % % % %                 Xtrain      = [Xtrain ones(ntrain,1)];
% % % % % % % % % % % % % % % % % % % % % % %                 Xtrain      = Xtrain; % double( Xtrain );
% % % % % % % % % % % % % % % % % % % % % % %                 
% % % % % % % % % % % % % % % % % % % % % % %                 [B_init iter_init]  = Lin_SVM_Keerthi(Xtrain,Ytrain,B_init,igam);
% % % % % % % % % % % % % % % % % % % % % % %                 linesearch_algo;
% % % % % % % % % % % % % % % % % % % % % % %                 close all
% % % % % % % % % % % % % % % % % % % % % % %                 best_gamma          = exp(Xm);
% % % % % % % % % % % % % % % % % % % % % % %                 [B_new iter_final]  = Lin_SVM_Keerthi(Xtrain,Ytrain,B_init,best_gamma);
% % % % % % % % % % % % % % % % % % % % % % %                 
% % % % % % % % % % % % % % % % % % % % % % %                 clear Xtrain
                
                %==============================================================================
                %==============================================================================
                
                %% test the classifier on remaining runs
                
                %==============================================================================
                %==============================================================================
                
                subsetTest = subset( ~ismember( subset.run, iRunTrain ), : );
                
                for iRunTest = 1:size( subsetTest, 1 )
                    
                    % read data
                    %------------------------------------------------------------------------------
                    subsetTesti = subsetTest( iRunTest, : );
                    sessionDir  = fullfile(dataDir, subsetTesti.sessionDirectory{1});
                    filename    = ls(fullfile(sessionDir, [subsetTesti.fileName{1} '*.bdf']));
                    erpData     = eegDataset( sessionDir, filename );
                    
                    erpData.tBeforeOnset = tBeforeOnset;
                    erpData.tAfterOnset = tAfterOnset;
                    
                    % read experiment parameters
                    %------------------------------------------------------------------------------
                    paramFile   = ls(fullfile(sessionDir, [subsetTesti.fileName{1} '*.mat']));
                    pars        = load( fullfile(sessionDir,paramFile), 'nCuesToShow', 'nRepetitions', 'lookHereStateSeq', 'realP3StateSeqOnsets' );
                    
                    nCues   = pars.nCuesToShow;
                    nReps   = pars.nRepetitions;
                    if nReps < iAve, error('number of repetitions used during the experiment is lower than the desired number of averages'); end
                    nIcons  = 6;
                    targetIcon = pars.lookHereStateSeq( pars.lookHereStateSeq <= nIcons );
                    flashSequence = pars.realP3StateSeqOnsets;
                    
                    
                    % filter the eeg data
                    %------------------------------------------------------------------------------
                    erpData.butterFilter(.5, 30, 3);
                    
                    % get cuts
                    %------------------------------------------------------------------------------
                    cuts = erpData.getCuts2(); % single( erpData.getCuts2() );
                    cuts(:, ~ismember(1:erpData.nChan, erpData.eegChanInd), :) = [];
                    
                    % select and average trials
                    %------------------------------------------------------------------------------
                    meanCuts = zeros( size(cuts, 1), size(cuts, 2), nIcons*nCues ); %, 'single' );
                    for iCue = 1:nCues
                        
                        iStart      = (iCue-1)*nIcons*nReps;
                        indEvents   = iStart + (1:nIcons*nReps);
                        
                        for iIcon = 1:nIcons
                            
                            iIconFlashes = iStart + find( flashSequence(indEvents) == iIcon, iAve, 'first' );
                            meanCuts( :, :, (iCue-1)*nIcons + iIcon ) = mean( cuts( :, :, iIconFlashes ), 3 );
                            
                        end
                    end
                    clear cuts
                    
                    % spatial filtering
                    %------------------------------------------------------------------------------
                    newCuts = zeros( size(meanCuts, 1), nSPcomp, size(meanCuts, 3) ); %, 'single' );
                    for iTr = 1:size(meanCuts, 3)
                        newCuts( :, :, iTr ) = meanCuts( :, :, iTr ) * W;
                    end
                    clear meanCuts
                    
                    % downsample
                    %------------------------------------------------------------------------------
%                     targetFS = 128;
                    DSF = erpData.fs / targetFS;
                    if DSF ~= floor(DSF), error('something wrong with the sampling rate'); end
                    if DSF == 1
                        cuts_DS = newCuts;
                    else
                        nbins = floor( size(newCuts, 1) / DSF );
                        cuts_DS = zeros( nbins, size(newCuts, 2), size(newCuts, 3) ); %, 'single' );
                        for i = 1:nbins
                            cuts_DS(i,:,:) = mean( newCuts( (i-1)*DSF+1:i*DSF, :, : ), 1 );
                        end
                    end
                    clear newCuts
                    
                    
                    xTest = permute(cuts_DS, [2 1 3]);
                    xTest = apply(w, xTest);
                    xTest = apply(n, xTest);
                    xTest = reshape(xTest, size(xTest, 2)*size(xTest, 1), size(xTest, 3));
                    YlatTest = classify(b,xTest);
                    
                    
% % % % % % % % % % % % % % % % % % % % % % % %                     % reshape
% % % % % % % % % % % % % % % % % % % % % % % %                     %------------------------------------------------------------------------------
% % % % % % % % % % % % % % % % % % % % % % % %                     featTest     = reshape(cuts_DS, size(cuts_DS,1)*size(cuts_DS,2), size(cuts_DS,3))';
% % % % % % % % % % % % % % % % % % % % % % % %                     clear cuts_DS
% % % % % % % % % % % % % % % % % % % % % % % %                     
% % % % % % % % % % % % % % % % % % % % % % % %                     % normalization
% % % % % % % % % % % % % % % % % % % % % % % %                     %------------------------------------------------------------------------------
% % % % % % % % % % % % % % % % % % % % % % % %                     %             Xtest  = (Xtrain - repmat(minxx,size(featTest,1),1)) ./ repmat(maxx-minxx,size(featTest,1),1);
% % % % % % % % % % % % % % % % % % % % % % % %                     Xtest       = bsxfun(@minus, featTest, minxx);
% % % % % % % % % % % % % % % % % % % % % % % %                     Xtest       = bsxfun(@rdivide, Xtest, maxx-minxx);
% % % % % % % % % % % % % % % % % % % % % % % %                     clear featTest
% % % % % % % % % % % % % % % % % % % % % % % %                     
% % % % % % % % % % % % % % % % % % % % % % % %                     % Apply classifier
% % % % % % % % % % % % % % % % % % % % % % % %                     %------------------------------------------------------------------------------
% % % % % % % % % % % % % % % % % % % % % % % %                     Xtest       = [Xtest ones(size(Xtest, 1),1)];
% % % % % % % % % % % % % % % % % % % % % % % %                     YlatTest    = Xtest*B_new;
% % % % % % % % % % % % % % % % % % % % % % % %                     clear Xtest
                    
                    % compare winner icon with target icon and update results
                    %------------------------------------------------------------------------------
                    for iCue = 1:nCues
                        
                        [ dum winner ]  = max( YlatTest( (iCue-1)*nIcons+1 : iCue*nIcons ) );
                        nCorrectii      = nCorrectii + ( winner == targetIcon(iCue) );
                        
                    end
                    nCuedii = nCuedii + nCues;
                end
                
            end
            
            fprintf(fid, '%s, %s, %d, %5.2f, %d, %d\n', ...
                sub{iS}, cond{iC}, iAve, 100*nCorrectii/nCuedii, nCorrectii, nCuedii);
            %             fprintf(fid, 'subject %s, %s condition, %d averages: accuracy %6.3f%% (%d out %d)\n', ...
            %                 sub{iS}, cond{iC}, iAve, 100*nCorrect(iS, iC, iAve)/nCued(iS, iC, iAve), nCorrect(iS, iC, iAve), nCued(iS, iC, iAve) );
            
end

fclose(fid);


end