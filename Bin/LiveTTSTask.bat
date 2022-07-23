@echo off
:reload
mode con:cols=80 lines=40
cls
title SRCOM LIVE Text-To-Speech Display
echo Loading Settings . . .
set TTSTimeout=600
set Reload=False
set Leave=False
set FinishQuit=False
Set AudioFile=NONE
if not exist "settings.cmd" (
    echo Error: Settings not found.
    pause
    exit /b
)
set livetts.rate=%voice.rate%
call ps1s.bat /tk "Simple Radio COM Ps1 Serial Interface"
echo Launching PTT PS1 Script . . .
if /i not "%ComPort%"=="NONE" start /MIN powershell -executionpolicy bypass -file "PTT Trigger.ps1" %COMPort% %TTSTimeout%
timeout /t 1 /nobreak >nul
set num=0

:cleared
cls
color 0a
type lttslogo.ascii
echo.
echo.
:loop
set /a num+=1
set /a nextnum=%num%+1
:loopsamenum
if exist "TTS\Update.cmd" (
    call "TTS\Update.cmd"
    del /f /q "TTS\Update.cmd"
)
if "%Clear%"=="True" goto :cleared
if "%reload%"=="True" goto :reload
if not exist "TTS\%num%.msg" (
    if not "%AudioFile%"=="NONE" goto audiofile
    if "%leave%"=="True" (
        call ps1s.bat /tk "Simple Radio COM Ps1 Serial Interface"
        exit
    )
    timeout /t 1 >nul
    goto loopsamenum
)
call :Convert "TTS\%num%.msg"
if /i not "%COMPort%"=="NONE" echo. >Transmit
if /i not "%COMPort%"=="NONE" timeout /t 2 /nobreak >nul
title SRCOM LIVE Text-To-Speech Display [ON-AIR]
call "fmedia.exe" "%file:"=%" --dev=%RadioInput% 2>nul
color 0a
title SRCOM LIVE Text-To-Speech Display
del /f /q "%file:"=%"
set premature=False
if /i not "%COMPort%"=="NONE" (
    if not exist Transmit set premature=True
)
if exist Transmit del /f /q Transmit
goto loop




:Convert
set /p custommessage=<"%~1"
set session=%random%%random%
echo Const SAFT48kHz16BitStereo = 39 >tts%session%.vbs
echo Const SSFMCreateForWrite = 3 ' Creates file even if file exists and so destroys or overwrites the existing file >>tts%session%.vbs
echo Dim oFileStream, oVoice >>tts%session%.vbs
echo Set oFileStream = CreateObject("SAPI.SpFileStream") >>tts%session%.vbs
echo oFileStream.Format.Type = SAFT48kHz16BitStereo >>tts%session%.vbs
echo oFileStream.Open "Audio%session%.wav", SSFMCreateForWrite >>tts%session%.vbs
echo Set oVoice = CreateObject("SAPI.SpVoice") >>tts%session%.vbs
echo Set oVoice.AudioOutputStream = oFileStream >>tts%session%.vbs
echo Set oVoice.Voice = oVoice.GetVoices.Item(%voice%) >>tts%session%.vbs
echo oVoice.Rate = %livetts.rate% >>tts%session%.vbs
echo oVoice.Volume = %voice.volume% >>tts%session%.vbs
echo oVoice.Speak "%custommessage%" >>tts%session%.vbs
echo oFileStream.Close >>tts%session%.vbs
cscript tts%session%.vbs >nul
if not %errorlevel%==0 (
    echo [91mLast message failed. Please check that the characters you entered are supported.
 
)
echo|set /p="[93m@ "
type "TTS\%num%.msg"
del /f /q tts%session%.vbs
del /f /q "%~1"
set file=Audio%session%.wav
exit /b


:audiofile
echo [96mPlaying Audio File: %AudioFile%
if /i not "%COMPort%"=="NONE" echo. >Transmit
if /i not "%COMPort%"=="NONE" timeout /t 2 /nobreak >nul
title SRCOM LIVE Text-To-Speech Display [ON-AIR]
call "fmedia.exe" "%AudioFile:"=%" --dev=%RadioInput% 2>nul
color 0a
title SRCOM LIVE Text-To-Speech Display
set premature=False
if /i not "%COMPort%"=="NONE" (
    if not exist Transmit set premature=True
)
if exist Transmit del /f /q Transmit
set AudioFile=NONE
goto loopsamenum