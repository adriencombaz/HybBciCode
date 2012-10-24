% Add the local dependencies dir
%
if isempty( strfind( path, 'deps' ) ),
    disp( 'Adding the local dependencies dir [./deps] to path');
    addpath( './deps' );
    addpath( './deps/lptIO' );
    addpath( './deps/eog_calibration' );
%     savepath();
else
    disp( 'The local dependencies dir [./deps] is already in the path.');
end