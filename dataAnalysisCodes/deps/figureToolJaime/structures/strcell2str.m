function out = strcell2str(texts)
sep = '';
out = '';
for i = 1:numel(texts)
    if i>1
        sep = '/';
    end
    out = [out,sep,texts{i}];
end
