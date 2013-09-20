function fixMfiles

d = dir('D:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP');
isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];

for iFold = 1:numel(nameFolds)
    fixMFilesRecursive(nameFolds{iFold});
end

end

function fixMFilesRecursive(folder)

d = dir(folder);

nameFiles = {d(~isub).name}';
namefileM = nameFiles( ~cellfun(@isempty, cellfun(@(x) strfind(x, '.m'), nameFiles, 'UniformOutput', false)) );
namefileR = nameFiles( ~cellfun(@isempty, cellfun(@(x) strfind(x, '.R'), nameFiles, 'UniformOutput', false)) );
fixMfilesInDir([namefileM ; namefileR])

isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];
if ~isempty(nameFolds)
    for iFold = 1:numel(nameFolds)
        fixMFilesRecursive(nameFolds{iFold});
    end
end

end

function fixMfilesInDir(fileList)

for ii= 1:length(fileList)
    l = textread(fileList{ii},'%s', 'delimiter', '\n');
    l = regexprep(l, 'HybBciProcessedData\watch-ERP', 'HybBciProcessedData\watchERP');
    % note this will overwrite the original file
    fid=fopen(fileList{ii}, 'wt');
    for jj=1:length(l)
        fprintf (fid, '%s\n', l{jj});
    end
    fclose(fid);
end

end