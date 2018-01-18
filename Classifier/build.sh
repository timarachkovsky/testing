#!/usr/bin/env bash
export MATLABPATH=$MATLABPATH:$(pwd)
echo "***************************** MATLABPATH *****************************"
echo $MATLABPATH

echo "***************************** PACKAGING *****************************"
ERROR=$(/usr/local/MATLAB/R2016b/bin/deploytool -package ComputeFramework.prj 3>&1 1>&2 2>&3 | tee /dev/stderr)

if [ "$ERROR" != "" ]; then
    echo "***************************** ERROR *****************************"
    echo $ERROR
    exit 1
else
    echo "Success"
fi
