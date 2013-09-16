#include <mex.h>
#define MAX_DEGREE 1024

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    if( ( 0 == nlhs ) || ( 0 == nrhs ) )
        return;
    
    unsigned int i, j;
    unsigned int n;             // [input] denominator degree
    double *r;                  // [input] autocorrelation sequence
    double *a;                  // [output] desired vector of autocorrelation coefficients
    double aa[MAX_DEGREE+1];
    double e;
    double ki;
    double s;
    
    r = mxGetPr( prhs[0] );
    if( nrhs > 1 )
        n = (unsigned int)(*mxGetPr( prhs[1] ));
    else
        n = mxGetNumberOfElements( prhs[0] ) - 1;
    
    if( n > MAX_DEGREE )
        mexErrMsgTxt( "Too large n, must <= 1024" );
    
    // prepare a (output) vector
    plhs[0] = mxCreateDoubleMatrix( 1, (mwSize) (n + 1), mxREAL ); //  a
    a = mxGetPr( plhs[0] );
    
    for( i = 1; i <= n; ++i )
        a[i] = 0.0;
    a[0] = 1.0;
    e = r[0];
    
    if( nlhs > 2 ) // COMPUTE_REFLECTION_COEFFICIENTS
    {
        double *k;            // [output] reflection coefficients vector
        // prepare k (output) vector
        plhs[2] = mxCreateDoubleMatrix( (mwSize) n, 1, mxREAL);
        k = mxGetPr( plhs[2] );
        
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
                k[i-1] = -ki;
                
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
                k[i-1] = -ki;
                
                for( j = 1; j < i; ++j )
                    aa[j] = a[j] + ki * a[i-j];
                
                e *= ( 1 - ki * ki );
                ++i;
                //---------------
            }    // i loop
        }  //  of ( e != 0.0 ) branch
    } // of COMPUTE_REFLECTION_COEFFICIENTS branch
    else
    {
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
            }    // i loop
        } //  of ( e != 0.0 ) branch
    } // of DON'T COMPUTE REFLECTION COEFFICIENTS branch
    
    // if n is even, the result is in aa[], while we need it in a[], so let's copy...
    if( !(n & 1) )
    {
        for( j = 0; j <= n; ++j )
            a[j] = aa[j];
    }
    
    if( nlhs > 1 )
        plhs[1] = mxCreateDoubleScalar( e );
}