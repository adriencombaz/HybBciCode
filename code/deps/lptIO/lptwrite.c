#include <stdio.h>
#include <mex.h>
#include "inpout32.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	void *address_ptr;
	void *value_ptr;
	int address = 0;
	short value = 0;

	if(nrhs != 2)
		mexErrMsgTxt("Usage: lptwrite(port_address, value)");

	address_ptr = mxGetData(prhs[0]);
	value_ptr = mxGetData(prhs[1]);

	if(mxIsDouble(prhs[0]))
		address = (int) (*(double*)address_ptr);
	else if(mxIsUint32(prhs[0]))
		address = (int) (*(unsigned int*)address_ptr);
	else if(mxIsUint64(prhs[0]))
		address = (int) (*(unsigned long*)address_ptr);
	else
		mexErrMsgTxt("Parameter 'port_address' should be a double or unsigned integer value.");

	if(mxIsDouble(prhs[1]))
		value = (short) (*(double*)value_ptr);
	else if(mxIsUint32(prhs[1]))
		value = (short) (*(unsigned int*)value_ptr);
	else if(mxIsUint64(prhs[1]))
		value = (short) (*(unsigned long*)value_ptr);
	else
		mexErrMsgTxt("Parameter 'value' should be a double or unsigned integer value.");

	if(!IsInpOutDriverOpen()) {
		Out32(address, 0); /* Try loading driver by attempting to write some value */
		if(!IsInpOutDriverOpen())
			mexErrMsgTxt("Failed to open inpout driver.");
	}

	Out32(address, value);
}

