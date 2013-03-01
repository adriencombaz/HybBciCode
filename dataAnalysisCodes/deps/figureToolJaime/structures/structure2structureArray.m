function structArray = structure2structureArray(varargin)
%This function convert structures that contains fields with the same amount
%elements to an array of structures containing only one value of the fields elements 
s = parseparameters(varargin{:});

elements = structfun(@(x) ({(x)}), s, 'UniformOutput',1)';
fnames = fieldnames(s);
structArray = [];
nelms = numel(elements{1});
for i = 2:numel(elements)
    if nelms ~= numel(elements{i})
        disp('The number of elements per field must be identical for all fields');
        return;
    end
end

for i = 1:nelms
    substruct = struct;
    for j=1:numel(fnames)
        substruct.(fnames{j}) = elements{j}{i};
    end
    structArray = [structArray, substruct];
end





