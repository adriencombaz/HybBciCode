function computeSNRs( iS )

%% ========================================================================================================
% =========================================================================================================

% init host name
%--------------------------------------------------------------------------
if isunix,
    envVarName = 'HOSTNAME';
else
    envVarName = 'COMPUTERNAME';
end
hostName = lower( strtok( getenv( envVarName ), '.') );

% init paths
%--------------------------------------------------------------------------
switch hostName,
    case 'kuleuven-24b13c',
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        resDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watch-ERP\04-watchSSVEP-PSD\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        addpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\') );
        rmpath( genpath('d:\Adrien\matlabToolboxes\eeglab10_0_1_0b\external\SIFT_01_alpha') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
        resDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciProcessedData\watch-ERP\04-watchSSVEP-PSD\';
    case {'sunny', 'solaris', ''}
        addpath( genpath( '~/PhD/hybridBCI-stuffs/deps/' ) );
        rmpath( genpath('~/PhD/hybridBCI-stuffs/deps/eeglab10_0_1_0b/external/SIFT_01_alpha') );
        dataDir = '~/PhD/hybridBCI-stuffs/data/';
        resDir = '~/PhD/hybridBCI-stuffs/results/04-watchSSVEP-PSD/';
    otherwise,
        error('host not recognized');
end

if ~exist(resDir, 'dir'), mkdir(resDir); end

if isunix,
    TableName   = 'watchFftDataset.csv';
    fileList    = dataset('File', TableName, 'Delimiter', ',');
else
    TableName   = 'watchFftDataset.xlsx';
    fileList    = dataset('XLSFile', TableName);
end

% ========================================================================================================
% ========================================================================================================

sub     = unique( fileList.subjectTag );
freq    = unique( fileList.frequency );
oddb    = unique( fileList.oddball );
cond    = unique( fileList.condition );

nSub    = numel( sub );
nFreq   = numel( freq );
nOdd    = numel( oddb );
nCond   = numel( cond );
if nCond ~= nFreq*nOdd, error('conditions are not entirely determined by frequency and oddball'); end
if ~isequal( oddb, [0 ; 1] ), error('not the expected oddball condition'); end

% check consistency of data
% % % % % % % % % % % for iS = 1:nSub
% % % % % % % % % % %     
% % % % % % % % % % %     subData = fileList( ismember(fileList.subjectTag, sub{iS}), : );
% % % % % % % % % % %     for iF = 1:nFreq
% % % % % % % % % % %         
% % % % % % % % % % %         subFreq = subData( ismember(subData.frequency, freq(iF)), : );
% % % % % % % % % % %         oddCond = sort( unique( subFreq.oddball ) );
% % % % % % % % % % %         if ~isequal( oddCond, oddb ),
% % % % % % % % % % %             error( 'subject %s, frequency %d, not the expected oddball condition', sub{iS}, freq(iF) );
% % % % % % % % % % %         end
% % % % % % % % % % %         
% % % % % % % % % % %     end
% % % % % % % % % % % end

% ========================================================================================================
% ========================================================================================================
% channelsList = { ...
%             {'O1', 'Oz', 'O2'} ...
%             , {'PO3', 'PO4', 'O1', 'Oz', 'O2'} ...
%             , {'P7', 'P3', 'Pz', 'P4', 'P8', 'PO3', 'PO4', 'O1', 'Oz', 'O2'} ...
%             , {'CP5', 'CP1', 'CP2', 'CP6', 'P7', 'P3', 'Pz', 'P4', 'P8', 'PO3', 'PO4', 'O1', 'Oz', 'O2'} ...
%             , {'C3', 'Cz', 'C4', 'CP5', 'CP1', 'CP2', 'CP6', 'P7', 'P3', 'Pz', 'P4', 'P8', 'PO3', 'PO4', 'O1', 'Oz', 'O2'} ...
%             , 'all' ...
%             };
% channelsLabel = {'ch-O', 'ch-PO-O', 'ch-P-PO-O', 'ch-CP-P-PO-O', 'ch-C-CP-P-PO-O', 'ch-all'};
% harmonicList = { 1, [1 2] };
% harmonicLabel = {'fund', 'fund-ha1'};
channelsList = { {'P7', 'P3', 'Pz', 'P4', 'P8', 'PO3', 'PO4', 'O1', 'Oz', 'O2'} };
channelsLabel = {'ch-P-PO-O'};
harmonicList = { [1 2] };
harmonicLabel = {'fund-ha1'};


refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

filter.fr_low_margin   = .2;
filter.fr_high_margin  = 40;
filter.order           = 4;
filter.type            = 'butter'; % Butterworth IIR filter

timesInSec  = 1:12;
nTimes      = numel( timesInSec );

targetFS    = 256;


% ========================================================================================================
% ========================================================================================================
fid = zeros(numel(channelsList), numel(harmonicList));
for iChanList = 1:numel(channelsList)
    for iHaList = 1:numel(harmonicList)
        outDir = fullfile(resDir, [channelsLabel{iChanList} '_' harmonicLabel{iHaList}]);
        if ~exist(outDir, 'dir'), mkdir(outDir); end
        fid(iChanList, iHaList) = fopen( fullfile( outDir, sprintf('snrs_subject%s.txt', sub{iS}) ),'wt' );
        fprintf(fid(iChanList, iHaList), 'subject, run, roundNb, time, watchedFrequency, snr, targetFrequency, oddball, nComp\n');
    end
end


% ========================================================================================================
% ========================================================================================================
mcdObj = cell(numel(channelsList), numel(harmonicList), nTimes);
for iChanList = 1:numel(channelsList)
    for iHaList = 1:numel(harmonicList)
        for iT = 1:nTimes
            mcdObj{iChanList, iHaList, iT} = mecSsvepClassifier( ...
                'frequencies', freq ...
                , 'harmonics', harmonicList{iHaList} ...
                , 'fs', targetFS ...
                , 'windowsizeinsec', timesInSec(iT) ...
                );
        end
    end
end

% ========================================================================================================
% ========================================================================================================
iRun = 0;
for iF = 1:nFreq,
    for iOdd = 1:nOdd,
        
        subset = fileList( ...
            ismember( fileList.subjectTag, sub{iS} ) & ...
            ismember( fileList.frequency, freq(iF) ) & ...
            ismember( fileList.oddball, oddb(iOdd) ) ...
            , : );
        
        if size(subset, 1)~=1, error('not exactly one file per condition per subject!!'); end
        iRun = iRun + 1;
        
        %-------------------------------------------------------------------------------------------
        sessionDir      = fullfile(dataDir, subset.sessionDirectory{1});
        filename        = ls(fullfile(sessionDir, [subset.fileName{1} '*.bdf']));
        hdr             = sopen( fullfile(sessionDir, filename) );
        
        if strcmp(filename, '2013-03-13-10-16-47-hybrid-12Hz.bdf')
            statusChannel = fix_2013_13_10_16_47_hybrid_12Hz( fullfile(sessionDir, filename) );
        else
            statusChannel = bitand(hdr.BDF.ANNONS, 255);
        end
        
        hdr.BDF         = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
        [sig hdr]       = sread(hdr);
        samplingRate    = hdr.SampleRate;
        [filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(samplingRate/2));
        
        channels        = hdr.Label;
        clear hdr
        channels(strcmp(channels, 'Status')) = [];
        discardChanInd  = cell2mat( cellfun( @(x) find(strcmp(channels, x)), discardChanNames, 'UniformOutput', false ) );
        refChanInd      = cell2mat( cellfun( @(x) find(strcmp(channels, x)), refChanNames, 'UniformOutput', false ) );
        channels([discardChanInd refChanInd]) = [];
        nChan           = numel(channels);
        
        %-------------------------------------------------------------------------------------------
        paramFileName   = [filename(1:19) '.mat'];
        expParams       = load( fullfile(sessionDir, paramFileName) );
        expParams.scenario = rmfield(expParams.scenario, 'textures');
        
        onsetEventInd   = cellfun( @(x) strcmp(x, 'SSVEP stim on'), {expParams.scenario.events(:).desc} );
        onsetEventValue = expParams.scenario.events( onsetEventInd ).id;
        eventChan       = logical( bitand( statusChannel, onsetEventValue ) );
        clear expParams
        
        %-------------------------------------------------------------------------------------------
        refSig = mean(sig(:,refChanInd), 2);
        sig(:, [discardChanInd refChanInd])  = [];
        sig = bsxfun( @minus, sig, refSig );
        clear refSig
        for i = 1:size(sig, 2)
            sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
        end
        [sig channels] = reorderEEGChannels(sig, channels);
        sig = sig{1};
        
        
        %-------------------------------------------------------------------------------------------
        DSF = samplingRate / targetFS;
        if DSF ~= floor(DSF), error('something wrong with the sampling rate'); end
        
        subsamplingLPfilter = fspecial( 'gaussian', [1 DSF*2-1], 1 );
        sig                 = conv2( sig', subsamplingLPfilter, 'same' )';
        sig                 = sig(1:DSF:end,:);
        
        eventChan       = eventChan(1:DSF:end,:);
        stimOnsets      = find( diff( eventChan ) == 1 ) + 1;
        stimOffsets     = find( diff( eventChan ) == -1 ) + 1;
        stimOffsets( stimOffsets <= stimOnsets(1) ) = [];
        minEpochLenght  = min( stimOffsets - stimOnsets + 1 ) / targetFS;
        if max(timesInSec) > minEpochLenght, error('Time to watch is larger (%g sec) than smallest SSVEP epoch lenght (%g sec)', max(timesInSec), minEpochLenght); end
        nTrials         = numel(stimOnsets);
        
        %-------------------------------------------------------------------------------------------
        for iTrial = 1:nTrials
            
            fprintf('treating subject %s (%d out %d), frequency %d (%d out of %d), oddball condition %d (%d out of %d), trial %d out of %d\n', ...
                sub{iS}, iS, nSub, ...
                freq(iF), iF, nFreq, ...
                oddb(iOdd), iOdd, nOdd, ...
                iTrial, nTrials);
            
            for iTime = 1:nTimes
                
                epochLenght = timesInSec(iTime)*targetFS;
                
                for iChanList = 1:numel(channelsList)
                    if strcmp(channelsList{iChanList}, 'all')
                        chanInd = 1:nChan;
                    else
                        chanInd = ismember( channels, channelsList{iChanList});
                    end
                    for iHaList = 1:numel(harmonicList)
                        
                        epoch       = sig( stimOnsets(iTrial):stimOnsets(iTrial)+epochLenght-1, chanInd )';
                        [Snr, Ns]   = mcdObj{iChanList, iHaList, iTime}.getSNRs( epoch );
                        Snr         = mean(Snr, 1);
                        
                        for iWFreq = 1:nFreq
                            fprintf(fid(iChanList, iHaList), '%s, %d, %d, %d, %.2f, %.2f, %.2f, %d, %d\n' ...
                                , sub{iS} ...
                                , iRun ...
                                , iTrial ...
                                , timesInSec(iTime) ...
                                , freq(iWFreq) ...
                                , Snr( iWFreq ) ...
                                , freq(iF) ...
                                , oddb(iOdd) ...
                                , Ns ...
                                );
                            
                        end % of loop over watched frequencies
                        clear epoch
                    end % of loop over harmonic groups
                end % of loop over channel groups
            end % of loop along time
        end % of loop over trials
        clear sig
    end % of loop over oddball condition
end % of loop over frequency condition

fclose(fid(:));


