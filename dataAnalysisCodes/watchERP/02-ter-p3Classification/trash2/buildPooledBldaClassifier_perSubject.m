function buildPooledBldaClassifier_perSubject( iS )

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
resDir = fullfile( resDir, folderName, 'BldaPooled', sprintf('subject_%s', sub{iS}) );
if ~exist( resDir, 'dir' ), mkdir(resDir); end

tBeforeOnset = 0;
tAfterOnset = .6;
nSPcomp = 4;
butterFilt.lowMargin = .5;
butterFilt.highMargin = 30;
butterFilt.order = 3;
targetFS = 128;
% nT_train_perCond    = 250;
% nNT_train_perCond   = 250;


for iRun = 1:nRuns
    
    for iAve = 1:nAveMax

        %================================================================================================================================
        %  BUILD FEATURES FROM ALL CONDITIONS
        %================================================================================================================================

        SigTrainT     = cell(1, nCond);
        SigTrainNT    = cell(1, nCond);
        
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
            
            if iAve == 1
                SigTrainT{iC}   = cuts_DS(:, :,erpData.eventId == iT);
                SigTrainNT{iC}  = cuts_DS(:, :,erpData.eventId == iNT);
                
                if (iC > 1 && nT_train_perCond ~= size(SigTrainT{iC}, 3)), error('not the same amount of target trials accross conditions'); end
                if (iC > 1 && nNT_train_perCond ~= size(SigTrainNT{iC}, 3)), error('not the same amount of non-target trials accross conditions'); end
                nT_train_perCond    = size(SigTrainT{iC}, 3);
                nNT_train_perCond   = size(SigTrainNT{iC}, 3);
            else
                nT_train_perCond    = 250;
                nNT_train_perCond   = 250;
                SigTrainT{iC}   = zeros( size(cuts_DS, 1), size(cuts_DS, 2), nT_train_perCond ); %, 'single' );
                SigTrainNT{iC}  = zeros( size(cuts_DS, 1), size(cuts_DS, 2), nNT_train_perCond ); %, 'single' );
                
                indTargetEvents = find( erpData.eventId == iT );
                for i = 1:nT_train_perCond
                    selection           = randperm( numel(indTargetEvents) );
                    selection           = selection(1:iAve);
                    SigTrainT{iC}(:,:,i)    = mean( cuts_DS( :, :, indTargetEvents(selection) ), 3 );
                end
                
                indNonTargetEvents = find( erpData.eventId == iNT );
                for i = 1:nNT_train_perCond
                    selection           = randperm( numel(indNonTargetEvents) );
                    selection           = selection(1:iAve);
                    SigTrainNT{iC}(:,:,i)   = mean( cuts_DS( :, :, indNonTargetEvents(selection) ), 3 );
                end
            end            
            clear cuts_DS

        end
        
        sizesT1 = unique( cell2mat( cellfun(@(x) size(x, 1), SigTrainT, 'UniformOutput', false) ) );
        sizesT2 = unique( cell2mat( cellfun(@(x) size(x, 2), SigTrainT, 'UniformOutput', false) ) );
        sizesNT1 = unique( cell2mat( cellfun(@(x) size(x, 1), SigTrainNT, 'UniformOutput', false) ) );
        sizesNT2 = unique( cell2mat( cellfun(@(x) size(x, 2), SigTrainNT, 'UniformOutput', false) ) );
        if numel( sizesT1 ) ~= 1, error('run %d, different number of time points across conditions', iRun); end
        if numel( sizesNT1 ) ~= 1, error('run %d, different number of time points across conditions', iRun); end
        if numel( sizesT2 ) ~= 1, error('run %d, different number of channels across conditions', iRun); end
        if numel( sizesNT2 ) ~= 1, error('run %d, different number of channels across conditions', iRun); end
        if ~isequal( sizesT1, sizesNT1 ), error('run %d, different number of time points across conditions for target and non-target', iRun); end
        if ~isequal( sizesT2, sizesNT2 ), error('run %d, different number of channels across conditions for target and non-target', iRun); end
        
        SigTrainT_pool = zeros( sizesT1, sizesT2, nCond*nT_train_perCond );
        SigTrainNT_pool = zeros( sizesNT1, sizesNT2, nCond*nNT_train_perCond);
        for  iC = 1:nCond
            SigTrainT_pool( :, :, (iC-1)*nT_train_perCond+1:iC*nT_train_perCond) = SigTrainT{iC};
            SigTrainNT_pool( :, :, (iC-1)*nNT_train_perCond+1:iC*nNT_train_perCond) = SigTrainNT{iC};
        end

        %================================================================================================================================
        %  TRAIN THE BLDA
        %================================================================================================================================
            
        % winsorize, normalize and train the bayesian lda
        %------------------------------------------------------------------------------
        xTrain = cat(3, SigTrainT_pool, SigTrainNT_pool);
        xTrain = permute(xTrain, [2 1 3]);
        
        w = windsor;
        w = train(w,xTrain,0.1);
        xTrain = apply(w,xTrain);
        
        n = normalize;
        n = train(n,xTrain,'minmax');
        xTrain = apply(n,xTrain);
        
        xTrain = reshape( xTrain, size(xTrain,2)*size(xTrain,1), size(xTrain,3) ); % size: nSamples*nChannels by nTrials
        yTrain = [ones(1, nCond*nT_train_perCond,1)  -ones(1, nCond*nNT_train_perCond)];
        b = bayeslda(1);
        b = trainBis(b, xTrain, yTrain);
        
        classifierFilename  = fullfile( resDir, sprintf('pooledBlda-run%d-%.2dAverages.mat', iRun, iAve) );
        save( classifierFilename, 'butterFilt', 'W', 'targetFS', 'w','n' ,'b' , 'tBeforeOnset', 'tAfterOnset', 'nSPcomp' );
        
    end
    
end


end