#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mex.h"

#include "../svm.h"
#include "svm_model_matlab.h"

#ifdef MX_API_VER
#if MX_API_VER < 0x07030000
typedef int mwIndex;
#endif
#endif

void mexFunction( int nlhs, mxArray *plhs[],
		int nrhs, const mxArray *prhs[] )
{
	char file_name[4096];
	struct svm_model *model;
	const char *error_msg;

	if(nrhs != 2)
	{
		mexPrintf("Usage: libsvmmodelwrite('file_name', model_struct);\n");
		return;
	}

	if(!mxIsStruct(prhs[1]))
	{
		mexPrintf("Error: second argument must be libSVM models struct.\n");			
		return;
	}

	mxGetString(prhs[0], file_name, mxGetN(prhs[0])+1);

	model = matlab_matrix_to_model(prhs[1], &error_msg);
	if (model == NULL)
	{
		mexPrintf("Error: can't read model: %s\n", error_msg);
		return;
	}

	if(svm_save_model(file_name,model))
	{
		mexPrintf("Can't save model to file %s\n", file_name);
	}

	svm_free_and_destroy_model(&model);
}
