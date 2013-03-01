function ensurefields(s, varargin)
for i = varargin
    if ~isfield(s, i{1})
        error('Parameters do not contain value for "%s"', i{1})
    end
end