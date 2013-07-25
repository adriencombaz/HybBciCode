cl;

%% ========================================================================================================

targetFS    = 128;
nFoldsSvm   = 10;

oldDir      = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP_2stim\02-classify-erps\';
newDir      = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP_2stim\02-xxx-classify-erps\';

codeDir     = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP_2stim\';
TableName   = fullfile( codeDir, '01-preprocess-plot', filesep, 'watchErpDataset.xlsx');
fileList    = dataset('XLSFile', TableName);

sub         = unique( fileList.subjectTag );

%% ========================================================================================================

run = unique( fileList.run );
if ~isequal(run(:), (1:max(run))'), error('wrong run numbering'); end

listTrainRunsNew = {1, 2, 3, [1 2], [2 3], [3 4], [1 2 3], [2 3 4]};
nClassifiers = numel(listTrainRunsNew);
listTestRunsNew = cell( nClassifiers, 1 );
for iCl = 1:nClassifiers
    listTestRunsNew{iCl} = run( run > max(listTrainRunsNew{iCl}) );
end

%% ========================================================================================================
for iS = 1:numel(sub)
    for iCl = 1:nClassifiers
        
        fprintf('\nTreating subject %d out of %d, classifier %d out of %d\n', iS, numel(sub), iCl, nClassifiers);
        fileListSub = fileList( ismember( fileList.subjectTag, sub{iS} ), : );
        
        %-------------------------------------------------------------------------------------------------------------------------
        nRunsForTraining = numel( listTrainRunsNew{iCl} );
        oldResDir = fullfile( oldDir, sprintf('LinSvm_%dRunsForTrain_%dHz_%.2dcvSvm', nRunsForTraining, targetFS, nFoldsSvm), sprintf('subject_%s', sub{iS}) );
        if ~exist( oldResDir, 'dir' )
            fprintf('\nDIRECTORY %s DOES NOT EXIST\n', oldResDir);
            continue
        end
        newResDir = fullfile( newDir, sprintf('LinSvm_%dHz_%.2dcvSvm', targetFS, nFoldsSvm), sprintf('subject_%s', sub{iS}) );
        if ~exist(newResDir, 'dir'), mkdir(newResDir); end
        
        %-------------------------------------------------------------------------------------------------------------------------
        listTrainRunsOld    = combntns(run, nRunsForTraining);
        nCv                 = size(listTrainRunsOld, 1);
        indCv               = find( sum( ismember(listTrainRunsOld, listTrainRunsNew{iCl}), 2 ) == nRunsForTraining );
        if isempty(indCv) || numel(indCv) ~= 1, error('smth wrong here!!'); end
        
        for iAve = 1:10
            
            %-------------------------------------------------------------------------------------------------------------------------
            classifierFilenameOld  = fullfile( oldResDir, sprintf('svm-%.2dAverages-fold%.2d.mat', iAve, indCv) );
            if ~exist( classifierFilenameOld, 'file' )
                fprintf('\nFILE %s DOES NOT EXIST\n', classifierFilenameOld);
                continue
            end
            
            %-------------------------------------------------------------------------------------------------------------------------
            classifierFilenameNew = 'svm-train';
            for iR = 1:nRunsForTraining
                classifierFilenameNew = sprintf('%s%d', classifierFilenameNew, listTrainRunsNew{iCl}(iR));
            end
            classifierFilenameNew  = fullfile( newResDir, sprintf('%s-%.2dAverages.mat',classifierFilenameNew, iAve) );
            
            
            %-------------------------------------------------------------------------------------------------------------------------
            % Just some cheking
            trainingRuns        = listTrainRunsNew{iCl};
            testingRuns         = listTestRunsNew{iCl};
            load( classifierFilenameOld, 'trainingFileNames', 'testingFileNames');
            if ~isequal( trainingFileNames, fileListSub.fileName( ismember(fileListSub.run, trainingRuns) ) )
                error('smth wrong here!!');
            end
            testingFileNames = fileListSub.fileName( ismember(fileListSub.run, testingRuns) );

            %-------------------------------------------------------------------------------------------------------------------------
            copyfile( classifierFilenameOld, classifierFilenameNew );
            
            
            %-------------------------------------------------------------------------------------------------------------------------
            save( classifierFilenameNew, 'trainingRuns', 'testingRuns', '-append');
            fprintf('...%dAve', iAve);
            
        end
    end
end



