function applySvmClassifier_perSubject_CompareNrepForTrain( iS, nRunsForTraining, targetFS, nFoldsSvm)

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


%================================================================================================================================
%================================================================================================================================

%--------------------------------------------------------------------------
if isunix,
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset2.csv');
    fileList    = dataset('File', TableName, 'Delimiter', ',');
else
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset2.xlsx');
    fileList    = dataset('XLSFile', TableName);
end

%--------------------------------------------------------------------------
sub     = unique( fileList.subjectTag );
cond    = unique( fileList.condition );
nCond   = numel(cond);
nAveMax = 10;
fileList= fileList( ismember( fileList.subjectTag, sub{iS} ), : );

%--------------------------------------------------------------------------
[~, folderName, ~] = fileparts(cd);
resDir = fullfile( resDir, folderName, sprintf('LinSvm_%dRunsForTrain_%dHz_%.2dcvSvm', nRunsForTraining, targetFS, nFoldsSvm), sprintf('subject_%s', sub{iS}) );

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
butterFilt.lowMargin = .5;
butterFilt.highMargin = 20;
butterFilt.order = 3;

%--------------------------------------------------------------------------
fid = fopen( fullfile( resDir, 'Results_CompareNrepForTrain.txt' ),'wt' );
fprintf(fid, 'subject, condition, foldInd, ');
for i = 1:nRunsForTraining
    fprintf(fid, 'trainingRun_%d, ', i);
end
fprintf(fid, 'testingRun, roundNb, nAveragesTest, nAveragesTrain, correctness\n');


%================================================================================================================================
%================================================================================================================================
for iC = 1:nCond
    for iRunTest = 1:max(run)
        
        fprintf('Subject %s, condition %s (%d out of %d), run %d out of %d\n', sub{iS}, cond{iC}, iC, nCond, iRunTest, max(run));
        
        subFileList = fileList( ismember( fileList.condition, cond{iC} ) & ismember( fileList.run, iRunTest ), : );
        if size(subFileList)~=1, error('size should be 1!!'); end
        
        
        %% LOAD AND PROCESS THE EEG DATA
        %==============================================================================
        %==============================================================================
        
        %
        %--------------------------------------------------------------------------
        sessionDir      = fullfile(dataDir, subFileList.sessionDirectory{1});
        [~, name, ext]  = fileparts( ls(fullfile(sessionDir, [subFileList.fileName{1} '*.bdf'])) );
        filename        = strtrim( [name ext] );
        [~, name, ext]  = fileparts( ls(fullfile(sessionDir, [subFileList.fileName{1}(1:19) '*.mat'])) );
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
        targetStateSeq  = pars.lookHereStateSeq( pars.lookHereStateSeq~=max(pars.lookHereStateSeq) );
        nP3item         = max( targetStateSeq );
    
        
        %%
        %==============================================================================
        %==============================================================================
        [concernedFolds, ~, ~] = find(listTestRuns == iRunTest);
        for iF = concernedFolds'
            for iAveTrain = 1:nAveMax
                for iAve = 1:nAveMax
                    
                    %                 fprintf('subject %s, test run %d out of %d, fold %d out of %d, %d ave out of %d\n', ...
                    %                     sub{iS}, iRunTest, max(run), find(concernedFolds==iF), numel(concernedFolds), iAve, nAveMax);
                    
                    % load the classifier
                    %------------------------------------------------------------------------------
                    classifierFilename  = fullfile( resDir, sprintf('svm-%s-%.2dAverages-fold%.2d.mat',  cond{iC}, iAveTrain, iF) );
                    classifier          = load(classifierFilename);
                    
                    %
                    %------------------------------------------------------------------------------
                    for iCue = 1:pars.nCuesToShow
                        
                        meanCuts        = zeros(nbins, nChans, nP3item);
                        indStart        = (iCue-1)*pars.nRepetitions*nP3item;
                        indEvents       = indStart + (1:pars.nRepetitions*nP3item);
                        for iIcon = 1:nP3item
                            
                            iIconFlashes = indStart + find( pars.realP3StateSeqOnsets(indEvents) == iIcon, iAve, 'first' );
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
                        
                        [ ~, winner ]   = max( YlatTest );
                        targetIcon      = targetStateSeq( iCue );
                        
                        % Write in the output file
                        %------------------------------------------------------------------------------
                        fprintf(fid, '%s, %s, %d, ', sub{iS}, cond{iC}, iF);
                        for i = 1:nRunsForTraining
                            fprintf(fid, '%d, ', listTrainRuns(iF, i));
                        end
                        fprintf(fid, '%d, %d, %d, %d, %d\n', iRunTest, iCue, iAve, iAveTrain, winner == targetIcon);
                        
                    end % OF iCUE LOOP
                end % OF iAVE LOOP
            end % OF iAVETRAIN LOOP
        end % CONCERNED CVFOLDS LOOP
    end % OF RUNTEST LOOP
end % OF iCOND LOOP

fclose(fid);

end % OF FUNCTION
