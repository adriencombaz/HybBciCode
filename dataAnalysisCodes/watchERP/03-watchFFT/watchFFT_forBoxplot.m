cl;

%% ====================================================================================================

hostName = lower( strtok( getenv( 'COMPUTERNAME' ), '.') );

switch hostName,
    case 'kuleuven-24b13c',
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciData\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciData\watchERP\';
    otherwise,
        error('host not recognized');
end

%% ====================================================================================================

TableName   = '..\01-preprocess-plot\watchErpDataset.xlsx';
fileList    = dataset('XLSFile', TableName);


sub     = unique( fileList.subjectTag );
cond    = {'hybrid-12Hz', 'ssvep-12Hz', 'hybrid-15Hz', 'ssvep-15Hz'};
freqOfInterest = [12 12 15 15];
nSub    = numel(sub);
nCond   = numel(cond);

minFreq = 1;
maxFreq = 35;

timesToWatch= 14;%[5 10];

nData       = nSub*nCond;
subject     = cell( nData, 1 );
condition   = cell( nData, 1 );
fftVals     = cell( nData, 1 );
chanList    = cell( nData, 1 );
fs          = zeros( nData, 1 );
timeInSec   = zeros( nData, 1 );
nEpochs     = zeros( nData, 1 );
ind         = 1;

%% ====================================================================================================

refChanNames    = {'EXG1', 'EXG2'};
discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};

filter.fr_low_margin   = .2;
filter.fr_high_margin  = 40;
filter.order           = 4;
filter.type            = 'butter'; % Butterworth IIR filter
% [filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(fs/2));

