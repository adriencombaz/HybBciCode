cl;

%% ====================================================================================================

hostName = lower( strtok( getenv( 'COMPUTERNAME' ), '.') );

switch hostName,
    case 'kuleuven-24b13c',
        addpath( genpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
    case 'neu-wrk-0158',
        addpath( genpath('d:\Adrien\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\') );
        dataDir = 'd:\Adrien\Work\Hybrid-BCI\HybBciRecordedData\watchERP\';
    otherwise,
        error('host not recognized');
end

%% ====================================================================================================

TableName   = '..\01-preprocess-plot\watchErpDataset.xlsx';
fileList    = dataset('XLSFile', TableName);


sub     = unique( fileList.subjectTag );
cond    = {'hybrid-12Hz', 'ssvep-12Hz', 'hybrid-15Hz', 'ssvep-15Hz'};
nSub    = numel(sub);
nCond   = numel(cond);

minFreq = 1;
maxFreq = 35;

timesToWatch= 1:14;%[5 10];
nTime       = numel(timesToWatch);

nData       = nSub*nCond*nTime;
subject     = cell( nData, 1 );
condition   = cell( nData, 1 );
fftVals     = cell( nData, 1 );
ff          = cell( nData, 1 );
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

%% ====================================================================================================

for iS = 1:nSub
    for iC = 1:nCond
        
        subset = fileList( ismember( fileList.subjectTag, sub{iS} ) & ismember( fileList.condition, cond{iC} ), : );
        nRuns = size(subset, 1);
        if ~isequal(subset.run', 1:nRuns)
            error('inconsistency between amount of runs and their numbering');
        end
        
        for iT = 1:nTime
            
            for iR = 1:nRuns
                
                fprintf('treating subject %s (%d out %d), condition %s (%d out of %d), epoch lenght of %g seconds (%d out of %d), run %d/%d\n', ...
                    sub{iS}, iS, nSub, cond{iC}, iC, nCond, timesToWatch(iT), iT, nTime, iR, nRuns);
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
                if timesToWatch(iT) > minEpochLenght, error('Time to watch is larger (%g sec) than smallest SSVEP epoch lenght (%g sec)', timesToWatch(iT), minEpochLenght); end
                
                %-------------------------------------------------------------------------------------------
                sig(:, discardChanInd)  = [];
                sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
                for i = 1:size(sig, 2)
                    sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
                end
                [sig channels] = reorderEEGChannels(sig, channels);
                sig = sig{1};
                
                %-------------------------------------------------------------------------------------------
                epochLenght = timesToWatch(iT)*samplingRate;
                NFFT        = 2^nextpow2(epochLenght);
                f           = samplingRate/2*linspace(0,1,NFFT/2+1);
                fx          = f( f>=minFreq & f<=maxFreq );
                if iR == 1
                    fftVals{ind} = zeros( numel(fx), nChan );
                    iEpoch       = 0;
                end
                for iE = 1:numel( stimOnsets )
                    epoch   = sig( stimOnsets(iE):stimOnsets(iE)+epochLenght-1, : );
                    for iCh = 1:nChan
                        Y = fft(epoch(:, iCh), NFFT)/epochLenght;
                        Y = 2 * abs( Y( 1:NFFT/2+1 ) );
                        fftVals{ind}(:, iCh) = fftVals{ind}(:, iCh) + Y( f>=minFreq & f<=maxFreq, :);
                    end
                end
                iEpoch = iEpoch + numel( stimOnsets );                
                if iR == nRuns
                    fftVals{ind} = fftVals{ind} / iEpoch;
                end
                
                
            end
            subject{ind}    = sub{iS};
            condition{ind}  = cond{iC};
            chanList{ind}   = channels;
            ff{ind}         = fx;
            fs(ind)         = samplingRate;
            timeInSec(ind)  = timesToWatch(iT);
            nEpochs(ind)    = iEpoch;
            
            ind = ind + 1;
        end
    end
end

meanFftDataset = dataset( ...
    subject, ...
    condition, ...
    timeInSec, ...
    ff, ...
    fftVals, ...
    nEpochs, ...
    chanList, ...
    fs ...
    );

save('meanFftDataset.mat', 'meanFftDataset');


%%

chanList = {'F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};
chanInd  = cell2mat( cellfun( @(x) find(strcmp(meanFftDataset.chanList{1}, x)), chanList, 'UniformOutput', false ) );

subjects = unique(meanFftDataset.subject);
nSub = numel(subjects);
% conditions = unique(meanFftDataset.condition);
conditions = {'ssvep-12Hz' ; 'hybrid-12Hz' ; 'ssvep-15Hz' ; 'hybrid-15Hz'};
ncond = numel(conditions);
stimTimes = unique(meanFftDataset.timeInSec);
nStimTimes = numel(stimTimes);

frequenciesOfInterest = zeros(1, ncond);
for iC = 1:ncond
    switch conditions{iC}
        case 'hybrid-12Hz'
            frequenciesOfInterest(iC) = 12;
        case 'hybrid-15Hz'
            frequenciesOfInterest(iC) = 15;
        case 'ssvep-12Hz'
            frequenciesOfInterest(iC) = 12;
        case 'ssvep-15Hz' 
            frequenciesOfInterest(iC) = 15;
        otherwise
            error('unexpected condition');
    end
end
colors = {'r', 'g', 'b', 'k'};
%%
% one figure per subject for 14 seconds of SSVEP stimulation
for iS = 1:nSub
   
    subset = meanFftDataset( ismember(meanFftDataset.subject, subjects{iS}) & ismember(meanFftDataset.timeInSec, max(meanFftDataset.timeInSec)), : );
    meanAmpSpec = cellfun(@(x) x(:, chanInd), subset.fftVals, 'UniformOutput', false);
    
    titleStr = sprintf('subject %s', subjects{iS});
    plotFfts2( ...
        subset.ff{1}, ...
        meanAmpSpec, ...
        'chanLabels', chanList, ...
        'nMaxChanPerAx', 12, ...
        'axisTitles', subset.condition, ...
        'title', titleStr, ...
        'scale', 2 ...
        );
    
    s.Format        = 'png';
    %     s.Resolution    = 300;
    fh = findobj('Name', titleStr);
    set(findobj(fh,'Type','uicontrol'),'Visible','off');
    % figName = strrep(titleStr, ' ', '-');
    figName = fullfile( cd, sprintf('fft_subject%s', subjects{iS}) );
    hgexport(gcf, [figName '.png'], s);
    close(fh);

    
end


%%
% show evolution of power a frequency of interest over time for each subject
figure
ind = 1;
x = unique(meanFftDataset.timeInSec);
for iS = 1:nSub
    for iCh = 1:numel(chanList)
        
        subplot(numel(chanList), nSub, ind)
        hold on
        for iC = 1:ncond
            
            y = zeros(1, nStimTimes);
            for iT = 1:nStimTimes
            
                subset = meanFftDataset( ismember(meanFftDataset.subject, subjects{iS}) ...
                    & ismember(meanFftDataset.condition, conditions{iC}) ....
                    & ismember(meanFftDataset.timeInSec, stimTimes(iT)), : );
                
                y(iT) = subset.fftVals{1}( subset.ff{1} == frequenciesOfInterest(iC), chanInd(iCh) );
            
            end
            plot(x, y, 'color', colors{iC});
        end
        ind = ind + 1;
    end
end

%%
% animation

chanList = {'Pz', 'Oz'};
chanInd  = cell2mat( cellfun( @(x) find(strcmp(meanFftDataset.chanList{1}, x)), chanList, 'UniformOutput', false ) );

for iT = 1:nStimTimes
    
    toPlot = cell(1, ncond);
    for iC = 1:ncond
    
        subset = meanFftDataset( ismember(meanFftDataset.condition, conditions{iC}) ...
            & ismember(meanFftDataset.timeInSec, stimTimes(iT)), : );
        
        temp = cellfun(@(x) x(:, chanInd), subset.fftVals, 'UniformOutput', false);
        y = [];
        for iS = 1:nSub
            y = [y temp{iS}];
        end
        
        toPlot{iC} = y;
    end
    
    titleStr = sprintf('stimulation time %g seconds', stimTimes(iT));
    plotFfts2( ...
        subset.ff{1}, ...
        toPlot, ...
        'chanLabels', repmat( chanList, 1, nSub ), ...
        'nMaxChanPerAx', 12, ...
        'axisTitles', conditions, ...
        'title', titleStr, ...
        'scale', 2 ...
        );
    
    s.Format        = 'png';
%     s.Resolution    = 300;
    fh = findobj('Name', titleStr);
    set(findobj(fh,'Type','uicontrol'),'Visible','off');
    % figName = strrep(titleStr, ' ', '-');
    figName = fullfile( cd, sprintf('fft_%02gsec', stimTimes(iT)) );
    hgexport(gcf, [figName '.png'], s);
    close(fh);
    
    
end




