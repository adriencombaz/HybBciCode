function s = parseparameters(varargin)
if nargin == 1
    s = varargin{1};
    return
end
s = struct;
properties = varargin;
while length(properties) >= 2,
   property = properties{1};
   s.(property) = properties{2};
   properties = properties(3:end);
end