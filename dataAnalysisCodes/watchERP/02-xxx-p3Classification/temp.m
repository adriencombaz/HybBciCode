cl;

for iS = 1:8
    
    folder = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP\02-ter-p3Classification\LinSvm\';
    folder = fullfile(folder, sprintf('subject_S%d', iS));
    filename = what( folder );
    filename = filename.mat;
    
    dates       = cellfun(@(x) x(:, 1:19), filename, 'UniformOutput', false);
    conditions  = cellfun(@(x) x(:, 21:end-15), filename, 'UniformOutput', false);
    nAve        = cellfun(@(x) x(:, end-13:end-4), filename, 'UniformOutput', false);
    
    
    fileSet = dataset( dates, conditions, nAve, filename );
    
    newFolder = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP\02-xxx-p3Classification\LinSvm_1RunsForTrain_128Hz_10cvSvm\';
    newFolder = fullfile(newFolder, sprintf('subject_S%d', iS));
    if ~exist( newFolder, 'dir'), mkdir(newFolder); end
    conds = unique(conditions);
    nA = unique(nAve);
    
    for iC = 1:numel(conds)
        for iA = 1:numel(nA)
            
            tempp = fileSet( ismember(conditions, conds{iC}) & ismember(nAve, nA{iA}), : );
            [~, run] = sort(tempp.dates);
            
            for iR = 1:size(tempp, 1)
                newFilename = sprintf('svm-%s-%s-fold%.2d.mat', tempp.conditions{iR}, tempp.nAve{iR}, run(iR));
                copyfile( fullfile(folder, tempp.filename{iR}), fullfile(newFolder, newFilename) );
            end
        end
    end
    
end

%%

for iS = 1:8
    
    folder = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP\02-ter-p3Classification\LinSvmPooled\';
    folder = fullfile(folder, sprintf('subject_S%d', iS));
    filename = what( folder );
    filename = filename.mat;
    
    newFolder = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciProcessedData\watchERP\02-xxx-p3Classification\LinSvmPooled_1RunsForTrain_128Hz_10cvSvm\';
    newFolder = fullfile(newFolder, sprintf('subject_S%d', iS));
    if ~exist( newFolder, 'dir'), mkdir(newFolder); end
    for iF = 1:numel(filename)
        newFilename = ['s' filename{iF}(8:end)];
        copyfile( fullfile(folder, filename{iF}), fullfile(newFolder, newFilename) );
    end

end