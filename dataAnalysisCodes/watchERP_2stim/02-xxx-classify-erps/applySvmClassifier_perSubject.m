function applySvmClassifier_perSubject( iS, targetFS, nFoldsSvm )

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
        resDir = '~/PhD/hybridBCI-stuffs/watchERP_2stim/results/02-xxx-classify-erps/';
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
resDir      = fullfile( resDir, sprintf('LinSvm_%dHz_%.2dcvSvm', targetFS, nFoldsSvm), sprintf('subject_%s', sub{iS}) );
if ~exist( resDir, 'dir' ), mkdir(resDir); end

%--------------------------------------------------------------------------
run = unique( fileList.run );
if ~isequal(run(:), (1:max(run))'), error('wrong run numbering'); end
listTrainRuns = {1, 2, 3, [1 2], [2 3], [3 4], [1 2 3], [2 3 4]};

nClassifiers = numel(listTrainRuns);
listTestRuns = cell( nClassifiers, 1 );
runsUsedForTest = [];
for iCl = 1:nClassifiers
    listTestRuns{iCl}   = run( run > max(listTrainRuns{iCl}) );
    runsUsedForTest     = unique( [runsUsedForTest; listTestRuns{iCl}] );
end

%--------------------------------------------------------------------------
nAveMax = 10;
tBeforeOnset = 0;
tAfterOnset = .6;
butterFilt.lowMargin = .5;
% butterFilt.highMargin = 30;
butterFilt.highMargin = 20;
butterFilt.order = 3;
% nSquares = 2;
% nItemsPerSquare = 6;

%--------------------------------------------------------------------------
fid = fopen( fullfile( resDir, 'ResultsClassification.txt' ),'wt' );
fprintf(fid, 'subject, foldInd, trainingRuns, testingRun, roundNb, nAverages, targetFrequency, correctness\n');


%% ========================================================================================================
% for iRunTest = runsUsedForTest
for iRT = 1:numel(runsUsedForTest)
    
    iRunTest = runsUsedForTest(iRT);
    fprintf('subject %s, test run %d out of %d\n', ...
        sub{iS}, iRunTest, max(run));
    
    %% LOAD AND PROCESS THE EEG DATA
    %==============================================================================
    %==============================================================================
    
    %
    %--------------------------------------------------------------------------
    sessionDir      = fullfile(dataDir, fileList.sessionDirectory{ ismember(fileList.run,iRunTest) });
    [~, name, ext]  = fileparts( ls(fullfile(sessionDir, [fileList.fileName{ ismember(fileList.run,iRunTest) } '*.bdf'])) );
    filename        = strtrim( [name ext] );
    [~, name, ext]  = fileparts( ls(fullfile(sessionDir, [fileList.fileName{ ismember(fileList.run,iRunTest) }(1:19) '*.mat'])) );
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
        cuts_proc = cuts;
    else
        nbins = floor( size(cuts, 1) / DSF );
        cuts_proc = zeros( nbins, size(cuts, 2), size(cuts, 3) ); % , 'single' );
        for i = 1:nbins
            cuts_proc(i,:,:) = mean( cuts( (i-1)*DSF+1:i*DSF, :, : ), 1 );
        end
    end
    
    % get labels
    %------------------------------------------------------------------------------
    targetStateSeq  = pars.lookHereStateSeq( pars.lookHereStateSeq~=max(pars.lookHereStateSeq) );
    
    
    %%
    %==============================================================================
    %==============================================================================
    concernedClassifiers = find( cell2mat( cellfun(@(x) sum(ismember(x, iRunTest)), listTestRuns, 'UniformOutput', false) ) )';
    
    for iCl = concernedClassifiers % check that iF takes all the values !!!!!!!!!!!!!!!!!
        for iAve = 1:nAveMax
            
            % load the classifier
            %------------------------------------------------------------------------------
            nRunsForTraining   = numel( listTrainRuns{iCl} );
            classifierFilename = 'svm-train';
            for iR = 1:nRunsForTraining
                classifierFilename = sprintf('%s%d', classifierFilename, listTrainRuns{iCl}(iR));
            end
            classifierFilename  = fullfile( resDir, sprintf('%s-%.2dAverages.mat',classifierFilename, iAve) );
            classifier          = load(classifierFilename);
            
            %
            %------------------------------------------------------------------------------
            for iCue = 1:pars.nCuesToShow
                
                targetSymbol    = targetStateSeq( iCue );
                targetSquare    = ceil( targetSymbol / pars.nP3item );
                
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
                
                
                % Write down result
                %------------------------------------------------------------------------------
                fprintf(fid, '%s, %d, train', sub{iS}, iCl);
                for i = 1:nRunsForTraining
                    fprintf(fid, '%d', listTrainRuns{iCl}(i));
                end
                fprintf(fid, ', %d, %d, %d, %.2g, %d\n', iRunTest, iCue, iAve, pars.ssvepFreq( targetSquare ), winner == targetIcon);

            end % OF iCUE LOOP
        end % OF iAVE LOOP
    end % CONCERNED CLASSIFIERS LOOP    
end % OF RUNTEST LOOP

fclose( fid );

end