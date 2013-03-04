function [timeSequential, timeParFor, timeSpmd] = parallelClassif2

allJobs = get(findResource, 'Jobs'); 
if ~isempty(allJobs), destroy(allJobs); end

if matlabpool('size') > 0
    matlabpool close
end


%% =========================================================================================================

hostName = lower( strtok( getenv( 'COMPUTERNAME' ), '.') );

switch hostName,
    case 'kuleuven-24b13c',
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciData\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciData\watchERP\';
    otherwise,
        error('host not recognized');
end

%% =========================================================================================================

TableName   = '..\01-preprocess-plot\watchErpDataset2.xlsx';
fileList    = dataset('XLSFile', TableName);

nSub    = numel( unique( fileList.subjectTag ) );
nCond   = numel(unique( fileList.condition ) );
nAveMax = 10;

nIterations = nSub*nCond*nAveMax;
iSlist      = 1;%zeros(nIterations, 1);
iClist      = 1;%zeros(nIterations, 1);
iAvelist    = 1;%zeros(nIterations, 1);
% indList     = (1:nIterations)';

ind = 1;
for iS = 1:nSub
    for iC = 1:nCond
        for iAve = 1:nAveMax
            iSlist(ind)     = iS;
            iClist(ind)     = iC;
            iAvelist(ind)   = iAve;
            ind = ind+1;
        end
    end
end



%% =====================================================================================

% fprintf('\nPARALLEL EXECUTION (with scheduler and job): ');
% tic
% 
sched           = findResource('scheduler', 'type', 'local');
nLabs           = sched.ClusterSize;
% nLabs           = str2double( getenv('NUMBER_OF_PROCESSORS') );
nIndPerLabMin   = floor(nIterations / nLabs);
nIndLeft        = nIterations - nLabs*nIndPerLabMin;
nIndPerLab      = nIndPerLabMin*ones(1, nLabs);
nIndPerLab(1:nIndLeft) = nIndPerLab(1:nIndLeft) + 1;

inputArg = cell(1, nLabs);
temp = [ 1 , nIndPerLab ];
for iLab = 1:nLabs

    i1 = sum(temp(1:iLab));
    i2 = sum(nIndPerLab(1:iLab));
    inputArg{iLab} = { iSlist(i1:i2), iClist(i1:i2), iAvelist(i1:i2) };

end
% 
% job     = createJob(sched);
% task    = createTask(job, @p3Classif_crossValTrainSession_fct, 0, inputArg);
% submit(job);
% waitForState(job, 'finished');
% results = getAllOutputArguments(job);
% for iLab = 1:nLabs
%     fprintf('\ntask %d: start time: %s finish time: %s', iLab, get(task(iLab),'StartTime'), get(task(iLab),'FinishTime'))
% end
% destroy(job)
% 
% timeParallel = toc;
% fprintf('\n total time = %d seconds\n', timeParallel);

% % % % %% =====================================================================================
% % % % fprintf('\nDFEVAL EXECUTION: ');
% % % % tic
% % % % [subject, condition, nAverages, accuracy, nCorrect,nCued] = dfeval( ...
% % % %     @p3Classif_crossValTrainSession_fct ...
% % % %     , cellfun(@(x) x(1), inputArg) ...
% % % %     , cellfun(@(x) x(2), inputArg) ...
% % % %     , cellfun(@(x) x(3), inputArg) ...
% % % %     , 'JobManager', 'sched');
% % % % tDfeval = toc;
% % % % fprintf('\n total time = %d seconds\n', tDfeval);

%% =====================================================================================
% 
% fprintf('\nPARFOR EXECUTION: ');
% tic
% subjectPF     = cell(nIterations, 1);
% conditionPF   = cell(nIterations, 1);
% nAveragesPF   = zeros(nIterations, 1);
% accuracyPF    = zeros(nIterations, 1);
% nCorrectPF    = zeros(nIterations, 1);
% nCuedPF       = zeros(nIterations, 1);
% matlabpool
% parfor i = 1:nIterations
%     [subjectPF(i), conditionPF(i), nAveragesPF(i), accuracyPF(i), nCorrectPF(i), nCuedPF(i)] = p3Classif_crossValTrainSession_fct(iSlist(i), iClist(i), iAvelist(i));
% end
% matlabpool close
% timeParFor = toc;
% fprintf('\n total time = %d seconds\n', timeParFor);
% 

