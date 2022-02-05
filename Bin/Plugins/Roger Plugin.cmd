@echo off
if not exist PluginFiles\Rogers (
    echo Could not find Bin folder or Rogers Folder.
    echo Make sure you run this file from Simple Radio COM
    pause
    exit /B
)
:menu
cls
echo Simple Radio COM Roger Plugin.
echo Allows adding of custom roger beep.
echo.
echo 1] Enable / Change Roger
echo 2] Disable Roger
echo X] Exit
choice /c 12X
goto %errorlevel%

:3
exit /b

:1
cls
echo Enter roger option from list:
dir /b "PluginFiles\Rogers\*.wav"
set /p rogerbeep=">"
if not exist "PluginFiles\Rogers\%rogerbeep%" (
    echo Invalid roger option.
    echo Must be a wav file in the Bin\PluginFiles\Rogers folder.
    pause
    goto menu
)
echo @call settings.cmd>"PluginFiles\AfterTX\9z_roger.cmd"
echo @call playsound "PluginFiles\Rogers\%rogerbeep%" %RadioInput% ^>nul>>"PluginFiles\AfterTX\9z_roger.cmd"
goto menu

:2
cls
if not exist "PluginFiles\AfterTX\9z_roger.cmd" (
    echo Roger is not enabled.
    pause
    goto menu
)
del /f /q "PluginFiles\AfterTX\9z_roger.cmd"
echo Disabled.
pause
goto menu
