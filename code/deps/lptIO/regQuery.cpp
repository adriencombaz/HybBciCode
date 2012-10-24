// Quick&dirty replacement of MATLAB built-in function winqueryreg()
// by Nikolay Chumerin [https://sites.google.com/site/chumerin]

#include "mex.h"
#include <windows.h>
#include <string.h>

#define HIVEMAXLEN      64
#define PATHMAXLEN      1024
#define KEYNAMEMAXLEN   1024
#define VALMAXLEN       4096

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
    
    HKEY hKey;
    char regHiveName[HIVEMAXLEN];
    char path[PATHMAXLEN];
    char keyName[KEYNAMEMAXLEN];
    DWORD dwReturn[VALMAXLEN];
    DWORD dwBufSize = sizeof(dwReturn);
    DWORD dwKeyType = REG_SZ;
    
    if ( nrhs<3 || !mxIsChar( prhs[0] ) || !mxIsChar( prhs[1] ) || !mxIsChar( prhs[2] ) ) {
        mexErrMsgTxt( "regQuery should have 3 string arguments!" );
    }
    
    mxGetString( prhs[0], regHiveName, HIVEMAXLEN );
    mxGetString( prhs[1], path, PATHMAXLEN );
    mxGetString( prhs[2], keyName, KEYNAMEMAXLEN );
    
    if ( strcmp( regHiveName, "HKEY_CLASSES_ROOT" ) == 0 || strcmp( regHiveName, "HKCR" ) == 0 )
        hKey = HKEY_CLASSES_ROOT;
    else if ( strcmp( regHiveName, "HKEY_CURRENT_CONFIG" ) == 0 || strcmp( regHiveName, "HKCC" ) == 0 )
        hKey = HKEY_CURRENT_CONFIG;
    else if ( strcmp( regHiveName, "HKEY_CURRENT_USER" ) == 0 || strcmp( regHiveName, "HKCU" ) == 0 )
        hKey = HKEY_CURRENT_USER;
    else if ( strcmp( regHiveName, "HKEY_LOCAL_MACHINE" ) == 0 || strcmp( regHiveName, "HKLM" ) == 0 )
        hKey = HKEY_LOCAL_MACHINE;
    else if ( strcmp( regHiveName, "HKEY_PERFORMANCE_DATA" ) == 0 || strcmp( regHiveName, "HKPD" ) == 0 )
        hKey = HKEY_PERFORMANCE_DATA;
    else if ( strcmp( regHiveName, "HKEY_USERS" ) == 0 || strcmp( regHiveName, "HKU" ) == 0 )
        hKey = HKEY_USERS;
    else
        mexErrMsgTxt( "Can't recognize the registry hive!" );
    
    if( RegOpenKeyEx( hKey, path, 0, KEY_QUERY_VALUE, &hKey ) == ERROR_SUCCESS &&
        RegQueryValueEx( hKey, keyName, 0, &dwKeyType, (LPBYTE)dwReturn, &dwBufSize ) == ERROR_SUCCESS )
    {
        switch (dwKeyType)
        {
            case REG_SZ:
                plhs[0] = mxCreateString( (char*) &dwReturn );
                break;
            case REG_DWORD:
                plhs[0] = mxCreateDoubleMatrix( 1, 1, mxREAL );
                *mxGetPr( plhs[0] ) = (double) dwReturn[0];
                break;
            default: // treat as REG_BINARY
                plhs[0] = mxCreateNumericMatrix( 1, dwBufSize, mxUINT8_CLASS, mxREAL);
                memcpy( (unsigned char*) mxGetData( plhs[0] ), dwReturn, dwBufSize );
        }        
        RegCloseKey( hKey );
    }
    else
        plhs[0] = mxCreateDoubleMatrix( 0, 0, mxREAL );
    
}
