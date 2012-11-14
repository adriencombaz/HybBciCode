function createEpochsP3

sessionName{1} = '2012-11-12-Adrien';

for i = 1:numel(sessionName)
%     createEpochs(sessionName{i}, 'eogCorrected', 1);
    createEpochs(sessionName{i}, 'nonEogCorreted', 1);
end

end


function createEpochs(sessionName, eogTag, doFiltering)

fprintf('\ntreating session %s (%s)\n', sessionName, eogTag);

% Init directories
%--------------------------------------------------------------------------
dataDir         = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\';
folderName      = fullfile(dataDir, sessionName, eogTag);
outputFolder    = fullfile(folderName, 'p3Epochs');
fileList        = cellstr(ls(sprintf('%s%s*.mat', folderName, filesep)));
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% do not consider the SSVEP baseline condition datafile (no P3 condition)
%--------------------------------------------------------------------------
temp        = strfind(fileList, '-SSVEP-baseline');
% iSsvepFile  = find ( cellfun(@(x) ~isempty(x), temp ) );
iSsvepFile  = cellfun(@(x) ~isempty(x), temp );
fileList(iSsvepFile)      = [];

% P3 epochs parameters
%--------------------------------------------------------------------------
tBeforeOnset    = 0.2; % lower time range in secs
tAfterOnset     = 0.8; % upper time range in secs

% filter parameters
%--------------------------------------------------------------------------
filter.fr_low_margin   = .2; % .5;
filter.fr_high_margin  = 40; % 20; % 25
filter.order           = 4; % 3
filter.type            = 'butter'; % Butterworth IIR filter


%
%--------------------------------------------------------------------------
nMaxCond            = 2*numel(fileList);
frequency           = zeros(nMaxCond, 1);
responseType        = cell(nMaxCond, 1);
erpResponse         = cell(nMaxCond, 1);
filename            = cell(nMaxCond, 1);
nEpochs             = zeros(nMaxCond, 1);
indCond             = 1;


for iF = 1:numel(fileList)
    
    
    % load data
    %----------------------------------------------------------------------
    fprintf('\tloading file %d out %d\n', iF, numel(fileList));
    load( fullfile( folderName, fileList{iF}) );
    nChan = numel(chanList); %#ok<NODEF>

    
    % epochs sizes (in datapoints)
    %--------------------------------------------------------------------------
    nl      = round(tBeforeOnset*fs); %#ok<NODEF>
    nh      = round(tAfterOnset*fs);
    range   = nh+nl+1;
    
    %
    %--------------------------------------------------------------------------
    nEvTot = 0;
    for iB = 1:numel(block), nEvTot = nEvTot + numel(block{iB}.p3Params.p3StateSeq); end
    
    %
    %--------------------------------------------------------------------------
    if iF == 1
        for iMc = 1:nMaxCond
            erpResponse{iMc} = zeros(range, nChan);
        end
    end
    
    %
    %--------------------------------------------------------------------------
    epochs      = zeros(range, nChan, nEvTot, 'single');
    blockNb     = zeros(nEvTot, 1);
    stimId      = zeros(nEvTot, 1);
    targetId    = zeros(nEvTot, 1);
    stimType    = zeros(nEvTot, 1);
    iEv         = 1;
    for iB = 1:numel(block)
        
        %
        no = find( diff( block{iB}.eventChan.p3 ) == 1 ) + 1;
        if numel(no) ~= numel(block{iB}.p3Params.p3StateSeq),
            error('mismatch in the number of events and onsets found')
        end
        evInds = iEv:iEv+numel(no)-1;
        
        
        % filter data
        if doFiltering
            [filter.a filter.b] = butter( filter.order, [ filter.fr_low_margin filter.fr_high_margin ] / ( fs/2 ) );
            %     sig = filtfilt( filter.a, filter.b, sig );
            for i = 1:size(block{iB}.sig, 2)
                block{iB}.sig(:,i) = filtfilt( filter.a, filter.b, block{iB}.sig(:,i) ); %#ok<AGROW>
            end
        end
        
        %
        for iE = 1:numel(evInds)
            epochs(:,:,evInds(iE)) = block{iB}.sig( no(iE)-nl : no(iE)+nh, : );
        end
        
        %
        blockNb(evInds) = iB;
        
        %
        stimId(evInds) = block{iB}.p3Params.p3StateSeq;
        
        %
        nItems  = numel( unique( block{1}.p3Params.p3StateSeq ) );
        temp    = repmat( block{iB}.p3Params.targetStateSeq, nItems*block{iB}.expParams.nRepetitions, 1);
        targetId(evInds) = temp(:);
        
        %
        stimType(evInds) = ( stimId(evInds) == targetId(evInds) );
        
        %
        iEv = iEv+numel(no);
        
    end
    
    
    % save epochs
    %--------------------------------------------------------------------------
    fprintf('\tsaving epochs\n');
    listOfVariablesToSave = { ...
        'epochs', ...
        'hdr', ...          % normally, not necessary
        'fs', ...
        'stimType', ...
        'blockNb', ...
        'stimId', ...
        'targetId', ...
        'stimType', ...
        'eogTag', ...
        'ssvepFreq', ...
        'chanList', ...
        'tBeforeOnset', ...
        'tAfterOnset' ...
        };
      
    save( fullfile( outputFolder, [fileList{iF}(1:end-4) '-p3-epochs.mat']), listOfVariablesToSave{:} );
    
    clear block hdr
    
    % 
    %--------------------------------------------------------------------------
    erpResponse{indCond}        = mean( epochs( :, :, stimType == 1 ), 3 );
    responseType{indCond}       = 'target';
    nEpochs(indCond)            = sum( stimType == 1 );
    frequency(indCond)          = ssvepFreq;
    filename{indCond}           = fileList{iF}(1:end-4);
    
    erpResponse{indCond+1}      = mean( epochs( :, :, stimType == 0 ), 3 );
    responseType{indCond+1}     = 'non-target';
    nEpochs(indCond+1)          = sum( stimType == 0 );
    frequency(indCond+1)        = ssvepFreq;
    filename{indCond+1}         = fileList{iF}(1:end-4);
    
    indCond                     = indCond + 2;

    
    % clearing some memory
    %--------------------------------------------------------------------------
    clear epochs 
    
end


% Create averaged epochs dataset
%--------------------------------------------------------------------------
erpResponse(indCond:end) = [];
responseType(indCond:end) = [];
nEpochs(indCond:end) = [];
frequency(indCond:end) = [];
filename(indCond:end) = [];

fs              = repmat(fs, indCond-1, 1);
chanList        = repmat({chanList}, indCond-1, 1);
tBeforeOnset    = repmat(tBeforeOnset, indCond-1, 1);

p3cutsDataset = dataset( ...
    frequency, ...
    responseType, ...
    nEpochs, ...
    erpResponse, ...
    filename, ...
    fs, ...
    chanList, ...
    tBeforeOnset ...
    ); %#ok<NASGU>

outputFileName  = 'meanP3epochs.mat';
save( fullfile(outputFolder, outputFileName), 'p3cutsDataset');



end