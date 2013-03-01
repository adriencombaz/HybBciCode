function p = ef(p, field_name, default_value)

% Ensure_field: Ensure that a struct field exists, else give it a default value.
% If the field existed in the input p, then the output p is identical.
% Else a new field is created, with the specified default value.
% function p = Ensure_field(p, field_name, default_value);
%
% Inputs:
% p:             Parameter struct.
% field_name:    Name of field (string).
% default_value: Value to set field to if field does not exist in p.
%
% Outputs:
% p:             Parameter struct.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Copyright: Cochlear Ltd
%     $Archive: /SPrint Research Software/Latest/Matlab/Process/Ensure_field.m $
%    $Revision: 2 $
%        $Date: 20/12/01 12:53p $
%      Authors: Brett Swanson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isfield(p, field_name)
    p = setfield(p, field_name, default_value);
end
