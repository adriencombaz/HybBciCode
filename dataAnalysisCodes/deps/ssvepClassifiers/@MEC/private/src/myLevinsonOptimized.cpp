#include <mex.h>
#include <cstring>
#define MAX_DEGREE 1024

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    if( 0 == nlhs )
        return;
    
    unsigned int i, j;
    unsigned int n;             // [input] denominator degree
    double *r;                  // [input] autocorrelation sequence
    double *a;                  // [output] desired vector of autocorrelation coefficients
    double aa[MAX_DEGREE+1];
    double ki;
    double s;
    double e;

	r = mxGetPr( prhs[0] );
    if( nrhs > 1 )
        n = (unsigned int)(*mxGetPr( prhs[1] ));
    else
        n = mxGetNumberOfElements( prhs[0] ) - 1;
        
    
    // prepare a (output) vector
    plhs[0] = mxCreateDoubleMatrix( 1, (mwSize) (n + 1), mxREAL ); //  a
    a = mxGetPr( plhs[0] );
//     memset( a, 0, sizeof(double)*(n + 1) ); // a = zeros( 1, n+1 );
    for( i = 1; i <= n; ++i )
        a[i] = 0.0;
    a[0] = 1.0;
    e = r[0];
    
    if( e != 0.0 )
    {
        aa[0] = 1;
        for( i = 1; i <= n; ++i )
            aa[i] = 0;

        ki = -r[1] / e;

        i = 1;
        while( i <= n )
        {
            
            s = 0.0;            
            for( j = 1; j < i; ++j )
                s -= aa[j] * r[i-j];

            ki =  ( s - r[i] ) / e;
            a[i] = ki;

            for( j = 1; j < i; ++j )
                a[j] = aa[j] + ki * aa[i-j];

            e *= ( 1 - ki * ki );
            ++i;
            //-----------------
            // now aa[] will be treated as a[] and vice versa

            if( i > n )
                break;

            s = 0.0;            
            for( j = 1; j < i; ++j )
                s -= a[j] * r[i-j];

            ki =  ( s - r[i] ) / e;
            aa[i] = ki;

            for( j = 1; j < i; ++j )
                aa[j] = a[j] + ki * a[i-j];

            e *= ( 1 - ki * ki );
            ++i;
            //---------------
        } // i loop

        // if n is even, the result is in aa[], while we need it in a[], so let's copy...
        if( !(n & 1) )
        {
            for( j = 0; j <= n; ++j )
                a[j] = aa[j];
        }

    } // of ( r[0] != 0.0 ) branch
    
    if( nlhs > 1 )
        plhs[1] = mxCreateDoubleScalar( e );
}