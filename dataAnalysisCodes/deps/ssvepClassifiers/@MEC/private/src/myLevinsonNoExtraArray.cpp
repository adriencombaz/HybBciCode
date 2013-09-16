#include <mex.h>
#include <string.h>

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    unsigned int i, j, m;
    unsigned int p;         // [input] denominator degree
    double *r;              // [input] autocorrelation sequence
    double *a;              // [output] desired vector of autocorrelation coefficients
    double e;
    double k, kk;
    double s;
    if( nrhs < 2 )
        mexErrMsgTxt( "Usage: [a, e] = myLevinsonOptiized( r, p )" );
    
    
    r = mxGetPr( prhs[0] );
    p = (unsigned int)(*mxGetPr( prhs[1] ));
    
    // prepare a (output) vector
    plhs[0] = mxCreateDoubleMatrix( 1, (mwSize) (p + 1), mxREAL ); //  a
    a = mxGetPr( plhs[0] );
    
//     memset( a, 0, sizeof(double)*(p + 1) ); // a = zeros( 1, p+1 );
    a[0] = 1.0;
    for( i = 1; i <= p; ++i )
        a[i] = 0;
    
    e = r[0];
    
    if( r[0] != 0.0 )
    {
        
        k = -r[1] / r[0];
        
        for( i = 1; i <= p; ++i )
        {
            s = 0.0;
            for( j = 1; j < i; ++j )
                s += a[j] * r[i-j];
            
            k =  ( r[i] - s ) / e;
            kk = 1 - k * k;
            a[i] = k;
            
            m = (i >> 1);
            
            for( j = 1; j <= m; ++j )
                a[j] = a[j] - k * a[i-j];
            
            for( j = m + 1; j < i; ++j )
                a[j] = a[j] * kk - a[i-j]*k;
            
            e *= kk;
            
        } // i loop
        
        for( j = 1; j <= p; ++j )
            a[j] = -a[j];
        
    } // of ( r[0] != 0.0 ) branch
    
    
    plhs[1] = mxCreateDoubleScalar( e );
}