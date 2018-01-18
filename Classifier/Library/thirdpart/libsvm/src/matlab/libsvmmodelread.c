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

static void fake_answer(mxArray *plhs[])
{
	plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
}

void mexFunction( int nlhs, mxArray *plhs[],
		int nrhs, const mxArray *prhs[] )
{
	char file_name[4096];
	struct svm_model * model;
	const char *error_msg;
	int i=0, nr_feat = 0;

	if(nrhs != 1)
	{
		mexPrintf("Usage: model_struct = libsvmmodelread('file_name');\n");
		fake_answer(plhs);
		return;
	}

	mxGetString(prhs[0], file_name, mxGetN(prhs[0])+1);

	if(file_name == NULL)
	{
		mexPrintf("Error: filename is NULL\n");
		fake_answer(plhs);
		return;
	}

	if((model=svm_load_model(file_name))==0)
	{
		mexPrintf("Can't open model file %s\n",file_name);
		fake_answer(plhs);
		return;
	}

	for(1;1;i++)
	{
		if(model->SV[0][i].index == -1 )
		{
			nr_feat = model->SV[0][i-1].index ;
			break;
		}
	}

	error_msg = model_to_matlab_structure(plhs, nr_feat, model);
	if(error_msg)
		mexPrintf("Error: can't convert libsvm model to matrix structure: %s\n", error_msg);

	svm_free_and_destroy_model(&model);
}
