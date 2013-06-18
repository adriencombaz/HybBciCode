function applySvmClassifier_perSubject( iS, nRunsForTraining )

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
        resDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP_2stim\02--classify-erps-one-classifier-per-stimFreq\';
        codeDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP_2stim\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP_2stim\';
        resDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciProcessedData\watchERP_2stim\02--classify-erps-one-classifier-per-stimFreq\';
        codeDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP_2stim\';
    case {'sunny', 'solaris', ''}
        addpath( genpath( '~/PhD/hybridBCI-stuffs/deps/' ) );
        rmpath( genpath('~/PhD/hybridBCI-stuffs/deps/eeglab10_0_1_0b/external/SIFT_01_alpha') );
        dataDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/data/';
        resDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/results/02--classify-erps-one-classifier-per-stimFreq/';
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
sub         = unique( fileList.subjectTag );
fileList    = fileList( ismember( fileList.subjectTag, sub{iS} ), : );
resDir      = fullfile( resDir, sprintf('linSvm_%dRunsForTrain', nRunsForTraining), sprintf('subject_%s', sub{iS}) );
if ~exist( resDir, 'dir' ), mkdir(resDir); end

%--------------------------------------------------------------------------
run = unique( fileList.run );
if ~isequal(run(:), (1:max(run))'), error('wrong run numbering'); end
listTrainRuns = combntns(run, nRunsForTraining);
nCv = size(listTrainRuns, 1);
nTestPerCv = numel(run)-nRunsForTraining;
listTestRuns = zeros( nCv, nTestPerCv );
for iCv = 1:nCv
    listTestRuns(iCv, :) = run( ~ismember(run, listTrainRuns(iCv,:)) );
end

%--------------------------------------------------------------------------
nAveMax = 10;
tBeforeOnset = 0;
tAfterOnset = .6;
butterFilt.lowMargin = .5;
% butterFilt.highMargin = 30;
butterFilt.highMargin = 20;
butterFilt.order = 3;
targetFS = 128;
% nSquares = 2;
% nItemsPerSquare = 6;

%--------------------------------------------------------------------------
fid = fopen( fullfile( resDir, 'Results_forLogisiticRegression.txt' ),'wt' );
fprintf(fid, 'subject, foldInd, ');
for i = 1:nRunsForTraining
    fprintf(fid, 'trainingRun_%d, ', i);
end
fprintf(fid, 'testingRun, roundNb, nAverages, targetFrequency, correctness\n');

% nData = nCv*nTestPerCv*nAveMax*nSquares*nItemsPerSquare;
% subject         = cell(nData, 1);
% iFold           = zeros(nData, 1);
% trainingRuns    = cell(nData, 1);
% testingRun      = zeros(nData, 1);
% nAverages       = zeros(nData, 1);
% targetFrequency = nan(nData, 1);
% correctness     = nan(nData, 1);
% ind = 1;
% for iF = 1:nCv, 
%     for iT = 1:nTestPerCv, 
%         for iAve = 1:nAveMax,
%             for iSq = 1:nSquares
%                 for iItem = 1:nItemsPerSquare
%                     subject{ind}        = sub{iS};
%                     iFold(ind)          = iF;
%                     trainingRuns{ind}   = listTrainRuns(iF, :);
%                     testingRun(ind)     = listTestRuns(iF, iT);
%                     nAverages(ind)      = iAve;
%                     ind                 = ind+1;
%                 end
%             end
%         end
%     end
% end

%% ========================================================================================================
for iRunTest = 1:max(run)
   
    fprintf('subject %s, test run %d out of %d\n', ...
        sub{iS}, iRunTest, max(run));
    
    %% LOAD AND PROCESS THE EEG DATA
    %==============================================================================
    %==============================================================================
    
    %
    %--------------------------------------------------------------------------
    sessionDir      = fullfile(dataDir, fileList.sessionDirectory{iRunTest});
    [~, name, ext]  = fileparts( ls(fullfile(sessionDir, [fileList.fileName{iRunTest} '*.bdf'])) );
    filename        = strtrim( [name ext] );
    [~, name, ext]  = fileparts( ls(fullfile(sessionDir, [fileList.fileName{iRunTest}(1:19) '*.mat'])) );
    paramFile       = strtrim( [name ext] );
    pars            = load( fullfile(sessionDir,paramFile), 'nP3item', 'nCuesToShow', 'nRepetitions', 'lookHereStateSeq', 'realP3StateSeqOnsets', 'ssvepFreq', 'scenario' );
    
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
            cuts_proc = cuts;
        else
            nbins = floor( size(cuts, 1) / DSF );
            cuts_proc = zeros( nbins, size(cuts, 2), size(cuts, 3) ); % , 'single' );
            for i = 1:nbins
                cuts_proc(i,:,:) = mean( cuts( (i-1)*DSF+1:i*DSF, :, : ), 1 );
            end
        end
        
