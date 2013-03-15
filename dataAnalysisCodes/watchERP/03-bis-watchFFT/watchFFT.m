cl;

%% ====================================================================================================

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

if isunix,
    TableName   = 'watchFftDataset.csv';
    fileList    = dataset('File', TableName, 'Delimiter', ',');
else
    TableName   = 'watchFftDataset.xlsx';
    fileList    = dataset('XLSFile', TableName);
end

%% ====================================================================================================

sub     = unique( fileList.subjectTag );
cond    = unique( fileList.condition );
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
frequency   = zeros( nData, 1 );
oddball     = zeros( nData, 1 );
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
        
        
        %-------------------------------------------------------------------------------------------
        sessionDir      = fullfile(dataDir, subset.sessionDirectory{1});
        filename        = ls(fullfile(sessionDir, [subset.fileName{1} '*.bdf']));
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
        if numel(stimOnsets) ~= numel(stimOffsets)
            if numel(stimOffsets) == numel(stimOnsets)+1
                if stimOffsets(1) < stimOnsets(1) && stimOffsets(2) > stimOnsets(1)
                    stimOffsets(1) = [];
                else
                    error('something wrong with SSVEP onset/offset markers');
                end
            else 
               error('different amount of stimuli onsets and offsets');
            end
        end
        
        minEpochLenght  = min( stimOffsets - stimOnsets + 1 ) / samplingRate;
        
        %-------------------------------------------------------------------------------------------
        sig(:, discardChanInd)  = [];
        sig = bsxfun( @minus, sig, mean(sig(:,refChanInd) , 2) );
        for i = 1:size(sig, 2)
            sig(:,i) = filtfilt( filter.a, filter.b, sig(:,i) );
        end
        [sig channels] = reorderEEGChannels(sig, channels);
        sig = sig{1};
        
        for iT = 1:nTime
            
            fprintf('treating subject %s (%d out %d), condition %s (%d out of %d), epoch lenght of %g seconds (%d out of %d)\n', ...
                sub{iS}, iS, nSub, cond{iC}, iC, nCond, timesToWatch(iT), iT, nTime);
            if timesToWatch(iT) > minEpochLenght, error('Time to watch is larger (%g sec) than smallest SSVEP epoch lenght (%g sec)', timesToWatch(iT), minEpochLenght); end
            
            %-------------------------------------------------------------------------------------------
            epochLenght     = timesToWatch(iT)*samplingRate;
            NFFT            = 2^nextpow2(epochLenght);
            f               = samplingRate/2*linspace(0,1,NFFT/2+1);
            fx              = f( f>=minFreq & f<=maxFreq );
            fftVals{ind}    = zeros( numel(fx), nChan );
            iEpoch          = 0;
            for iE = 1:numel( stimOnsets )
                epoch   = sig( stimOnsets(iE):stimOnsets(iE)+epochLenght-1, : );
                for iCh = 1:nChan
                    Y = fft(epoch(:, iCh), NFFT)/epochLenght;
                    Y = 2 * abs( Y( 1:NFFT/2+1 ) );
                    fftVals{ind}(:, iCh) = fftVals{ind}(:, iCh) + Y( f>=minFreq & f<=maxFreq, :);
                end
            end
            iEpoch          = iEpoch + numel( stimOnsets );
            fftVals{ind}    = fftVals{ind} / iEpoch;
            
            
            subject{ind}    = sub{iS};
            condition{ind}  = cond{iC};
            frequency(ind)  = subset.frequency(1);
            oddball(ind)    = subset.oddball(1);
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
    frequency, ...
    oddball, ...
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
conditions = unique(meanFftDataset.condition);
ncond = numel(conditions);
stimTimes = unique(meanFftDataset.timeInSec);
nStimTimes = numel(stimTimes);

frequenciesOfInterest = meanFftDataset.frequency;
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