%% =====================================================================================

fprintf('\nSPMD EXECUTION: ');

sched           = findResource('scheduler', 'type', 'local');
nLabs           = sched.ClusterSize;
nIndPerLabMin   = floor(nIterations / nLabs);
nIndLeft        = nIterations - nLabs*nIndPerLabMin;
nIndPerLab      = nIndPerLabMin*ones(1, nLabs);
nIndPerLab(1:nIndLeft) = nIndPerLab(1:nIndLeft) + 1;

inputArg = cell(1, nLabs);
temp = [ 1 , nIndPerLab ];
for iLab = 1:nLabs

    i1 = sum(temp(1:iLab));
    i2 = sum(nIndPerLab(1:iLab));
    inputArg{iLab} = { iSlist(i1:i2), iClist(i1:i2), iAvelist(i1:i2) };

end


tic
subjectSPMD     = cell(nIterations, 1);
conditionSPMD   = cell(nIterations, 1);
nAveragesSPMD   = zeros(nIterations, 1);
accuracySPMD    = zeros(nIterations, 1);
nCorrectSPMD    = zeros(nIterations, 1);
nCuedSPMD       = zeros(nIterations, 1);
matlabpool(nLabs)
spmd (nLabs)
    [subject, condition, nAverages, accuracy, nCorrect,nCued] = p3Classif_crossValTrainSession_fct( inputArg{labindex}{:} );
end
temp = [ 1 , nIndPerLab ];
for i = 1:nLabs
    i1 = sum(temp(1:i));
    i2 = sum(nIndPerLab(1:i));
    subjectSPMD(i1:i2)      = subject{i};
    conditionSPMD(i1:i2)    = condition{i};
    nAveragesSPMD(i1:i2)    = nAverages{i};
    accuracySPMD(i1:i2)     = accuracy{i};
    nCorrectSPMD(i1:i2)     = nCorrect{i};
    nCuedSPMD(i1:i2)        = nCued{i};
end
matlabpool close
timeSpmd = toc;
fprintf('\n total time = %d seconds\n', timeSpmd);

resultsSPMD = dataset( ...
    {subjectSPMD, 'subject'} ...
    ,{conditionSPMD, 'condition'} ...
    ,{nAveragesSPMD, 'nAverages'} ...
    ,{accuracySPMD, 'accuracy'} ...
    ,{nCorrectSPMD, 'nCorrect'} ...
    ,{nCuedSPMD, 'nCued'} ...
    );

save('resultsSPMD.mat', 'resultsSPMD', 'timeSpmd');


%% =====================================================================================
 
fprintf('\nSEQUENTIAL EXECUTION: ');
tic
[subjectSeq, conditionSeq, nAveragesSeq, accuracySeq, nCorrectSeq, nCuedSeq] = p3Classif_crossValTrainSession_fct(iSlist, iClist, iAvelist);
timeSequential = toc;
fprintf('time = %d seconds\n', timeSequential);

resultsSeq = dataset( ...
    {subjectSeq, 'subject'} ...
    ,{conditionSeq, 'condition'} ...
    ,{nAveragesSeq, 'nAverages'} ...
    ,{accuracySeq, 'accuracy'} ...
    ,{nCorrectSeq, 'nCorrect'} ...
    ,{nCuedSeq, 'nCued'} ...
    );

save('resultsSeq.mat', 'resultsSeq', 'timeSequential');

end




function [subject, condition, nAverages, accuracy, nCorrect, nCued] = p3Classif_crossValTrainSession_fct(iSL, iCL, iAveL)

if numel(iSL) ~= numel(iCL) || numel(iSL) ~= numel(iAveL)
    error('iSL, iCL and iAveL must have the number of elements');
end

%% =========================================================================================================

hostName = lower( strtok( getenv( 'COMPUTERNAME' ), '.') );

switch hostName,
    case 'kuleuven-24b13c',
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciData\watchERP\';
    case 'neu-wrk-0158',
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciData\watchERP\';
    otherwise,
        error('host not recognized');
end

%% =========================================================================================================

% TableName   = '..\01-preprocess-plot\watchErpDataset.xlsx';
TableName   = '..\01-preprocess-plot\watchErpDataset2.xlsx';
fileList    = dataset('XLSFile', TableName);

