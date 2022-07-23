@echo off
set vrs=7
rem todo
rem Add QuickRecorder
rem Fix Stream in simple mode
Setlocal EnableDelayedExpansion
set Console=False
if not "%~1"=="" set Console=True
color 0f
if "%Console%"=="False" mode con:cols=80 lines=30
if "%Console%"=="False" cls
if "%Console%"=="False" title Simple Radio COM by W1BTR
if "%Console%"=="False" echo Loading Settings . . .
rem NOTE: Do not change these settings - change them in the settings menu after setup, or in Bin\settings.cmd.
set COMPort=COM5
set fromsimple=false
Set COMCheck=Nul
set Timeout=120
set RadioInput=0
set voice=0
set voice.rate=1
set voice.volume=100
set callsign=XXXXX
set Volume=100
Set MicInput=
if not exist Bin (
    echo Error: Bin Folder not found.
    if "%Console%"=="False" pause
    exit /B
)
cd bin
cls
echo.
color 0f
echo. | set /p="[93m"
type mentions.ascii
echo.
echo.
echo [0mLoading . . .
if exist Transmit del /f /q Transmit
if exist settings.cmd call settings.cmd
set livetts.rate=%voice.rate%
timeout /t 2 /nobreak >nul
if "%callsign%"=="XXXXX" goto firsttimesetup
rem Check audio device
if "%Console%"=="False" echo Self-Checking . . .
fmedia --list-dev 2>nul | find "%AudioCheck: - Default=%" >nul 2>nul
if not %errorlevel%==0 goto audioerror
:PassAudioCheck
rem Check COM device
if "%COMPort%"=="NONE" goto passselfcheck
for /f "delims=" %%A in ('wmic path win32_pnpentity get caption /format:table ^| find /i "(%COMPort%)"') do (set "COMComp=%%~A")
if not "%COMComp%"=="%COMCheck%" (
    goto comerror
)
:passselfcheck
echo Self-Check Pass.
call ps1s.bat /tk "Simple Radio COM Ps1 Serial Interface"
echo Launching PTT PS1 Script
if /i not "%ComPort%"=="NONE" start /MIN powershell -executionpolicy bypass -file "PTT Trigger.ps1" %COMPort% %Timeout%
goto mainmenu

:comerror
cls
echo ERROR: COM Port Change detected.
echo.
echo COM Port is set to %COMPort%.
echo Expected Name: %COMCheck%
echo   Pulled Name: %COMComp%
echo.
echo Press any key to set radio input audio output device again . . .
pause >nul
goto ComDevice

:COMDevice
cls
echo [92mDoes your radio interface use COM to trigger PTT?[0m
echo.
choice
if %errorlevel%==2 (
    set COMPort=NONE
    set ComCheck=NONE
    goto settings
)
echo [92mWhat COM port is your interface connected to?
echo [90mPort name is in parenthases.
echo.
echo [96mAvailable Com Ports:[0m
wmic path win32_pnpentity get caption /format:table | find "COM"
echo [90mInclude COM in entry. Example: COM5[0m
echo.
echo.
set /p COMPort=">"
echo.
wmic path win32_pnpentity get caption /format:table | find /i "(%COMPort%)" >nul 2>nul
if not "%errorlevel%"=="0" (
    echo COM Port "%COMPort%" was not found.
    pause
    goto COMDevice
)
for /f "delims=" %%A in ('wmic path win32_pnpentity get caption /format:table ^| find /i "(%COMPort%)"') do (set COMCheck=%%~A)
echo Fantastic. We'll use COM port %COMPort% to trigger PTT.
goto settings

:firsttimesetup
cls
color 0f
type logo.ascii
echo.
echo.
echo [96mWelcome to the Simple Radio COM Setup Wizard.
echo Make sure your digirig or VOX interface is setup and plugged in.
echo Make sure you know what COM port the digirig uses, and make sure you know
echo which audio ouptut device goes to the radio's mic input.
echo Note that you can change all these settings later on.
echo.
echo [92mFirst and foremost, what's your callsign?[0m
echo This will be used in emergency broadcast mode, and if any plugins require it.
echo.
set /p callsign=">"
echo.
echo Great. Hi there, %callsign%.
:comportback
echo.
echo [92mNow we need to know if your device uses COM to trigger PTT (Digirig), or if it uses VOX (Signalink).
echo [91mNote: At this time, SRCOM only suports the Digirig for COM control (or other devices that use the RTS pin).[0m.
echo.
echo Does your radio interface use COM to trigger PTT?[0m
echo.
choice
if %errorlevel%==2 (
    set COMPort=NONE
    set ComCheck=NONE
    echo.
    echo Alright, no COM port, VOX it is.
    goto firsttimeaudio
)
echo [92mOkay, what COM port is your interface connected to?
echo [90mPort name is in parenthases.
echo.
echo [96mAvailable Com Ports:[0m
wmic path win32_pnpentity get caption /format:table | find "COM"
echo [90mInclude COM in entry. Example: COM5[0m
echo.
set /p COMPort=">"
echo.
wmic path win32_pnpentity get caption /format:table | find /i "(%COMPort%)" >nul 2>nul
if not "%errorlevel%"=="0" (
    echo COM Port "%COMPort%" was not found.
    pause
    goto comportback
)
for /f "delims=" %%A in ('wmic path win32_pnpentity get caption /format:table ^| find /i "(%COMPort%)"') do (set COMCheck=%%~A)
echo Fantastic. We'll use COM port %COMPort% to trigger PTT.
:firsttimeaudio
echo.
echo [92mNext, what audio device is your radio's mic input connected to?[0m
echo ======================================================================
:setupa
set device=True
if exist devlist.temp del /f /q devlist.temp
for /f "skip=1 delims=" %%A in ('call fmedia --list-dev 2^>nul') do (
    if "%%~A"=="Capture:" goto breaksetupa
    if "!device!"=="True" (
        echo [93m%%~A
        set device=False
        echo "%%~A">>devlist.temp
    ) ELSE (
        echo [90m%%~A
        set device=True
    )
)
:breaksetupa
echo ======================================================================
echo [92mEnter Device number to act as INPUT to radio:
set /p NewRadioInput=">#"
rem strip of # in case of dumb user
set NewRadioInput=%NewRadioInput:#=%
rem check for existance of device
find "device #%NewRadioInput%: " "devlist.temp" >nul 2>nul
if not %errorlevel%==0 (
    echo Device #%NewRadioInput% was not found.
    pause
    goto firsttimeaudio
)
for /f "skip=1 delims=" %%A in ('find "device #%NewRadioInput%: " "devlist.temp"') do (
    set AudioCheck=%%~A
)
echo.
echo Use Device %AudioCheck%?
choice
if %errorlevel%==2 goto :firsttimeaudio
set RadioInput=%NewRadioInput%
echo.
echo Alright %callsign%, we'll use%AudioCheck%
echo as your radio's mic input.
:NewRadioOutput
echo.
echo [92mDo you have a device you wish to record your Radio's output from?[0m
echo =======================================================================
echo [90mThis is not required, and will not automatically play your radio's audio
echo through your computer. It is only used to record conversations in the QuickRecorder.
echo.
choice
if %errorlevel%==2 goto doneinitialsetup

:setupi
set device=True
set capture=False
if exist devlist.temp del /f /q devlist.temp
for /f "skip=1 delims=" %%A in ('call fmedia --list-dev 2^>nul') do (
    if "!capture!"=="True" (
        if "!device!"=="True" (
            echo [93m%%~A
            set device=False
            echo "%%~A">>devlist.temp
        ) ELSE (
            echo [90m%%~A
            set device=True
        )
    )
    if "%%~A"=="Capture:" set capture=True
)
echo ======================================================================
echo [92mEnter Device number to act as OUTPUT from Radio:
set /p NewRadioOutput=">#"
rem strip of # in case of dumb user
set NewRadioOutput=%NewRadioOutput:#=%
rem check for existance of device
find "device #%NewRadioOutput%: " "devlist.temp" >nul 2>nul
if not %errorlevel%==0 (
    echo Output Device #%NewRadioOutput% was not found.
    pause
    goto newradiooutput
)
for /f "skip=1 delims=" %%A in ('find "device #%NewRadioOutput%: " "devlist.temp"') do (
    set OutputCheck=%%~A
)
echo.
echo Use Device %OutputCheck%?
choice
if %errorlevel%==2 goto newradiooutput
set RadioOutput=%NewRadioOutput%

:doneinitialsetup
echo.
echo [92mThat's it for the initial setup.[0m
echo.
echo But, there are more settings to explore in the settings menu, such
echo as the TTS voice, voice speed, and voice volume, or timeout settings.
echo @set "COMPort=%COMPort%">settings.cmd
echo @set "Timeout=%Timeout%">>settings.cmd
echo @set "RadioInput=%RadioInput%">>settings.cmd
echo @set "AudioCheck=%AudioCheck%">>settings.cmd
echo @set "RadioOutput=%RadioOutput%">>settings.cmd
echo @set "OutputCheck=%OutputCheck%">>settings.cmd
echo @set "MicInput=%MicInput%">>settings.cmd
echo @set "voice=%voice%">>settings.cmd
echo @set "voice.rate=%voice.rate%">>settings.cmd
echo @set "voice.volume=%voice.volume%">>settings.cmd
echo @set "callsign=%callsign%">>settings.cmd
echo @set "COMCheck=%COMCheck%">>settings.cmd
echo.
pause
goto mainmenu

:console
if /i "%~1"=="audio" goto csaud
if /i "%~1"=="tts" goto cstts
if /i "%~1"=="schedule" goto csschedule
if /i "%~1"=="help" goto help
goto help

:help
echo Simple Radio COM by W1BTR
echo.
echo Usage: Tool is designed to be run directly, but it
echo        offers some command line options for scripting.
echo.
echo Learn more at https://github.com/ITCMD/Simple-Radio-COM
echo.
echo - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
echo.
echo "%~nx0" audio "file" "Output Device (optional)"
echo.
echo      Allows playing of an audio file to the radio via output device.
echo.
echo "%~nx0" tts "text message" "Output Device (optional)"
echo.
echo      Allows text to speech conversion and playback to the radio via output device.
echo.
echo "%~nx0" schedule "file" "Starting Time" "Output Device (optional)"
echo.
echo      Allows audio files to be played at a specific time and / or date.
echo.
echo "%~nx0" help
echo.
echo      Displays this help menu.
exit /b
:csschedule
if "%~2"=="" (
    echo "Radio control.bat" schedule "file" "schedule" "outpt [optional]"
    exit /B
)
if "%~3"=="" (
    echo "Radio control.bat" schedule "file" "schedule" "outpt [optional]"
    exit /B
)
set source=%~2
if not exist "%source%" (
        if exist "..\%source%" (
            set source=..\%source%
        ) ELSE (
            echo "File not found: %source%"
            exit /B
        )
)
set Starts=%~3
powershell Get-Date '%Starts%'
if %errorlevel%==1 (
    cls
    echo Invalid Date/Time.
    exit /b
)
if not exist "%source%" (
        if exist "..\%source%" (
            set source=..\%source%
        ) ELSE (
            echo "File not found: %source%"
            exit /B
        )
)
if not "%~4"=="" set RadioInput=%~4
set session=%random%%random%
echo converting file
call ffmpeg -y -i "%source%" "%cd%\%session%.wav" >nul 2>nul
set file=%session%.wav
echo Preparing to transmit audio file: %file%

:csschedloop
for /f "tokens=1* delims=" %%A in ('powershell -executionpolicy bypass -File "CompareDateToNow.ps1" "%starts%"') do ( 
    if not "%%~A"=="True" (
        timeout /t 2 /nobreak >nul
        goto csschedloop
    )
)
echo Starting TX
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto mainmenu
if /i not "%COMPort%"=="NONE" echo. >Transmit
if /i not "%COMPort%"=="NONE" timeout /t 2 /nobreak >nul
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\BeforeTX\*.cmd" /b') do (
        call "PluginFiles\BeforeTX\%%~a"
    )
)
call "fmedia.exe" "%file:"=%" --dev=%RadioInput% 2>nul
rem call "playsound.exe" "%file%" %RadioInput%
if exist "PluginFiles\AfterTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\AfterTX\*.cmd" /b') do (
        call "PluginFiles\AfterTX\%%~a"
    )
)
echo Stopping TX
set premature=False
if not exist Transmit echo ### WARNING: Transmission was stopped before message is finished. Raise timeout.
if exist Transmit del /f /q Transmit
del /f /q %file%
timeout /t 2 /nobreak >nul
exit /b

:csaud
if "%~2"=="" (
    echo "Radio control.bat" audio "file" "outpt [optional]"
    exit /B
)
set source=%~2
if not exist "%source%" (
        if exist "..\%source%" (
            set source=..\%source%
        ) ELSE (
            echo "File not found: %source%"
            exit /B
        )
)
if not "%~3"=="" set RadioInput=%~3
set session=%random%%random%
echo converting file
call ffmpeg -y -i "%source%" "%cd%\%session%.wav" 
set file=%session%.wav
echo Starting TX
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto mainmenu
if /i not "%ComPort%"=="NONE" echo. >Transmit
if /i not "%ComPort%"=="NONE" timeout /t 2 /nobreak >nul
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\BeforeTX\*.cmd" /b') do (
        call "PluginFiles\BeforeTX\%%~a"
    )
)
call fmedia "%file%" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
rem call "playsound.exe" "%file%" %RadioInput%
if exist "PluginFiles\AfterTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\AfterTX\*.cmd" /b') do (
        call "PluginFiles\AfterTX\%%~a"
    )
)
echo Stopping TX
set premature=False
if not exist Transmit echo ### WARNING: Transmission was stopped before message is finished. Raise timeout.
if exist Transmit del /f /q Transmit
del /f /q %file%
timeout /t 1 /nobreak >nul
exit /b

:cstts
if "%~2"=="" (
    echo "Radio control.bat" tts "text" "outpt [optional]"
    exit /B
)
set session=DISTRESS%random%
echo Const SAFT48kHz16BitStereo = 39 >tts%session%.vbs
echo Const SSFMCreateForWrite = 3 ' Creates file even if file exists and so destroys or overwrites the existing file >>tts%session%.vbs
echo Dim oFileStream, oVoice >>tts%session%.vbs
echo Set oFileStream = CreateObject("SAPI.SpFileStream") >>tts%session%.vbs
echo oFileStream.Format.Type = SAFT48kHz16BitStereo >>tts%session%.vbs
echo oFileStream.Open "Audio%session%.wav", SSFMCreateForWrite >>tts%session%.vbs
echo Set oVoice = CreateObject("SAPI.SpVoice") >>tts%session%.vbs
echo Set oVoice.AudioOutputStream = oFileStream >>tts%session%.vbs
echo Set oVoice.Voice = oVoice.GetVoices.Item(%voice%) >>tts%session%.vbs
echo oVoice.Rate = %voice.rate% >>tts%session%.vbs
echo oVoice.Volume = %voice.Volume% >>tts%session%.vbs
echo oVoice.Speak "%~2" >>tts%session%.vbs
echo oFileStream.Close >>tts%session%.vbs
cscript tts%session%.vbs >nul
del /f /q tts%session%.vbs
set file=Audio%session%.wav
if not "%~3"=="" set RadioInput=%~3
echo Starting TX
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto mainmenu
if /i not "%ComPort%"=="NONE" echo. >Transmit
if /i not "%ComPort%"=="NONE" timeout /t 2 /nobreak >nul
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\BeforeTX\*.cmd" /b') do (
        call "PluginFiles\BeforeTX\%%~a"
    )
)
call fmedia "%file%" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
if exist "PluginFiles\AfterTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\AfterTX\*.cmd" /b') do (
        call "PluginFiles\AfterTX\%%~a"
    )
)
echo Stopping TX
del /f /q "%file%"
set premature=False
if not exist Transmit echo ### WARNING: Transmission was stopped before message is finished. Raise timeout.
if exist Transmit del /f /q Transmit
timeout /t 1 /nobreak >nul
exit /b


:mainmenu
if /i "%Console%"=="true" goto console 
if not "%deletefile%"=="" del /f /q "%deletefile%"
set deletefile=
cls
color 0f
type logo.ascii
echo.
echo                                    [%callsign%]
echo [92m1] Basic Transmit
echo [96m2] Transmit Audio File
echo [95m3] Transmit Custom TTS Message
echo [93m4] Recordings and Playback
echo [94m5] Live Text-To-Speech Mode
echo [31m6] DISTRESS MODE
echo [33mR] Open Quick Recorder[0m
echo S] Settings
echo [90mP] Plugins[0m
echo A] About
echo [90mX] Exit[0m
choice /c x123456SPRA
if %errorlevel%==1 exit /B
set /a erl=%errorlevel%-1
if %erl%==1 goto basic
if %erl%==2 goto audio
if %erl%==3 goto custom
if %erl%==4 goto recplay
if %erl%==5 goto livetts
if %erl%==6 goto distress
if %erl%==7 goto settings
if %erl%==8 goto plugins
if %erl%==9 (
    start "" "QuickRecorder.bat"
    goto mainmenu
)
if %erl%==10 goto about
exit /b %erl%

:about
cls
echo.[93m
type mentions.ascii
echo.
echo.
echo [96mHi there, I'm Lucas Elliott, W1BTR. I'm the author of Simple-Radio-COM
echo.
echo I made this program because I wanted a program that could allow me to control
echo my radio from my computer. I wanted something simple and easy to use for simple
echo tasks.
echo Using your computer's microphone on your radio was always possible, but it 
echo required numerous programs and cumbersome setup each time you wanted to just
echo make a quick contact. This program is ment to be a simple solution.

echo SRCOMM is the everything-but-digital simple radio control that I wanted.
echo.[0m

pause
goto mainmenu


:UpdateUTC
REM get UTC times:
for /f %%a in ('wmic Path Win32_UTCTime get Year^,Month^,Day^,Hour^,Minute^,Second /Format:List ^| findstr "="') do (set %%a)
Set Second=0%Second%
Set Second=%Second:~-2%
Set Minute=0%Minute%
Set Minute=%Minute:~-2%
Set Hour=0%Hour%
Set Hour=%Hour:~-2%
Set Day=0%Day%
Set Day=%Day:~-2%
Set Month=0%Month%
Set Month=%Month:~-2%
set UTCTIME=%Hour%:%Minute%:%Second%
set UTCDATE=%Year%%Month%%Day%
exit /b

:livetts
call cmds.bat /ts "SRCOM LIVE Text-To-Speech Display" >nul
if %errorlevel%==1 (
    start "" "LiveTTSTask.bat"
)
:cleartts
cls
type logo.ascii
echo.
echo.
echo [92mLive TTS Mode[0m
echo ============================================================================
echo Press the [Space] bar to start transmitting, then send as many words as you
echo want at a time, using the [Enter] key to transmit twhat you have typed in.
echo ============================================================================
echo [90mEnter "/quit" to quit amd "/?" for a list of more commands[0m
echo ============================================================================
if not exist "TTS\" md "TTS\"
set ttsnum=1
call focuson.bat "Simple Radio COM by W1BTR" >nul
:liveentry
set /p TTSEntry=">"
rem strip quotes
set "TTSEntry=%TTSEntry:"=%"
rem update UTC time
call :UpdateUTC
rem handle commands
if /i "%TTSEntry%"=="/?" goto ttscommands
if /i "%TTSEntry%"=="/quit" goto quitts
if /i "%TTSEntry%"=="/x" goto quitts
if /i "%TTSEntry%"=="/leave" goto leavetts
if /i "%TTSEntry%"=="/l" goto leavetts
if /i "%TTSEntry%"=="/c" goto cleartts
if /i "%TTSEntry%"=="/clear" goto cleartts
if /i "%TTSEntry%"=="/speed" (
    echo Enter new TTS Speed [.1-10]
    set /p livetts.rate=">"
    echo set "livetts.rate=!livetts.rate!">"TTS\Update.cmd"
    goto liveentry
)
if /i "%TTSEntry%"=="/reload" (
    del /f /q "TTS\*.msg" 2>nul 
    call ps1s.bat /tk "Simple Radio COM Ps1 Serial Interface"
    call cmds.bat /tk "SRCOM LIVE Text-To-Speech Display" >nul 2>nul
    call cmds.bat /tk "SRCOM LIVE Text-To-Speech Display [ON AIR]" >nul 2>nul
    goto livetts
)
if /i "%TTSEntry%"=="/r" (
    del /f /q "TTS\*.msg" 2>nul 
    call ps1s.bat /tk "Simple Radio COM Ps1 Serial Interface"
    call cmds.bat /tk "SRCOM LIVE Text-To-Speech Display" >nul 2>nul
    call cmds.bat /tk "SRCOM LIVE Text-To-Speech Display [ON AIR]" >nul 2>nul
    goto livetts
)
if /i "%TTSEntry%"=="/clear" (
    echo set "clear=True">>"TTS\Update.cmd"
    goto cleartts
)
if /i "%TTSEntry%"=="/c" (
    echo set "clear=True">>"TTS\Update.cmd"
    goto cleartts
)
if /i "%TTSEntry:~0,5%"=="/play" goto playfiletts
if /i "%TTSEntry%"=="/quit" goto quitts
)
if /i "%TTSEntry%"=="/q" (
    start "" "QuickRecorder.bat"
    goto liveentry
)

if /i "%TTSEntry%"=="/QuickRecord" (
    start "" "QuickRecorder.bat"
    goto liveentry
)

rem check if non-command command
if "%TTSEntry:~0,1%"=="/" (
    echo Command not found.
    goto liveentry
)
rem handle variables
set "TTSEntry=!TTSEntry:$CS=%CALLSIGN%!"
set "TTSEntry=!TTSEntry:$Date=%Date%!"
set "TTSEntry=!TTSEntry:$Time=%time::= %!"
set "TTSEntry=%TTSEntry:$SRC=I am using a program called SRCOMM to speak for me%"
set "TTSEntry=!TTSEntry:$CQ=CQ CQ CQ %callsign%, %callsign% calling CQ any stations over!"
set "TTSEntry=!TTSEntry:$CQDX=CQ DX CQ DX %callsign%, %callsign% calling CQ DX over!"
set "TTSEntry=!TTSEntry:$UTCT=%UTCTIME::= %!"
set "TTSEntry=!TTSEntry:$UTCD=%UTCDATE%!"
:setuplooptts
if exist "TTS\%ttsnum%.msg" (
    set /a ttsnum+=1
    goto setuplooptts
)
echo %TTSEntry% >"TTS\%ttsnum%.msg"
set /a ttsnum+=1
goto :liveentry

:playfiletts
if not exist "%TTSEntry:~6%" (
    echo [91mCould not find file: "%TTSEntry:~6%"[0m
    goto liveentry
)
echo set "AudioFile=%TTSEntry:~6%">>"TTS\Update.cmd"
echo [96mOK[0m
goto liveentry

:quitts
call cmds.bat /tk "SRCOM LIVE Text-To-Speech Display" >nul 2>nul
call cmds.bat /tk "SRCOM LIVE Text-To-Speech Display [ON AIR]" >nul 2>nul
if exist Transmit del /f /q Transmit
if exist TTS\*.msg del /f /q TTS\*.msg
if exist TTS\*.cmd del /f /q TTS\*.cmd
goto mainmenu

:leavetts
echo set "Leave=True">>"TTS\Update.cmd"
goto mainmenu

:ttscommands
cls
echo [96mLive TTS Commands list:[0m
echo.
echo /?             [/?] - Show this page
echo /quit          [/x] - End all transmissions and exit
echo /leave         [/l] - Exit but finish transmissions
echo /reload        [/r] - Cancel transmissions and reload the display
echo /clear         [/c] - Clear SRCOM and Display Window
echo.
echo /play [File]   [/p] - Play audio File
echo /QuickRecord   [/q] - Launch Quick-recorder
echo.
echo [96mVariables are:[0m
echo            $CS      - Your callsign (%CALLSIGN%)
echo            $Date    - Current date (%date%)
echo            $Time    - Current local time (%time%)
echo            $UTCT    - Current UTC time (%UTCTIME%)
echo            $UTCD    - Current UTC date (%UTCDATE%)
echo            $SRC     - (I am using a program called SRCOMM to speak for me)
echo            $CQ      - (CQ CQ CQ %callsign% %callsign% calling CQ any stations over)
echo            $CQDX    - (CQ DX CQ DX %callsign% %callsign% calling CQ DX over)
echo.
pause
goto cleartts



:recplay
cls
type logo.ascii
echo.
echo [92mRecord and Playback Messages[0m
echo Press any number to transmit recording.
echo ============================================================================
if not exist PlaybackRecordings md PlayBackRecordings
set rec=0
:recloop
if exist "PlaybackRecordings\%rec%.wav" (
    set /p temprecname=<"PlaybackRecordings\%rec%.ini"
    echo %rec%] !temprecname!
) ELSE (
    echo [90m%rec%] Not Set. Press R to open record menu.[0m
)
if %rec%==9 goto endrecloop
set /a rec+=1
goto recloop
:endrecloop
echo ============================================================================
echo [90mNote: Plugins do not apply to recordings.
echo [92m[R] - Record [L] - Listen [D] - Delete [X] - Exit[0m
echo ============================================================================
choice /c 1234567890rldx /N >nul
if %errorlevel% LSS 10 (
    set play=%errorlevel%
    goto playrec
)
if %errorlevel%==10 (
    set play=0
    goto playrec
)
if %errorlevel%==11 goto recnew
if %errorlevel%==12 goto reclisten
if %errorlevel%==13 goto recdelete
if %errorlevel%==14 (
    if "%fromsimple%"=="true" goto :basic
    if "%fromlivetts%"=="true" goto :livetts
    goto mainmenu
)


:playrec
if not exist "PlaybackRecordings\%play%.wav" (
    set recnum=%play%
    goto startrecnew
)
cls
type logo.ascii
echo.
echo.
echo Transmitting Recording . . .
echo.
color e0
if /i not "%ComPort%"=="NONE" echo. >Transmit
if /i not "%ComPort%"=="NONE" timeout /t 2 /nobreak >nul
echo [102;31m[ON AIR][0m
title Simple Radio COM by W1BTR [ON AIR]
call fmedia "PlaybackRecordings\%play%.wav" --dev=%RadioInput% --volume=%Volume%
rem call "playsound.exe" "PlaybackRecordings\%play%.wav" %RadioInput%
echo Ending Transmission
set premature=False
if /i not "%COMPort%"=="NONE" (
    if not exist Transmit set premature=True
)
if exist Transmit del /f /q Transmit
color e0
timeout /t 1 /nobreak >nul
color 0f
title Simple Radio COM by W1BTR

if "%premature%"=="True" (
    echo WARNING: Transmission ended before end of file. 
    echo Make sure you accomodate for any start and stop tones in the timeout.
    echo.
    pause
)
goto recplay


:recdelete
echo.
echo Enter Recording Number to delete
echo [90mEnter X to cancel[0m
set /p recnum=">"
if "%recnum%"=="0" goto startrecdel
if "%recnum%"=="1" goto startrecdel
if "%recnum%"=="2" goto startrecdel
if "%recnum%"=="3" goto startrecdel
if "%recnum%"=="4" goto startrecdel
if "%recnum%"=="5" goto startrecdel
if "%recnum%"=="6" goto startrecdel
if "%recnum%"=="7" goto startrecdel
if "%recnum%"=="8" goto startrecdel
if "%recnum%"=="9" goto startrecdel
goto recplay

:startrecdel
cls
echo [91mDeleteRecording #%recnum%
set /p temprecname=<"PlaybackRecordings\%recnum%.ini"
echo [93m%temprecname%[91m
echo.
echo Are you sure?[0m
choice
if %errorlevel%==2 goto recplay
del /f /q "PlaybackRecordings\%recnum%.wav"
del /f /q "PlaybackRecordings\%recnum%.ini"
goto recplay

:reclisten
echo.
echo Enter Recording Number to Listen to
echo [90mEnter X to cancel[0m
set /p recnum=">"
if "%recnum%"=="0" goto startrecplay
if "%recnum%"=="1" goto startrecplay
if "%recnum%"=="2" goto startrecplay
if "%recnum%"=="3" goto startrecplay
if "%recnum%"=="4" goto startrecplay
if "%recnum%"=="5" goto startrecplay
if "%recnum%"=="6" goto startrecplay
if "%recnum%"=="7" goto startrecplay
if "%recnum%"=="8" goto startrecplay
if "%recnum%"=="9" goto startrecplay
goto recplay

:startrecplay
cls
echo [92mPlaying Recording #%recnum% . . .
set /p temprecname=<"PlaybackRecordings\%recnum%.ini"
echo [90m%temprecname%[93m
echo.
fmedia "PlaybackRecordings\%recnum%.wav" >nul
echo.[0m
pause
goto recplay

:recnew
echo.
echo Enter Recording Number to Overwrite
echo [90mEnter X to cancel[0m
set /p recnum=">"
if "%recnum%"=="0" goto startrecnew
if "%recnum%"=="1" goto startrecnew
if "%recnum%"=="2" goto startrecnew
if "%recnum%"=="3" goto startrecnew
if "%recnum%"=="4" goto startrecnew
if "%recnum%"=="5" goto startrecnew
if "%recnum%"=="6" goto startrecnew
if "%recnum%"=="7" goto startrecnew
if "%recnum%"=="8" goto startrecnew
if "%recnum%"=="9" goto startrecnew
goto recplay

:startrecnew
cls
echo [92mNew Recording[0m
echo.
echo Press any key to start recording for recording #%recnum%.
echo.
echo Once started, press [Space] to pause, press [S] to Save.[93m
echo.
pause >nul
set devcapture=
if not "%MicInput%"=="" set devcapture=--dev-capture=%MicInput%
fmedia --record %devcapture% --out="PlaybackRecordings\%recnum%.temp.wav" 
echo.
echo [92mPlaying Back Recording . . .[93m
fmedia "PlaybackRecordings\%recnum%.temp.wav"
echo.
echo [92mKeep and name recording?[0m
choice
if %errorlevel%==2 (
    del /f /q "PlaybackRecordings\%recnum%.temp.wav"
    goto recplay
)
if exist "PlaybackRecordings\%recnum%.wav" del /f /q "PlaybackRecordings\%recnum%.wav"
ren "PlaybackRecordings\%recnum%.temp.wav" "%recnum%.wav"
echo [92mEnter name for recording:[93m
set /p recname=">"
echo %recname%>"PlaybackRecordings\%recnum%.ini"
goto recplay



:plugins
cls
echo [96mPlugins[0m
echo.
echo [90mEnter number plugin to run, or x to exit.[0m
echo.
set plugnum=1
for /f "tokens=1 delims=" %%A in ('dir "Plugins\*.cmd" /b') do (
    echo !plugnum!] %%~nA
    set plugin!plugnum!=%%~A
    set /a plugnum+=1
)
echo.
set /p plugin=">"
if /i "%plugin%"=="x" goto mainmenu
if exist "Plugins\!plugin%plugin%!" (
    call "Plugins\!plugin%plugin%!" "%vrs%"
    goto plugins
) ELSE (
    echo Invalid.
    pause
    goto plugins
)


:distress
color 0f
cls
type logo.ascii
echo.[40;91m
echo.
echo [=========DISTRESS MODE=========]
echo.
echo Distress mode will send a distress signal to the digirig.
echo This message will play on a loop until stopped.
echo.
echo [41;97mNOTICE: Use of this mode in a non-emergency is a violation of FCC
echo law and can result in a fine of $25,000 and / or prison time.[40;91m
echo.
echo 1] Immediate Distress Mode (No Additional Information or Message)
echo 2] Custom Distress Message (Text to Speech)
echo 3] Play Custom Recorded Distress Message (choose audio file).
echo 4] Test Distress Message (clearly states it is a test).
echo X] Cancel
choice /c x1234
if %errorlevel%==1 goto mainmenu
if %errorlevel%==2 goto immediatedistress
if %errorlevel%==3 goto customdistress
if %errorlevel%==4 goto audiodistress
if %errorlevel%==5 goto testdistress
goto mainmenu

:audiodistress
cls
echo enter file:
set session=DistressAudio%random%
set /p file=">"
set file=%file:"=%
set file=%session%.mp3
for /f "tokens=1,2,3 delims=:" %%A in ('powershell -executionpolicy bypass -File "audio file length.ps1" "%file%"') do (
        set _hours=%%A
        set _minutes=%%B
        set _seconds=%%C
)
set /a _total=%_hours%*3600+%_minutes%*60+%_seconds%
set /a sostimeout=%_total%+15
echo.
echo Begin Distress Transmission? Transmission will take approximately %sostimeout% seconds
choice
if %errorlevel%==2 goto mainmenu
call ps1s.bat /tk "Simple Radio COM Ps1 Serial Interface" >nul
start /MIN powershell -executionpolicy bypass -file "PTT Trigger.ps1" %COMPort% %sostimeout%
echo SOS Transmission was started by %username% on %date% at %time%>>"%appdata%\SOSLog.log"
:distreaudloop
echo.
echo Repeating Distress Mesage.
echo.
echo TO FORCE STOP TRANSMISSION PRESS CTRL+C and CLOSE POWERSHELL WINDOW
echo.
echo DISTRESS MODE DISTRESS MODE DISTRESS MODE.
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto mainmenu
if /i not "%ComPort%"=="NONE" echo. >Transmit
if /i not "%ComPort%"=="NONE" timeout /t 2 /nobreak >nul
color 4f
title Simple Radio COM by W1BTR [ON AIR]
echo [102;31m[ON AIR][0m
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\BeforeTX\*.cmd" /b') do (
        call "PluginFiles\BeforeTX\%%~a"
    )
)
call fmedia "%morse%" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
rem call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
timeout /t 2 /nobreak >nul
call fmedia "AudioFiles\SOS.mp3" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
rem call "playsound.exe" "AudioFiles\SOS.mp3" %RadioInput% >transmitaudio.log
call fmedia "%file:"=%" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
rem call "playsound.exe" "%file%" %RadioInput% >transmitaudio.log
call fmedia "%morse%" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
rem call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
timeout /t 1 /nobreak >nul
call fmedia "%morse%" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
rem call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
if exist "PluginFiles\AfterTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\AfterTX\*.cmd" /b') do (
        call "PluginFiles\AfterTX\%%~a"
    )
)
echo Stopping TX
set premature=False
if not exist Transmit echo ### WARNING: Transmission is stopping before message is finished. Raise SO timeout.
if exist Transmit del /f /q Transmit
timeout /t 1 /nobreak >nul
color cf
title Simple Radio COM by W1BTR
echo.
echo Waiting 30 seconds before repeating. Press Q to End.
choice /c qp /t 30 /d p >nul
if %errorlevel%==1 goto postdistress
echo Repeating Transmission.
goto BasicSOSLoop




:customdistress
cls
type logo.ascii
echo.
echo.
echo PREPARING TO SEND DISTRESS MESSAGE.
echo.
echo The Following Information will already be included:
for /f "tokens=*" %%A in ('hostname') do set hostname=%%A
set ExtIP=SDR Controlled by %hostname% is offline.
if %errorlevel%==0 (
    for /f "tokens=1* delims=: " %%A in ('nslookup myip.opendns.com. resolver1.opendns.com 2^>NUL^|find "Address:"') Do (set ExtIP=Network IP is %%B)
)
echo Callsign %callsign%, time / date, %EetIP%.
echo.
echo Recommended information: Location, name, type of emergency, number of people.
echo Long messages may be cut off by 120 second timeout.
echo Enter custom message:
set /p customdistressmessage=">"
set ExtIP=SDR Controlled by %hostname% is offline.
ping opendns.com -n 1 >nul
if %errorlevel%==0 (
    for /f "tokens=1* delims=: " %%A in ('nslookup myip.opendns.com. resolver1.opendns.com 2^>NUL^|find "Address:"') Do (set ExtIP=Network IP is %%B)
)
set distresstimeout=120
set Custommessage=Emergency, Emergency, Emergency, This is %callsign% with an automated distress call. Initiated at %time% on %date%. %customdistressmessage%. %ExtIP%. Emergency, Emergency, Emergency, This is %callsign% with an automated distress call. Message will repeat every 30 seconds.
set morse=AudioFiles\SOS.mp3
goto practicedistress

:testdistress
cls
echo Are You Sure? Make sure you are not interfering with other operators during the test.
echo.
choice
if %errorlevel%==2 goto mainmenu
set Custommessage=This is %callsign% testing the Simple Radio com distress system. This is not an emergency. Please confirm receive of message after morse code. Message will repeat every 30 seconds until stopped.
set morse=AudioFiles\Test.mp3
set distresstimeout=50
goto practicedistress

:immediatedistress
cls
echo ARE YOU SURE YOU WANT TO START A DISTRESS MESSAGE?
echo.
echo Press [Y] key for yes or [N] key for no.
choice
if %errorlevel%==2 goto mainmenu
if %errorlevel%==1 goto continueimdis
goto mainmenu

:continueimdis
cls
echo Generating SOS Files.
ping opendns.com -n 1 >nul
set distresstimeout=60
rem setting hostname to variable
for /f "tokens=*" %%A in ('hostname') do set hostname=%%A
set ExtIP=SDR Controlled by %hostname% is offline.
ping opendns.com -n 1 >nul
if %errorlevel%==0 (
    for /f "tokens=1* delims=: " %%A in ('nslookup myip.opendns.com. resolver1.opendns.com 2^>NUL^|find "Address:"') Do (set ExtIP=Network IP is %%B)
)
set Custommessage=Emergency, Emergency, Emergency, This is %callsign% with an automated distress call. Initiated at %time% on %date%. Emergency, Emergency, Emergency, This is %callsign% with an automated distress call. %ExtIP%. Emergency, Emergency, Emergency, This is %callsign% with an automated distress call. Message will repeat every 30 seconds.
set morse=AudioFiles\SOS.mp3
:practicedistress
set session=DISTRESS%random%
echo Const SAFT48kHz16BitStereo = 39 >tts%session%.vbs
echo Const SSFMCreateForWrite = 3 ' Creates file even if file exists and so destroys or overwrites the existing file >>tts%session%.vbs
echo Dim oFileStream, oVoice >>tts%session%.vbs
echo Set oFileStream = CreateObject("SAPI.SpFileStream") >>tts%session%.vbs
echo oFileStream.Format.Type = SAFT48kHz16BitStereo >>tts%session%.vbs
echo oFileStream.Open "Audio%session%.wav", SSFMCreateForWrite >>tts%session%.vbs
echo Set oVoice = CreateObject("SAPI.SpVoice") >>tts%session%.vbs
echo Set oVoice.AudioOutputStream = oFileStream >>tts%session%.vbs
echo Set oVoice.Voice = oVoice.GetVoices.Item(%voice%) >>tts%session%.vbs
echo oVoice.Rate = 0.8 >>tts%session%.vbs
echo oVoice.Volume = 100 >>tts%session%.vbs
echo oVoice.Speak "%custommessage%" >>tts%session%.vbs
echo oFileStream.Close >>tts%session%.vbs
cscript tts%session%.vbs >nul
del /f /q tts%session%.vbs
set file=Audio%session%.wav
set deletefile=%file%
echo BEGINNING SOS TRANSMISSION
call ps1s.bat /tk "Simple Radio COM Ps1 Serial Interface" >nul
start /MIN Powershell -executionpolicy bypass -File "PTT Trigger.ps1" %COMPort% %distresstimeout%
echo SOS Transmission was started by %username% on %date% at %time%>>"%appdata%\SOSLog.log"
echo.
:BasicSOSLoop
echo.
echo Repeating Distress Mesage.
echo.
echo TO FORCE STOP TRANSMISSION PRESS CTRL+C and CLOSE POWERSHELL WINDOW
echo.
echo DISTRESS MODE DISTRESS MODE DISTRESS MODe.
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto mainmenu
if /i not "%ComPort%"=="NONE" echo. >Transmit
if /i not "%ComPort%"=="NONE" timeout /t 2 /nobreak >nul
color 4f
title Simple Radio COM by W1BTR [ON AIR]
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\BeforeTX\*.cmd" /b') do (
        call "PluginFiles\BeforeTX\%%~a"
    )
)
call fmedia "%morse%" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
rem call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
call fmedia "%file:"=%" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
rem call "playsound.exe" "%file%" %RadioInput% >transmitaudio.log
call fmedia "%morse%" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
rem call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
timeout /t 1 /nobreak >nul
call fmedia "%morse%" --dev=%RadioInput% --volume=%Volume% --notui 2>nul
rem call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
if exist "PluginFiles\AfterTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\AfterTX\*.cmd" /b') do (
        call "PluginFiles\AfterTX\%%~a"
    )
)
echo Stopping TX
set premature=False
if /i not "%COMPort%"=="NONE" (
    if not exist Transmit echo ### WARNING: Transmission is stopping before msg is finished. Raise SO timeout.
)
if exist Transmit del /f /q Transmit
timeout /t 1 /nobreak >nul
color cf
title Simple Radio COM by W1BTR
echo.
echo Waiting 30 seconds before repeating. Press Q to End.
choice /c qp /t 30 /d p >nul
if %errorlevel%==1 goto goto postdistress
echo Repeating Transmission.
goto BasicSOSLoop

:postdistress
call ps1s.bat /tk "Simple Radio COM Ps1 Serial Interface" >nul
start /MIN Powershell -executionpolicy bypass -File "PTT Trigger.ps1" %COMPort% %Timeout%
goto mainmenu

:custom
cls
color 0f
type logo.ascii
echo.
echo.
echo [92mCustom Text-To-Speech Engine[0m
echo.
echo [90mOn the next screen, you will choose when it plays.
echo.
echo [96mPlease enter custom message text.[90m
echo.
echo Note: Please remember to include your callsign for fcc compliance.
echo Use alphanumeric characters, spaces, and punctuation only.
echo Enter "X" to cancel.[0m
echo.
set /p custommessage=">"
if /i "%custommessage%"=="X" goto mainmenu
echo.
echo Generating file . . .
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
echo oVoice.Rate = %voice.rate% >>tts%session%.vbs
echo oVoice.Volume = %voice.volume% >>tts%session%.vbs
echo oVoice.Speak "%custommessage%" >>tts%session%.vbs
echo oFileStream.Close >>tts%session%.vbs
cscript tts%session%.vbs >nul
if not %errorlevel%==0 (
    echo File failed to generate, error %errorlevel%.
    echo Please check that the characters you entered
    echo are supported.
    echo.
    pause
    goto mainmenu
)
echo.
echo [92mFile generated.[0m
del /f /q tts%session%.vbs
timeout /t 1 /nobreak>nul
set deletefile=Audio%session%.wav
set file=Audio%session%.wav
goto :FromTTS

:settings
cls
color 0f
type logo.ascii
echo.
echo.
echo [92mSettings Menu[97m
echo.
echo @set "COMPort=%COMPort%">settings.cmd
echo @set "Timeout=%Timeout%">>settings.cmd
echo @set "RadioInput=%RadioInput%">>settings.cmd
echo @set "AudioCheck=%AudioCheck%">>settings.cmd
echo @set "RadioOutput=%RadioOutput%">>settings.cmd
echo @set "OutputCheck=%OutputCheck%">>settings.cmd
echo @set "MicInput=%MicInput%">>settings.cmd
echo @set "voice=%voice%">>settings.cmd
echo @set "voice.rate=%voice.rate%">>settings.cmd
echo @set "voice.volume=%voice.volume%">>settings.cmd
echo @set "callsign=%callsign%">>settings.cmd
echo @set "COMCheck=%COMCheck%">>settings.cmd
echo @set "Volume=%Volume%">>settings.cmd
echo 1] COM Port: %COMPort%
echo 2] Timeout: %Timeout%
if "%AudioCheck:~0,64%"=="%AudioCheck%" echo 3] Radio Input: %AudioCheck%
if not "%AudioCheck:~0,64%"=="%AudioCheck%" echo 3] Radio Input: %AudioCheck:~0,61%...
if "%OutputCheck%"=="" (
    echo 4] Radio Output:
    goto skipaudiocsettings
)
if "%OutputCheck:~0,64%"=="%OutputCheck%" echo 4] Radio Output: %OutputCheck%
if not "%OutputCheck:~0,64%"=="%OutputCheck%" echo 4] Radio Output: %OutputCheck:~0,60%...
:skipaudiocsettings
if "%MicInput%"=="" (
    echo 5] Microphone Input: [Default]
) ELSE (
    echo 5] Microphone Input: %MicInput%
)
if "%voice%"=="0" (
    echo 6] TTS Voice: Male - DAVID
) ELSE (
    echo 6] TTS Voice: Female - ZIRA
)
echo 7] TTS Speed - %voice.rate%/10
echo 8] TTS Volume - %voice.volume%/100
echo 9] Callsign - %CALLSIGN%
echo [90mX] Back[0m
choice /c 123456789X
if %errorlevel%==1 goto COMDevice
if %errorlevel%==2 (
        set /p Timeout=">"
        goto settings
)

if %errorlevel%==3 goto audiodevice
if %errorlevel%==4 goto outputdevice
if %errorlevel%==5 goto inputdevice
if %errorlevel%==6 if "%voice%"=="0" (
    set voice=1
    ) ELSE (
    set voice=0
    )
)
if %errorlevel%==7 (
    echo Enter rate between 0.1 and 10
    set /p voice.rate=">"
    if not !voice.rate! LSS 11 set voice.rate=1
)
if %errorlevel%==8 (
    set /p voice.volume=">"
    if not !voice.volume! LSS 101 set voice.volume=100
)
if %errorlevel%==9 (
    set /p callsign=">"
)
if %errorlevel%==10 goto mainmenu
goto settings


:inputdevice
cls
set device=True
set capture=False
if exist devlist.temp del /f /q devlist.temp
for /f "skip=1 delims=" %%A in ('call fmedia --list-dev 2^>nul') do (
    if "!capture!"=="True" (
        if "!device!"=="True" (
            echo [93m%%~A
            set device=False
            echo "%%~A">>devlist.temp
        ) ELSE (
            echo [90m%%~A
            set device=True
        )
    )
    if "%%~A"=="Capture:" set capture=True
)
echo ======================================================================
echo [92mEnter Device number to microphone audio from:
echo [90mEnter D to use system default[0m
set /p MicInput=">#"
rem strip of # in case of dumb user
set MicInput=%MicInput:#=%
if /i "%MicInput%"=="D" (
    set MicInput=
    goto settings
)
rem check for existance of device
find "device #%MicInput%: " "devlist.temp" >nul 2>nul
if not %errorlevel%==0 (
    echo Output Device #%MicInput% was not found.
    pause
    goto inputdevice
)
goto settings


:OutputDevice
set device=True
set capture=False
if exist devlist.temp del /f /q devlist.temp
for /f "skip=1 delims=" %%A in ('call fmedia --list-dev 2^>nul') do (
    if "!capture!"=="True" (
        if "!device!"=="True" (
            echo [93m%%~A
            set device=False
            echo "%%~A">>devlist.temp
        ) ELSE (
            echo [90m%%~A
            set device=True
        )
    )
    if "%%~A"=="Capture:" set capture=True
)
echo ======================================================================
echo [92mEnter Device number to act as OUTPUT from Radio:
set /p NewRadioOutput=">#"
rem strip of # in case of dumb user
set NewRadioOutput=%NewRadioOutput:#=%
rem check for existance of device
find "device #%NewRadioOutput%: " "devlist.temp" >nul 2>nul
if not %errorlevel%==0 (
    echo Output Device #%NewRadioOutput% was not found.
    pause
    goto outputdevice
)
for /f "skip=1 delims=" %%A in ('find "device #%NewRadioOutput%: " "devlist.temp"') do (
    set OutputCheck=%%~A
)
echo.
echo Use Device %OutputCheck%?
choice
if %errorlevel%==2 goto outputdevice
set RadioOutput=%NewRadioOutput%
goto settings

:audiodevice
cls
echo.
echo [92mWhat audio device is your radio's mic input connected to?[0m
echo.
set device=True
if exist devlist.temp del /f /q devlist.temp
for /f "tokens=1 skip=1 delims=" %%A in ('call fmedia --list-dev 2^>nul') do (
    if "%%~A"=="Capture:" goto breaksetupb
    if "!device!"=="True" (
        echo [93m%%~A
        set device=False
        echo "%%~A">>devlist.temp
    ) ELSE (
        echo [90m%%~A
        set device=True
    )
)
:breaksetupb
echo.
echo [92mEnter Device number to act as INPUT to radio:
set /p NewRadioInput=">"
rem strip of # in case of dumb user
set NewRadioInput=%NewRadioInput:#=%
rem check for existance of device
find "device #%NewRadioInput%: " "devlist.temp" >nul 2>nul
if not %errorlevel%==0 (
    echo Device #%NewRadioInput% was not found.
    pause
    goto audiodevice
)
for /f "skip=1 delims=" %%A in ('find "device #%NewRadioInput%: " "devlist.temp"') do (
    set AudioCheck=%%~A
)
echo.
echo Use Device %AudioCheck%?
choice
if %errorlevel%==2 goto audiodevice
set RadioInput=%NewRadioInput%
set InputName=%AudioCheck%
echo.
echo Alright %callsign%, we'll use%AudioCheck%
echo as your radio's mic input.
pause
goto settings


:audioerror
cls
echo ERROR: Audio Device Change detected.
echo.
if "%ErrorOutput%"=="" (
        echo Audio device %RadioInput% no longer exists.
) ELSE (
    echo Audio device is set to %RadioInput%.
    echo Expected name: %InputName%
    echo Pulled Name: %ErrorOutput%
)
echo Press any key to set radio input audio output device again.
pause
goto audiodevice




:basic
cls
type logo.ascii
echo.
echo.
echo [92mBasic Transmit mode[0m
echo Transmission Timeout is %Timeout% seconds.
echo.
echo [96mAudio will pass to:
echo [90m%AudioCheck%.[96m
echo.
echo Toggle PTT with the Space bar. Press X or Backspace to quit.
echo Use number 0-9,#,* for DTMF. Alternative * is - / # is =.
echo.
echo P] Recording and Playback Menu
echo R] Launch Quick Recorder
echo X] Exit to Main Menu
echo.
:kbdloopbasic
call kbd.exe
set _kbd=%errorlevel%
if %_kbd%==120 goto mainmenu
if %_kbd%==8 goto mainmenu
if %_kbd%==113 goto mainmenu
if %_kbd%==112 (
    set fromsimple=true
    goto :recplay
)
if %_kbd%==114 (
    start "" "QuickRecorder.bat"
    goto kbdloopbasic
)
if not %_kbd%==32 goto kbdloopbasic
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto mainmenu
if /i not "%ComPort%"=="NONE" echo.>Transmit
color e0
if /i not "%ComPort%"=="NONE" timeout /t 2 /nobreak >nul
if not "%MicInput%"=="" set devcapture=--dev-capture=%MicInput%
fmedia --dev=%RadioInput% --record %devcapture% --capture-buffer 15 --background >out.txt 2>nul
for /f "tokens=1,2 delims=PID" %%A in ('type out.txt') do (set PID=%%B)
title Simple Radio COM by W1BTR [ON AIR]
if exist OnStartTX.cmd call OnStartTX.cmd
color 60
echo [102;31m[ON AIR][0m
:txkbdloopbasic
call kbd.exe
if %errorlevel%==49 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-1.wav" >nul 2>nul
if %errorlevel%==50 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-2.wav" >nul 2>nul
if %errorlevel%==51 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-3.wav" >nul 2>nul
if %errorlevel%==52 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-4.wav" >nul 2>nul
if %errorlevel%==53 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-5.wav" >nul 2>nul
if %errorlevel%==54 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-6.wav" >nul 2>nul
if %errorlevel%==55 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-7.wav" >nul 2>nul
if %errorlevel%==56 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-8.wav" >nul 2>nul
if %errorlevel%==57 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-9.wav" >nul 2>nul
if %errorlevel%==48 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-0.wav" >nul 2>nul
if %errorlevel%==45 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-star.wav" >nul 2>nul
if %errorlevel%==61 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-pound.wav" >nul 2>nul
if %errorlevel%==42 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-star.wav" >nul 2>nul
if %errorlevel%==47 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-pound.wav" >nul 2>nul
if %errorlevel%==35 call fmedia --dev=%RadioInput% --volume=%Volume% --notui "DTMF\Dtmf-pound.wav" >nul 2>nul

if %errorlevel%==32 (
        timeout /t 1 /nobreak >nul
        taskkill /f /pid %PID% >nul
        if exist OnEndTX.cmd call OnEndTX.cmd
        if exist Transmit del /f /q Transmit
        color e0
        timeout /t 1 /nobreak >nul
        color 0f
        title Simple Radio COM by W1BTR
        goto :basic
)
if %errorlevel%==120 (
        timeout /t 1 /nobreak >nul
        if exist Transmit del /f /q Transmit
        taskkill /f /pid %PID% >nul
        color 0f
        title Simple Radio COM by W1BTR
        goto mainmenu
)
if %errorlevel%==8 (
        timeout /t 1 /nobreak >nul
        if exist Transmit del /f /q Transmit
        taskkill /f /pid %PID% >nul
        color 0f
        title Simple Radio COM by W1BTR
        goto mainmenu
)
if %errorlevel%==113 (
        timeout /t 1 /nobreak >nul
        if exist Transmit del /f /q Transmit
        taskkill /f /pid %PID% >nul
        color 0f
        title Simple Radio COM by W1BTR
        goto mainmenu
)
if %_kbd%==114 (
    start "" "QuickRecorder.bat"
    goto txkbdloopbasic
)
goto txkbdloopbasic

:audio
cls
color 0f
type logo.ascii
echo.
echo.
echo [92mTransmit Audio File[0m
set /a maxtx=%timeout%-5
echo.
echo [90mMax Transmission Length is %maxtx% seconds. Raise timeout to increase.
echo You will choose when the file plays in the next screen.[0m
echo.
echo [96mEnter File that will be used (or X to exit):[0m

set /p file=">"
set file=%file:"=%
if /i "%file%"=="X" goto mainmenu
if not exist "%file%" (
        echo File not found.
        pause
        goto mainmenu
)
:returnfromconvert
:FromTTS
for /f "tokens=1,2,3 delims=:" %%A in ('Powershell -executionpolicy bypass -File "audio file length.ps1" "%file%"') do (
        set _hours=%%A
        set _minutes=%%B
        set _seconds=%%C
)
set /a _total=%_hours%*3600+%_minutes%*60+%_seconds%
echo File Length is %_hours% hours, %_minutes% minutes and %_seconds% seconds.
echo Total of %_total% seconds.
echo.
set Timer=10
set Loop=False
set LoopDelay=30
set loopamount=0
:audiosettings
cls
echo [92mAudio Transmit mode[0m
echo Max Transmission Length is %Timeout% seconds.
echo.
echo File to be transmitted: %file%
echo File Length is %_hours% hours, %_minutes% minutes and %_seconds% seconds.
echo Total of %_total% seconds.
echo.
echo [96mChoose Timing Option:[0m
echo 1] Count Down and / or loop
echo 2] Set Date and Time
echo 3] Start Now and Play Once
choice /c 123x
if %errorlevel%==1 goto looprecording
if %errorlevel%==2 goto scheduledplay
if %errorlevel%==3 goto supersimple
if %errorlevel%==4 goto mainmenu

:supersimple
cls
color e0
echo BEGINNING TRANSMISSION OF AUDIO FILE: %file%
echo.
echo FILE WILL PLAY ONE TIME.
echo.
echo TO FORCE STOP TRANSMISSION PRESS CTRL+C and CLOSE POWERSHELL WINDOW
echo.
echo Will take %_total% seconds to transmit.
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto mainmenu
if /i not "%COMPort%"=="NONE" echo. >Transmit
echo [102;31m[ON AIR][0m
if /i not "%COMPort%"=="NONE" timeout /t 2 /nobreak >nul
title Simple Radio COM by W1BTR [ON AIR]
if exist OnStartTX.cmd call OnStartTX.cmd
call "fmedia.exe" "%file:"=%" --dev=%RadioInput% 2>nul
rem call "playsound.exe" "%file:"=%" %RadioInput% >transmitaudio.log
if exist OnEndTX.cmd call OnEndTX.cmd
echo Ending Transmission
set premature=False
if /i not "%COMPort%"=="NONE" (
    if not exist Transmit set premature=True
)
if exist Transmit del /f /q Transmit
color e0
timeout /t 1 /nobreak >nul
color 0f
title Simple Radio COM by W1BTR
for /f "tokens=1 delims=" %%A in ('powershell Get-Date') do (set lasttime=%%~A)
cls
type logo.ascii
echo.
echo.
echo [92mFinished transmission of %file% at:
echo [96m%lasttime%.[0m
echo.
if "%premature%"=="True" (
    echo WARNING: Transmission ended before end of file. 
    echo Make sure you accomodate for any start and stop tones in the timeout.
    echo.
)
pause
goto mainmenu

:convertfile
echo This file is incompatible with the player.
echo.
echo Convert with ffmpeg?
choice
if %errorlevel%==2 goto mainmenu
color 07
ffmpeg -y -i "%file:"=%" "%file:"=%.wav" >nul
set file=%file:"=%.wav
color 0f
goto returnfromconvert

:looprecording
cls
echo Audio Transmit Mode: LOOP
echo Max Transmission Length is %Timeout% seconds.
echo.
echo File to be looped: %file%
echo File Length is %_hours% hours, %_minutes% minutes and %_seconds% seconds.
echo Total of %_total% seconds.
echo.
echo 1] Starts after: %Timer% seconds.
echo 2] Loop enabled: %Loop%
echo 3] Wait between loops: %LoopDelay% seconds (if loop enabled).
if %loopamount%==0 (
        echo 4] Loop Amount: Forever
) ELSE (
        echo 4] Loop Amount: %loopamount%
)
echo 5] Finish
echo X] Cancel
choice /c 12345x
REM Menu handling
if %errorlevel%==6 exit /B
if %errorlevel%==1 (
    echo Set Timer in Seconds:
    set /p Timer=">"
    goto looprecording
)
if %errorlevel%==2 (
    if %loop%==True (
            set Loop=False
    ) ELSE (
            set Loop=True
    )
    goto looprecording
)
if %errorlevel%==3 (
    echo Set Loop Delay in Seconds:
    set /p LoopDelay=">"
    goto looprecording
)
if %errorlevel%==4 (
    echo Set Loop Amount [Enter 0 for infinite]:
    set /p loopamount=">"
    goto looprecording
)
if not %errorlevel%==5 goto PlayLoopRecording

:PlayLoopRecording
set loopcount=1
:playloopRecordingLoop
cls
type logo.ascii
echo.
echo.
echo [92mPreparing to Play File: %file% [0m
echo.
echo This will be loop %loopcount% of %loopamount%
echo.
echo Waiting %timer% seconds... Press Q to cancel.
choice /c qp /t %timer% /d p >nul
if %errorlevel%==1 (
        echo Cancelled.
        pause
        goto mainmenu
)
rem BEGIN TRANSMISSION HERE
cls
type logo.ascii
echo.
echo.
color e0
echo BEGINNING TRANSMISSION OF AUDIO FILE: %file%
echo.
if %loop%==True (
    if "%loopamount%"==0 (
            echo LOOPING FOREVER
    ) ELSE (
            echo LOOP %loopcount% OF %loopamount%
    )
) ELSE (
    echo NOT LOOPING
)

echo.
echo TO FORCE STOP TRANSMISSION PRESS CTRL+C and CLOSE POWERSHELL WINDOW
echo.
echo Will take %_total% seconds to transmit.
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto mainmenu
if /i not "%COMPort%"=="NONE" echo. >Transmit
echo [102;31m[ON AIR][0m
if /i not "%COMPort%"=="NONE" timeout /t 2 /nobreak >nul
title Simple Radio COM by W1BTR [ON AIR]
if exist OnStartTX.cmd call OnStartTX.cmd
call "fmedia.exe" "%file:"=%" --dev=%RadioInput% 2>nul
rem call "playsound.exe" "%file:"=%" %RadioInput% >transmitaudio.log
if exist OnEndTX.cmd call OnEndTX.cmd
echo Ending Transmission
set premature=False
if /i not "%COMPort%"=="NONE" (
    if not exist Transmit set premature=True
)
if exist Transmit del /f /q Transmit
color e0
timeout /t 1 /nobreak >nul
color 0f
title Simple Radio COM by W1BTR
for /f "tokens=1 delims=" %%A in ('powershell Get-Date') do (set lasttime=%%~A)
cls
echo Finished transmission of %file% at 
echo %lasttime%.
echo.
if "%premature%"=="True" (
    echo WARNING: Transmission ended before end of file. 
    echo Make sure you accomodate for any start and stop tones in the timeout.
    echo.
)
if %loop%==False (
    echo Press any key to return to main menu . . .
    pause>nul
    goto mainmenu
)
if not "%loopamount%"=="0" (
    if %loopcount%==%loopamount% (
        echo Loop finished.
        echo Press any key to return to main menu . . .
        pause>nul
        goto mainmenu
    ) ELSE (
        set /a loopcount+=1
        set timer=%LoopDelay%
        goto playloopRecordingLoop
    )
)
set timer=%loopdelay%
goto playloopRecordingLoop


:scheduledplay
cls
echo Audio Transmit Mode: LOOP
echo Max Transmission Length is %Timeout% seconds.
echo.
echo File to be looped: %file%
echo File Length is %_hours% hours, %_minutes% minutes and %_seconds% seconds.
echo Total of %_total% seconds.
echo.
echo.
echo Enter time for transmission to be scheduled (accuracy is within 3 seconds of system time).
echo Examples: 5:00PM, 07/20/24 12:00 PM, 05-23-2028 17:00
echo Enter "X" to cancel.
set /p Starts=">"

if "%Starts%"=="X" goto mainmenu
powershell Get-Date '%Starts%'
if %errorlevel%==1 (
    cls
    echo Invalid Date/Time.
    pause
    goto audiosetstart
)
set startingtime=!starts!
set starts=On.!Starts!
echo.
echo Repeat?
echo 1] Hourly
echo 2] Daily
echo 3] Every other Day
echo 4] Weekly
echo X] None
choice /c 1234X
set repeat=!errorlevel!
goto confirmaudio

:confirmaudio
cls
echo Please Confirm Settings:
echo.
echo File to be transmitted: %file%
echo Length of transmission: %_hours% hours, %_minutes% minutes and %_seconds% seconds.
echo.
echo Transmission Time Scheduled: %startingtime%
if %repeat%==1 (
        echo Repeats: Hourly
)
if %repeat%==2 (
        echo Repeats: Daily
)
if %repeat%==3 (
        echo Repeats: Every other Day
)
if %repeat%==4 (
        echo Repeats: Weekly
)
if %repeat%==5 (
        echo Repeats: None
)
echo.
echo Continue?
choice /c YN
if %errorlevel%==1 goto handledatea
goto mainmenu

:handledatea
:testaudioloop
for /f "tokens=1 delims=" %%A in ('powershell Get-Date '%Startingtime%'') do (set wait=%%~A)
for /f "tokens=1 delims=" %%A in ('powershell Get-Date') do (set current=%%~A)

cls
type logo.ascii
echo.
echo.
echo [92mPreparing to transmit audio file: %file%[0m
echo File has length of %_total% seconds.
echo.
echo Waiting for:   %wait%
echo Current Time:  %wait%
for /f "tokens=1* delims=" %%A in ('Powershell -executionpolicy bypass -File "CompareDateToNow.ps1" "%startingtime%"') do ( 
    if not "%%~A"=="True" (
        timeout /t 1 /nobreak >nul
        goto testaudioloop
    )
)
:beginaudiotransmit
rem BEGIN TRANSMISSION HERE
cls
color e0
echo BEGINNING TRANSMISSION OF AUDIO FILE: %file%
echo.
echo TO FORCE STOP TRANSMISSION PRESS CTRL+C and CLOSE POWERSHELL WINDOW
echo.
echo Will take %_total% seconds to transmit.
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto mainmenu
if /i not "%COMPort%"=="NONE" echo. >Transmit
echo [102;31m[ON AIR][0m
if /i not "%COMPort%"=="NONE" timeout /t 2 /nobreak >nul
title Simple Radio COM by W1BTR [ON AIR]
if exist OnStartTX.cmd call OnStartTX.cmd
call "fmedia.exe" "%file:"=%" --dev=%RadioInput% 2>nul
rem call "playsound.exe" "%file:"=%" %RadioInput% >transmitaudio.log
if exist OnEndTX.cmd call OnEndTX.cmd
echo Ending Transmission
set premature=False
if /i not "%COMPort%"=="NONE" (
    if not exist Transmit set premature=True
)
if exist Transmit del /f /q Transmit
color e0
timeout /t 1 /nobreak >nul
color 0f
title Simple Radio COM by W1BTR
for /f "tokens=1 delims=" %%A in ('powershell Get-Date') do (set lasttime=%%~A)
cls
type logo.ascii
echo.
echo.
echo [92mFinished transmission of %file% at:
echo [96m%lasttime%.[0m
echo.
if "%premature%"=="True" (
    echo WARNING: Transmission ended before end of file. 
    echo Make sure you accomodate for any start and stop tones in the timeout.
    echo.
)
if %repeat%==5 (
    pause
    goto audiosettings
)
if %repeat%==1 for /f "tokens=1 delims=" %%A in ('powershell (Get-Date '%wait%'^).AddHours(1^)') do (
    set startingtime=%%A
    set wait=%%A
)
if %repeat%==2 for /f "tokens=1 delims=" %%A in ('powershell (Get-Date '%wait%'^).AddDays(1^)') do (
    set startingtime=%%A
    set wait=%%~A
)
if %repeat%==3 for /f "tokens=1 delims=" %%A in ('powershell (Get-Date '%wait%'^).AddDays(2^)') do (
    set startingtime=%%A
    set wait=%%~A
)
if %repeat%==4 for /f "tokens=1 delims=" %%A in ('powershell (Get-Date '%wait%'^).AddDays(7^)') do (
    set startingtime=%%A
    set wait=%%~A
)
echo.
echo.
echo.
echo Now waiting for %startingtime% to transmit again.
:extraaudioloop
for /f "tokens=* delims=" %%A in ('Powershell -executionpolicy bypass -File "CompareDateToNow.ps1" "%startingtime%"') do ( 
    if not "%%~A"=="True" (
        timeout /t 1 /nobreak >nul
        goto :extraaudioloop
    )
)
goto :beginaudiotransmit
rem to repeat (Get-Date $date).AddDays(1)


:error
echo Please report this bug to https://github.com/ITCMD/Simple-Radio-COM/issues
if exist Transmit del /f /q Transmit
timeout /t 2 >nul
call ps1s /tk "Simple Radio COM Ps1 Serial Interface" >nul
pause
exit /b

::::::::::::::::::::::::::::::::::::::::
:: By npocmaka
:::----- subroutine starts here ----::::
:startsWith [%1 - string to be checked;%2 - string for checking ] 
@echo off
rem :: sets errorlevel to 1 if %1 starts with %2 else sets errorlevel to 0

setlocal EnableDelayedExpansion

set "string=%~1"
set "checker=%~2"
rem set "var=!string:%~2=&echo.!"
set LF=^


rem ** Two empty lines are required
rem echo off
for %%L in ("!LF!") DO (
    for /f "delims=" %%R in ("!checker!") do ( 
        rem set "var=!string:%%~R%%~R=%%~L!"
        set "var=!string:%%~R=#%%L!"
    )
)
for /f "delims=" %%P in (""!var!"") DO (
    if "%%~P" EQU "#" (
        endlocal & exit /b 1
    ) else (
        endlocal & exit /b 0
    )
)
::::::::::::::::::::::::::::::::::::::::::::::::::
