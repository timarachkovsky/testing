ECHO OFF
SETLOCAL

SET MATLABPATH=%MATLABPATH%;%~dp0
SET ERROR_LOG_FILE=error.log
ECHO "***************************** MATLABPATH *****************************"
ECHO "%MATLABPATH%"

ECHO "***************************** PACKAGING *****************************"
CALL deploytool -package ComputeFramework.Win.prj 2> "%ERROR_LOG_FILE%"

SET /p ERROR=<%ERROR_LOG_FILE%
IF "%ERROR%" NEQ "" (
    ECHO "***************************** ERROR *****************************"
    ECHO "%ERROR%"

    EXIT /B 1
) ELSE (
    IF EXIST "%ERROR_LOG_FILE%" (
        ECHO "***************************** Clean up *****************************"
        DEL "%ERROR_LOG_FILE%"
    )

    ECHO Success
)

ENDLOCAL