nfolds      = 10;	% Number of subsets for the cross-validation
igam        = 1;    % Central value of the regularization paramter for the first line search
B_init      = [];
error_type  = 1;    % 1: calculate mean square error on misclassified data
                    % 2: calculate mean square error on active data (data that are not beyond the margin...even if correctly classified)

sub     = unique( fileList.subjectTag );
cond    = unique( fileList.condition );
nSub    = numel(sub);
nCond   = numel(cond);
nAveMax = 10;

if max(iSL) > nSub, error('invalid subject index'); end
if max(iCL) > nCond, error('invalid condition index'); end

tBeforeOnset = 0;
tAfterOnset = .8;
nSPcomp = 4;

subject     = cell(numel(iSL), 1);
condition   = cell(numel(iSL), 1);
nAverages   = zeros(numel(iSL), 1);
accuracy    = zeros(numel(iSL), 1);
nCorrect    = zeros(numel(iSL), 1);
nCued       = zeros(numel(iSL), 1);

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
        
        % spatial filtering
        %------------------------------------------------------------------------------
%         W = beamformerCFMS( cuts( :, :, erpData.eventId == iT ), cuts( :, :, erpData.eventId == iNT ), nSPcomp, 1 );
        nSPcomp = size(cuts, 2);
        W = eye( nSPcomp );
        newCuts = zeros( size(cuts, 1), nSPcomp, size(cuts, 3) ); % , 'single' );
        for iTr = 1:size(cuts, 3)
            newCuts( :, :, iTr ) = cuts( :, :, iTr ) * W;
        end
        
        clear cuts
        
        % downsample
        %------------------------------------------------------------------------------
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
        clear cuts_DS
        
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
        minxx   = min(Xtrain);
        %             Xtrain  = (Xtrain - repmat(minxx,size(Xtrain,1),1)) ./ repmat(maxx-minxx,size(Xtrain,1),1);
        Xtrain  = bsxfun(@minus, Xtrain, minxx);
        Xtrain  = bsxfun(@rdivide, Xtrain, maxx-minxx);
        
        % train the SVM
        %------------------------------------------------------------------------------        
        ntrain      = size(Xtrain,1);
        Xtrain      = [Xtrain ones(ntrain,1)];
        Xtrain      = Xtrain; % double( Xtrain );
        
        [B_init iter_init]  = Lin_SVM_Keerthi(Xtrain,Ytrain,B_init,igam);
        linesearch_algo;
        close all
        best_gamma          = exp(Xm);
        [B_new iter_final]  = Lin_SVM_Keerthi(Xtrain,Ytrain,B_init,best_gamma);
        
        clear Xtrain
        
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
            targetFS = 128;
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
            
            % reshape
            %------------------------------------------------------------------------------
            featTest     = reshape(cuts_DS, size(cuts_DS,1)*size(cuts_DS,2), size(cuts_DS,3))';
            clear cuts_DS
            
            % normalization
            %------------------------------------------------------------------------------
            %             Xtest  = (Xtrain - repmat(minxx,size(featTest,1),1)) ./ repmat(maxx-minxx,size(featTest,1),1);
            Xtest       = bsxfun(@minus, featTest, minxx);
            Xtest       = bsxfun(@rdivide, Xtest, maxx-minxx);
            clear featTest
            
            % Apply classifier
            %------------------------------------------------------------------------------
            Xtest       = [Xtest ones(size(Xtest, 1),1)];
            YlatTest    = Xtest*B_new;
            clear Xtest
            
            % compare winner icon with target icon and update results
            %------------------------------------------------------------------------------
            for iCue = 1:nCues
                
                [ dum winner ]  = max( YlatTest( (iCue-1)*nIcons+1 : iCue*nIcons ) );
                nCorrectii        = nCorrectii + ( winner == targetIcon(iCue) );
                
            end
            nCuedii = nCuedii + nCues;
        end
        
    end
    
    
    subject{ii}     = sub{iS};
    condition{ii}   = cond{iC};
    nAverages(ii)   = iAve;
    accuracy(ii)    = 100*nCorrectii/nCuedii;
    nCorrect(ii)    = nCorrectii;
    nCued(ii)       = nCuedii;
        
end

end