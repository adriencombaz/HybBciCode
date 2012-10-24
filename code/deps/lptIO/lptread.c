#include <stdio.h>
#include <mex.h>
#include "inpout32.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	double *address_ptr;
	/* short *value_ptr; */
	int address;
	short unsigned int value;

	if (nlhs != 1 || nrhs != 1)
		mexErrMsgTxt("Usage: value = lptread(port_address)");

	address_ptr = mxGetPr(prhs[0]);
	address = (unsigned int) (*address_ptr);
	mexPrintf( "address %d\n", address );
	if(!IsInpOutDriverOpen()) {
		/* Out32( address, (short)0 );  Try loading driver by attempting to write some value */
		Out32( 888, (short)0 ); /* Try loading driver by attempting to write some value */

		if( !IsInpOutDriverOpen() )
			mexErrMsgTxt("Failed to open inpout driver.");
	}

	value = Inp32( address );
	mexPrintf( "value %d\n", value );

	/* plhs[0] = mxCreateNumericMatrix( 1, 1, mxINT16_CLASS, mxREAL );
	value_ptr = mxGetPr( plhs[0]);
	*value_ptr = (double) value;
	*/
	plhs[0] = mxCreateDoubleScalar( (double) value );

	mexPrintf( "return value: %g\n", mxGetScalar( plhs[0] ) );

}

