function applySvmClassifier_perSubject( iS )

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
    case {'sunny', 'solaris'}
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

if isunix,
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset2.csv');
    fileList    = dataset('File', TableName, 'Delimiter', ',');
else
    TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset2.xlsx');
    fileList    = dataset('XLSFile', TableName);
end


sub     = unique( fileList.subjectTag );
cond    = unique( fileList.condition );
nSub    = numel(sub);
nCond   = numel(cond);
nAveMax = 10;

[dum1 folderName dum2] = fileparts(cd);
resDir = fullfile( resDir, folderName, 'LinSvm', sprintf('subject_%s', sub{iS}) );

fid = fopen( fullfile( resDir, 'Results.txt' ),'wt' );
fprintf(fid, 'subject, conditionTrain, conditionTest, nAverages, accuracy, nCorrect, nCued\n');
fprintf('subject, conditionTrain, conditionTest, nAverages, accuracy, nCorrect, nCued\n');


%================================================================================================================================
%================================================================================================================================

for iCTrain = 1:nCond
    for iCTest = 1:nCond
        for iAve = 1:nAve
            
            subsetTrain = fileList( ismember( fileList.subjectTag, sub{iS} ) & ismember( fileList.condition, cond{iCTrain} ), : );
            subsetTest  = fileList( ismember( fileList.subjectTag, sub{iS} ) & ismember( fileList.condition, cond{iCTest} ), : );
            
            runIdTr = unique( subsetTrain.run );
            runIdTest = unique( subsetTest.run );
            if ~isequal( runIdTr, runIdTest ), 
                error('unequal number of runs for train and test condition');
            end
            nRuns = numel( runIdTr );

            %==============================================================================
            %==============================================================================
            
            %%  CROSS-VALIDATION

            %==============================================================================
            %==============================================================================
            nCorrect    = 0;
            nCued       = 0;
            for iCrossVal = 1:nRuns
                                
                % load corresponding classifier
                %==============================================================================
                %==============================================================================

                subsetTrainIcv      = subsetTrain( ismember( subsetTrain.run, runIdTr(iCrossVal) ), : );
                sessionDir          = fullfile(dataDir, subsetTrainIcv.sessionDirectory{1});
%                 filename    = ls(fullfile(sessionDir, [subsetTrain.fileName{1} '*.bdf']));
                [dum, name, ext]    = fileparts( ls( fullfile(sessionDir, [subsetTrainIcv.fileName{1} '*.bdf']) ) );
                filename            = strtrim( [name ext] );
                classifierFilename  = fullfile( resDir, filename );
                classifier          = load(classifierFilename);
                
                % test the classifier on remaning runs
                %==============================================================================
                %==============================================================================
                subsetTestIcv = subsetTest( ~ismember( subsetTest.run, runIdTest(iCrossVal) ), : );
                
                for iRunTest = 1:size( subsetTestIcv, 1 )
                    
                    
                    % read data
                    %------------------------------------------------------------------------------
                    subsetTesti = subsetTestIcv( iRunTest, : );
                    sessionDir  = fullfile(dataDir, subsetTesti.sessionDirectory{1});
                    %                 filename    = ls(fullfile(sessionDir, [subsetTesti.fileName{1} '*.bdf']));
                    [dum, name, ext] = fileparts( ls( fullfile(sessionDir, [subsetTesti.fileName{1} '*.bdf']) ) );
                    filename = strtrim( [name ext] );
                    erpData     = eegDataset( sessionDir, filename );
                    
                    erpData.tBeforeOnset    = classifier.tBeforeOnset;
                    erpData.tAfterOnset     = classifier.tAfterOnset;
                    
                    
                    % read experiment parameters
                    %------------------------------------------------------------------------------
                    %                 paramFile   = ls(fullfile(sessionDir, [subsetTesti.fileName{1} '*.mat']));
                    [dum, name, ext] = fileparts( ls( fullfile(sessionDir, [subsetTesti.fileName{1} '*.mat']) ) );
                    paramFile = strtrim( [name ext] );
                    pars        = load( fullfile(sessionDir,paramFile), 'nCuesToShow', 'nRepetitions', 'lookHereStateSeq', 'realP3StateSeqOnsets' );
                    
                    nCues   = pars.nCuesToShow;
                    nReps   = pars.nRepetitions;
                    if nReps < iAve, error('number of repetitions used during the experiment is lower than the desired number of averages'); end
                    nIcons  = 6;
                    targetIcon = pars.lookHereStateSeq( pars.lookHereStateSeq <= nIcons );
                    flashSequence = pars.realP3StateSeqOnsets;
                    
                
                    % filter the eeg data
                    %------------------------------------------------------------------------------
                    erpData.butterFilter( classifier.butterFilt.lowMargin, classifier.butterFilt.highMargin, classifier.butterFilt.order );
                    
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
                    newCuts = zeros( size(meanCuts, 1), classifier.nSPcomp, size(meanCuts, 3) ); % , 'single' );
                    for iTr = 1:size(meanCuts, 3)
                        newCuts( :, :, iTr ) = meanCuts( :, :, iTr ) * classifier.W;
                    end
                    clear cuts
                    
                    % downsample
                    %------------------------------------------------------------------------------
                    DSF = erpData.fs / classifier.targetFS;
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
                    
                    % reshape
                    %------------------------------------------------------------------------------
                    featTest     = reshape(cuts_DS, size(cuts_DS,1)*size(cuts_DS,2), size(cuts_DS,3))';
                    clear cuts_DS
                    
                    % normalization
                    %------------------------------------------------------------------------------
                    Xtest       = bsxfun(@minus, featTest, classifier.minx);
                    Xtest       = bsxfun(@rdivide, Xtest, classifier.maxx-classifier.minx);
                    clear featTest
                    
                    % Apply classifier
                    %------------------------------------------------------------------------------
                    Xtest       = [Xtest ones(size(Xtest, 1),1)];
                    YlatTest    = Xtest*classifier.B;
                    clear Xtest
                    
                    
                    % compare winner icon with target icon and update results
                    %------------------------------------------------------------------------------
                    for iCue = 1:nCues
                        [ dum winner ]          = max( YlatTest( (iCue-1)*nIcons+1 : iCue*nIcons ) );
                        nCorrect = nCorrect + ( winner == targetIcon(iCue) );
                    end
                    nCued = nCued + nCues;

                end
            end
            
        fprintf( fid, ...
            '%s, %s, %s, %d, %5.2f, %d, %d\n', ...
            sub{iS}, cond{iCTrain}, cond{iCTest}, iAve, 100*nCorrect/nCued, nCorrect, nCued );
        fprintf( ...
            '%s, %s, %s, %d, %5.2f, %d, %d\n', ...
            sub{iS}, cond{iCTrain}, cond{iCTest}, iAve, 100*nCorrect/nCued, nCorrect, nCued );
            
            
        end
    end
end

fclose(fid);
end