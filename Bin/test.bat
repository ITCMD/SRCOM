@echo off
setlocal EnableDelayedExpansion

:audiodevice
cls
echo Detecting Audio Devices...
set device=0
:detectadloop
set /a device+=1
for /f "tokens=1,2 delims=: skip=4" %%A in ('playsound Calibrate.mp3 %device%') do (
        if "%%~B"=="" goto breakdeva
        echo Device %device%: %%~B
        set device%device%=%%~B
        goto detectadloop
)
goto detectadloop
:breakdeva
pause