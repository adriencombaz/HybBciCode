function fixMfiles

originFolder = 'D:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP';
d = dir(originFolder);
isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];

for iFold = 1:numel(nameFolds)
    fullfolfder = fullfile(originFolder, nameFolds{iFold});
    fixMFilesRecursive(fullfolfder);
end

end

function fixMFilesRecursive(folder)

d = dir(folder);

nameFiles = {d.name}';
[~, ~, ext] = cellfun(@fileparts, {d.name}, 'UniformOutput', false);
namefile = nameFiles( ismember(ext, {'.m', '.R'}) );
fileList = cellfun(@(x) fullfile(folder, x), namefile, 'UniformOutput', false);
fixMfilesInDir(fileList)

isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];
if ~isempty(nameFolds)
    for iFold = 1:numel(nameFolds)
        fullfolfder = fullfile(folder, nameFolds{iFold});
        fixMFilesRecursive(fullfolfder);
    end
end

end

function fixMfilesInDir(fileList)

for ii= 1:length(fileList)
    
    text = fileread(fileList{ii});
    textNew = regexprep(text, 'watch-ERP', 'watchERP');
    if ~isequal(text, textNew)
        fprintf('editing %s\n', fileList{ii});
        fid = fopen(fileList{ii}, 'w');
        fwrite(fid, textNew, '*char');              %# write characters (bytes)
        fclose(fid);
    end
    
end

end