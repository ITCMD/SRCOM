@echo off
title SRCOMM Quick Recorder
setlocal EnableDelayedExpansion
if "%~1"=="Playback" goto playback
mode con:cols=25 lines=15
:top
cls
rem get and set variables
if exist settings.cmd (
    echo Loading . . .
    call settings.cmd
) ELSE (
    echo Settings File Missing.
    pause
    exit /B
)
if not exist QuickRecordings\ md QuickRecordings\
rem 0=no 2=yes 
set IsRecordingVoice=0
set IsRecordingRadio=0
set all=Record
set VoiceRecordStatus=[0mRecord My Voice
set RadioRecordStatus=[0mRecord Radio Output
set filenum=0
rem if %MicInput% is not "" add --dev-capture=%MicInput%
set devcapture=
if not "%MicInput%"=="" set devcapture=--dev-capture=%MicInput%
rem get next file number
:getnumloop
set /a filenum+=1
if exist "QuickRecordings\%filenum%.*" goto getnumloop
goto mainmenu


:mainmenu
cls
if %IsRecordingRadio%==0 (
    if %IsRecordingVoice%==0 set all=Record
)
echo | set /p="[96m"
type microphone.ascii
echo.
echo.
echo [90m=========================
echo   [92;4mSRCOMM QUICK RECORDER[0m
echo -------------------------
echo 1] %VoiceRecordStatus%
echo 2] %RadioRecordStatus%
echo 3] %all% Both
echo =========================
echo 4] Browse Recordings
echo [90mX] Quit
choice /n /c 1234x >nul 2>nul
call :timestamp
if %errorlevel%==1 goto togglevoice
if %errorlevel%==2 (
    if "%RadioOutput%"=="" goto mainmenu
    goto toggleradio
)
if %errorlevel%==3 (
    if "%RadioOutput%"=="" goto mainmenu
    goto toggleall
)
if %errorlevel%==4 goto playback
taskkill /f /im %VPID% >nul 2>nul
taskkill /f /im %RPID% >nul 2>nul
exit

rem if none recording - start with current number
rem if another is recording when starting one, new file number and file.

:togglevoice
if %IsRecordingVoice%==0 (
    if %IsRecordingRadio%==1 (
        taskkill /f /pid %RPID% >nul 2>nul
        set /a filenum+=1
        call :timestamp
        fmedia --record --dev-capture=%RadioOutput% --out="QuickRecordings\!timestamp!.radio.wav" --capture-buffer=1000 --background >quickrecorder.radio.temp 2>nul
        for /f "tokens=1,2 delims=PID" %%A in ('type quickrecorder.radio.temp') do (set RPID=%%B)
        del /f /q quickrecorder.radio.temp 2>nul >nul
    )
    set IsRecordingVoice=1
    set VoiceRecordStatus=[91mRecording Voice[0m
    set all=Stop
    fmedia --record %devcapture% --out="QuickRecordings\!timestamp!.voice.wav" --background >quickrecorder.voice.temp 2>nul
    for /f "tokens=1,2 delims=PID" %%A in ('type quickrecorder.voice.temp') do (set VPID=%%B)
    del /f /q quickrecorder.voice.temp 2>nul >nul
    goto mainmenu >nul 2>nul
) ELSE (
    taskkill /f /pid %VPID% >nul 2>nul
    set /a filenum+=1
    set IsRecordingVoice=0
    set VoiceRecordStatus=[0mRecord My Voice
    goto mainmenu
)

:toggleradio
if %IsRecordingRadio%==0 (
    rem if starting record and voice is recording, start new file so they match up
    if %IsRecordingVoice%==1 (
        taskkill /f /pid %VPID% >nul
        set /a filenum+=1
        call :timestamp
        fmedia --record %devcapture% --out="QuickRecordings\!timestamp!.voice.wav" --capture-buffer=1000 --background >quickrecorder.voice.temp 2>nul
        for /f "tokens=1,2 delims=PID" %%A in ('type quickrecorder.voice.temp') do (set VPID=%%B)
        del /f /q quickrecorder.voice.temp 2>nul >nul
    )
    set IsRecordingRadio=1
    set RadioRecordStatus=[91mRecording Radio Output[0m
    fmedia --record --dev-capture=%RadioOutput% --out="QuickRecordings\!timestamp!.radio.wav" --background >quickrecorder.radio.temp 2>nul
    for /f "tokens=1,2 delims=PID" %%A in ('type quickrecorder.radio.temp') do (set RPID=%%B)
    set all=Stop
    del /f /q quickrecorder.radio.temp 2>nul >nul
    goto mainmenu
) ELSE (
    taskkill /f /pid %RPID% >nul 2>nul
    set /a filenum+=1
    set IsRecordingRadio=0
    set RadioRecordStatus=[0mRecord Radio Output
    goto mainmenu
)

:toggleall
rem if either is recording, stop all.
if %IsRecordingRadio%==1 goto stopall
if %IsRecordingVoice%==1 goto stopall
rem otherwise start both
set IsRecordingRadio=1
set RadioRecordStatus=[91mRecording Radio Output[0m
fmedia --record --dev-capture=%RadioOutput% --out="QuickRecordings\!timestamp!.radio.wav" --capture-buffer=900 --background >quickrecorder.radio.temp 2>nul
for /f "tokens=1,2 delims=PID" %%A in ('type quickrecorder.radio.temp') do (set RPID=%%B)
del /f /q quickrecorder.radio.temp 2>nul >nul
set IsRecordingVoice=1
set VoiceRecordStatus=[91mRecording Voice[0m
fmedia --record %devcapture% --out="QuickRecordings\!timestamp!.voice.wav" --background >quickrecorder.voice.temp 2>nul
for /f "tokens=1,2 delims=PID" %%A in ('type quickrecorder.voice.temp') do (set VPID=%%B)
del /f /q quickrecorder.voice.temp 2>nul >nul
set all=Stop
goto mainmenu




:stopall
timeout /t 1 >nul
taskkill /f /pid %VPID% >nul 2>nul
taskkill /f /pid %RPID% >nul 2>nul
set /a filenum+=1
set IsRecordingRadio=0
set RadioRecordStatus=[0mRecord Radio Output
set IsRecordingVoice=0
set VoiceRecordStatus=[0mRecord My Voice
set all=Record
goto mainmenu

:timestamp
set timestamp=!filenum!.%date:/=-%.%time::=.%
exit /b

:playback
mode con:cols=60 lines=40
set DisplayMax=35
set skip=0
:ListRecordings
set DSPNum=0
for /f "tokens=1 delims==" %%A in ('set Done') do (
    set %%~A=
)
cls
echo | set /p="[96m"
type microphone.ascii
echo.
echo.
echo [90m============================================================
echo [92;4mSRCOMM QUICK RECORDER PlAYBACK MENU[0m
echo.
if %skip% LSS 1 (
    set skpvr=
) ELSE (
    set skpvr= skip=%skip%
)
for /f "tokens=1,2,3,4,5,6,7%skpvr% delims=." %%A in ('dir /b "QuickRecordings\"') do (
    if not "!Done%%~A!"=="1" (
        set /a DSPNum+=1
        set Done%%~A=1
        if exist "QuickRecordings\%%~A.*.radio.wav" (
            set startchars=R
        ) ELSE (
            set startchars=_
        )
        if exist "QuickRecordings\%%~A%.*.voice.wav" (
            set startchars=!starchars!V
        ) ELSE (
            set startchars=!starchars!_
        )
        echo !DSPNum!] !starchars! [92m%%~B [90m@ [96m%%~C:%%~D:%%~E.[90m%%~F[0m
        set file!DSPNum!=%%~A
    ) ELSE (
        set DualOn!DSPNum!=1
    )
    if "!DSPNum!"=="%DisplayMax%" goto DisplayBreak
)
:DisplayBreak
set Value=
echo.
echo [90m============================================================
echo Enter Number ^| Arrow Keys - Page ^| Enter - Select ^| X - Exit
echo.
echo | set /p=">"
:kbdentry
call kbd.exe
if %errorlevel%==49 set Value=%value%1& echo.| set /p="1"
if %errorlevel%==50 set Value=%value%2& echo.| set /p="2"
if %errorlevel%==51 set Value=%value%3& echo.| set /p="3"
if %errorlevel%==52 set Value=%value%4& echo.| set /p="4"
if %errorlevel%==53 set Value=%value%5& echo.| set /p="5"
if %errorlevel%==54 set Value=%value%6& echo.| set /p="6"
if %errorlevel%==55 set Value=%value%7& echo.| set /p="7"
if %errorlevel%==56 set Value=%value%8& echo.| set /p="8"
if %errorlevel%==57 set Value=%value%9& echo.| set /p="9"
if %errorlevel%==48 set Value=%value%0& echo.| set /p="0"
if %errorlevel%==75 (
    if %skip% GTR 0 set /a skip-=%DisplayMax%
    goto ListRecordings
)
if %errorlevel%==77 (
    set /a skip+=%DisplayMax%
    goto ListRecordings
)
if %errorlevel%==13 goto playvalue
if %errorlevel%==120 mode con:cols=25 lines=15&goto mainmenu
if %errorlevel%==8 mode con:cols=25 lines=15&goto mainmenu
if %errorlevel%==113 mode con:cols=25 lines=15&goto mainmenu
goto kbdentry


:playvalue
cls
if not exist "QuickRecordings\%value%.*" (
    echo Recording #%value% not found.
    pause
    goto mainmenu
)
echo [92mPlaying File %value%.
echo [90m============================================================
if "!DualOn%value%!"=="1" (
    set DualCount=1
    for /f "tokens=1 delims=" %%A in ('dir /b "QuickRecordings\%value%.*"') do (
        set File!DualCount!=%%~A
        set /a DualCount+=1
    )
    echo "!File1" "!File2!"
    call fmedia.exe --mix "QuickRecordings\!File1!" "QuickRecordings\!File2!"
) ELSE (
    for /f "tokens=1 delims=" %%A in ('dir /b "QuickRecordings\%value%.*"') do (set file=%%~A)
    call fmedia.exe "QuickRecordings\!file!"
)
echo.
:playbackmenu
echo 1] Play again
echo 2] Delete
echo 3] Export
echo X] Back
choice /c 123x
if %errorlevel%==4 goto :playback
if %errorlevel%==2 (
    echo Delete recording %value%?
    choice
    if !errorlevel!==2 goto playbackmenu
    del /f /q "QuickRecordings\%value%.*"
    goto playback
)
if %errorlevel%==1 goto playvalue
if %errorlevel%==3 goto export

:export
cls
echo Enter file path and name to export to
echo [90mExample: C:\Users\%username%\Desktop\Output.ogg[0m
echo ============================================================
echo Supported Extensions: .mp3 .ogg .wav
set /p output=">"
set output=%output:"=%
if "!DualOn%value%!"=="1" (
    call fmedia.exe --mix !File1! !File2! --out="%output%"
) ELSE (
    call fmedia.exe !file! --out="%output%"
)
pause
goto playbackmenu