%         % get labels
%         %------------------------------------------------------------------------------
%         labels_cuts     = zeros(1, size(cuts, 3));
%         targetSquare    = zeros(1, size(cuts, 3));
        targetStateSeq  = pars.lookHereStateSeq( pars.lookHereStateSeq~=max(pars.lookHereStateSeq) );
%         tempp           = repmat( targetStateSeq, pars.nP3item*pars.nRepetitions, 1);
%         targetId        = tempp(:);
%         for iSq = 1:numel(pars.realP3StateSeqOnsets)
%             stimId = (iSq-1)*pars.nP3item + pars.realP3StateSeqOnsets{iSq};
%             labels_cuts( stimId(:) == targetId(:) ) = 1;
%             targetSquare( ismember(targetId, (iSq-1)*pars.nP3item+1:iSq*pars.nP3item) ) = iSq;
%         end
%         clear cuts
    
        
        %%
        %==============================================================================
        %==============================================================================
        [concernedFolds, ~, ~] = find(listTestRuns == iRunTest);
        
        for iF = concernedFolds'
            for iAve = 1:nAveMax
            
%                 fprintf('subject %s, test run %d out of %d, fold %d out of %d, %d ave out of %d\n', ...
%                     sub{iS}, iRunTest, max(run), find(concernedFolds==iF), numel(concernedFolds), iAve, nAveMax);
                                
                % 
                %------------------------------------------------------------------------------
%                 temp_correctness        = nan( pars.nCuesToShow, 1 );
%                 temp_targetFrequency    = nan( pars.nCuesToShow, 1 );
                for iCue = 1:pars.nCuesToShow
                
                    % 
                    %------------------------------------------------------------------------------
                    targetSymbol    = targetStateSeq( iCue );
                    targetSquare    = ceil( targetSymbol / pars.nP3item );
                    
                    % 
                    %------------------------------------------------------------------------------
                    meanCuts        = zeros(nbins, nChans, pars.nP3item);
                    indStart        = (iCue-1)*pars.nRepetitions*pars.nP3item;
                    indEvents       = indStart + (1:pars.nRepetitions*pars.nP3item);
                    for iIcon = 1:pars.nP3item
                        
                        iIconFlashes = indStart + find( pars.realP3StateSeqOnsets{targetSquare}(indEvents) == iIcon, iAve, 'first' );
                        meanCuts( :, :, iIcon ) = mean( cuts_proc( :, :, iIconFlashes ), 3 );
                        
                    end
                    
                    % reshape
                    %------------------------------------------------------------------------------
                    featTest     = reshape(meanCuts, size(meanCuts,1)*size(meanCuts,2), size(meanCuts,3))';
                    
                    % load the classifier
                    %------------------------------------------------------------------------------
                    classifierFilename  = fullfile( resDir, sprintf('svm-%.2dAverages-fold%.2d-%.2fHz.mat', iAve, iF, pars.ssvepFreq(targetSquare)) );
                    classifier          = load(classifierFilename);
                    
                    % normalization
                    %------------------------------------------------------------------------------
                    Xtest       = bsxfun(@minus, featTest, classifier.minx);
                    Xtest       = bsxfun(@rdivide, Xtest, classifier.maxx-classifier.minx);
                    clear featTest
                    
                    % Apply classifier
                    %------------------------------------------------------------------------------
                    Xtest       = [Xtest ones(size(Xtest, 1),1)]; %#ok<AGROW>
                    YlatTest    = Xtest*classifier.B;
                    clear Xtest
                    
                    [ ~, winner ] = max( YlatTest );
                    targetIcon = targetSymbol - (targetSquare-1)*pars.nP3item;
                    
                    
%                     fprintf( fid, ...
%                         '%s, %d, %d, %d, %d, %d, %.2g, %d\n', ...
%                         sub{iS}, iF, listTrainRuns(iF, :), iRunTest, iCue, iAve, pars.ssvepFreq( targetSquare ), winner == targetIcon );                    
                    fprintf(fid, '%s, %d, ', sub{iS}, iF);
                    for i = 1:nRunsForTraining
                        fprintf(fid, '%d, ', listTrainRuns(iF, i));
                    end
                    fprintf(fid, '%d, %d, %d, %.2g, %d\n', iRunTest, iCue, iAve, pars.ssvepFreq( targetSquare ), winner == targetIcon);
                    
%                     temp_targetFrequency( iCue ) = pars.ssvepFreq( targetSquare );
%                     temp_correctness( iCue ) = winner == targetIcon;
                                        
                end % OF iCUE LOOP

%                 inds = ( testingRun == iRunTest ) & ( iFold == iF ) & ( nAverages == iAve ) ;
%                 targetFrequency( inds ) = temp_targetFrequency;
%                 correctness( inds )     = temp_correctness;
                
                
            end % OF iAVE LOOP
        end % CONCERNED CVFOLDS LOOP
        
    
end % OF RUNTEST LOOP

fclose( fid );

end