for iS = 1:nSub
    for iC = 1:nCond
        
        subset = fileList( ismember( fileList.subjectTag, sub{iS} ) & ismember( fileList.condition, cond{iC} ), : );
        nRuns = size(subset, 1);
        if ~isequal(subset.run', 1:nRuns)
            error('inconsistency between amount of runs and their numbering');
        end
                
        fftValsRun = cell(nRuns, 1);
        iEpoch = 0;
        for iR = 1:nRuns
            
            fprintf('treating subject %s (%d out %d), condition %s (%d out of %d), run %d/%d\n', ...
                sub{iS}, iS, nSub, cond{iC}, iC, nCond, iR, nRuns);
            %-------------------------------------------------------------------------------------------
            sessionDir      = fullfile(dataDir, subset.sessionDirectory{iR});
            filename        = ls(fullfile(sessionDir, [subset.fileName{iR} '*.bdf']));
            hdr             = sopen( fullfile(sessionDir, filename) );
            [sig hdr]       = sread(hdr);
            statusChannel   = bitand(hdr.BDF.ANNONS, 255);
            hdr.BDF         = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
            samplingRate    = hdr.SampleRate;
            
            channels        = hdr.Label;
            channels(strcmp(channels, 'Status')) = [];
            discardChanInd  = cell2mat( cellfun( @(x) find(strcmp(channels, x)), discardChanNames, 'UniformOutput', false ) );
            channels(discardChanInd) = [];
            refChanInd      = cell2mat( cellfun( @(x) find(strcmp(channels, x)), refChanNames, 'UniformOutput', false ) );
            nChan           = numel(channels);
            
            [filter.a filter.b] = butter(filter.order, [filter.fr_low_margin filter.fr_high_margin]/(samplingRate/2));
            
            %-------------------------------------------------------------------------------------------
            paramFileName   = [filename(1:19) '.mat'];
            expParams       = load( fullfile(sessionDir, paramFileName) );
            expParams.scenario = rmfield(expParams.scenario, 'textures');
            
            onsetEventInd   = cellfun( @(x) strcmp(x, 'SSVEP stim on'), {expParams.scenario.events(:).desc} );
            onsetEventValue = expParams.scenario.events( onsetEventInd ).id;
            eventChan       = logical( bitand( statusChannel, onsetEventValue ) );
            
            stimOnsets      = find( diff( eventChan ) == 1 ) + 1;
            stimOffsets     = find( diff( eventChan ) == -1 ) + 1;
            minEpochLenght  = min( stimOffsets - stimOnsets + 1 ) / samplingRate;
            if timesToWatch > minEpochLenght, error('Time to watch is larger (%g sec) than smallest SSVEP epoch lenght (%g sec)', timesToWatch, minEpochLenght); end
            
            %-------------------------------------------------------------------------------------------
            sig(:, discardChanInd)  = [];
            sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
            for i = 1:size(sig, 2)
                sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
            end
            [sig channels] = reorderEEGChannels(sig, channels);
            sig = sig{1};
            
            %-------------------------------------------------------------------------------------------
            epochLenght = timesToWatch*samplingRate;
            NFFT        = 2^nextpow2(epochLenght);
            f           = samplingRate/2*linspace(0,1,NFFT/2+1);
            
            fftValsRun{iR} = zeros(numel(stimOnsets), nChan);
            
            for iE = 1:numel( stimOnsets )
                epoch   = sig( stimOnsets(iE):stimOnsets(iE)+epochLenght-1, : );
                for iCh = 1:nChan
                    Y = fft(epoch(:, iCh), NFFT)/epochLenght;
                    Y = 2 * abs( Y( 1:NFFT/2+1 ) );
                    fftValsRun{iR}(iE, iCh) = Y( f==freqOfInterest(iC), : );
                end
            end
            iEpoch = iEpoch + numel( stimOnsets );            
            
        end
        fftVals{ind}    = cell2mat(fftValsRun);
        subject{ind}    = sub{iS};
        condition{ind}  = cond{iC};
        chanList{ind}   = channels;
        fs(ind)         = samplingRate;
        timeInSec(ind)  = timesToWatch;
        nEpochs(ind)    = iEpoch;
        
        ind = ind + 1;
    end
end


fftDatasetForBoxplot = dataset( ...
    subject, ...
    condition, ...
    timeInSec, ...
    fftVals, ...
    nEpochs, ...
    chanList, ...
    fs ...
    );

save('fftDatasetForBoxplot.mat', 'fftDatasetForBoxplot');

%%

subjects = unique(fftDatasetForBoxplot.subject);
nSub = numel(subjects);
conditions = unique(fftDatasetForBoxplot.condition);
nCond = numel(conditions);

%%
nSamples    = sum( cell2mat( cellfun(@numel, fftDatasetForBoxplot.fftVals, 'UniformOutput', false ) ) );
subjectR    = cell(nSamples, 1);
conditionR  = cell(nSamples, 1);
channelR    = cell(nSamples, 1);
runR        = zeros(nSamples, 1);
fftValue    = zeros(nSamples, 1);
stimStyle   = cell(nSamples, 1);
frequency   = zeros(nSamples, 1);

indStart = 1;
for iSub = 1:nSub
    for iCond = 1:nCond
        
        subset = fftDatasetForBoxplot( ismember(fftDatasetForBoxplot.subject, subjects{iSub}) & ismember(fftDatasetForBoxplot.condition, conditions{iCond}), : );
        
        indEnd                      = indStart + numel(subset.fftVals{1}) - 1;
        fftValue(indStart:indEnd)   = subset.fftVals{1}(:);
        temp                        = repmat( subset.chanList{1}, 1, size( subset.fftVals{1}, 1 ) )';
        channelR(indStart:indEnd)   = temp(:);
        runR(indStart:indEnd)       = repmat( (1:size( subset.fftVals{1}, 1 ))', size( subset.fftVals{1}, 2 ), 1 );
        conditionR(indStart:indEnd) = repmat( conditions(iCond), numel(subset.fftVals{1}), 1 );
        subjectR(indStart:indEnd)   = repmat( subjects(iSub), numel(subset.fftVals{1}), 1 );
        
        if strfind( conditions{iCond}, 'hybrid' )
            stimStyle(indStart:indEnd) = repmat( {'hybrid'}, numel(subset.fftVals{1}), 1 );
        else
            stimStyle(indStart:indEnd) = repmat( {'ssvep'}, numel(subset.fftVals{1}), 1 );
        end
        
        if strfind( conditions{iCond}, '12Hz' )
            frequency(indStart:indEnd) = repmat( 12, numel(subset.fftVals{1}), 1 );
        else
            frequency(indStart:indEnd) = repmat( 15, numel(subset.fftVals{1}), 1 );
        end
        
        indStart = indEnd + 1;
    end
end


dataForR = dataset( ...
    subjectR, ...
    conditionR, ...
    stimStyle, ...
    frequency, ...
    channelR, ...
    runR, ...
    fftValue ...
    );

export(dataForR, 'file', 'fftDataForR.csv', 'Delimiter', ',');
















