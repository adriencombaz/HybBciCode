function s = setfielddefault(s, fieldName, defaultValue)
if ~isfield(s, fieldName)
    s.(fieldName) = defaultValue;
end