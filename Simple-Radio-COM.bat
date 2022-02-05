@echo off
set vrs=4
Setlocal EnableDelayedExpansion
set Console=False
if not "%~1"=="" set Console=True
color 0f
if "%Console%"=="False" mode con:cols=80 lines=30
if "%Console%"=="False" cls
if "%Console%"=="False" title Simple Radio COM by W1BTR
if "%Console%"=="False" echo Loading Settings . . .
set COMPort=COM5
set Timeout=120
set RadioInput=0
set voice=0
set voice.rate=1
set voice.volume=100
set callsign=XXXXX
if not exist Bin (
    echo Error: Bin Folder not found.
    if "%Console%"=="False" pause
    exit /B
)
cd bin
if exist Transmit del /f /q Transmit
if exist settings.cmd call settings.cmd
if "%callsign%"=="XXXXX" goto firsttimesetup
rem Check audio device
if "%Console%"=="False" echo Self-Checking . . . 
for /f "tokens=1,2 delims=: skip=4" %%A in ('playsound AudioFiles\Calibrate.mp3 %RadioInput%') do (
        if "%%~B"=="%InputName%" goto PassAudioCheck
        set ErrorOutput=%%~B
        if "%Console%"=="False" goto audioerror.
        exit /b
)
)
:PassAudioCheck
echo Self-Check Pass
call ps1s.bat /tk "Simple Radio COM Ps1 Serial Interface"
echo Launching PTT PS1 Script
start /MIN powershell -file "PTT Trigger.ps1" %COMPort% %Timeout%
goto mainmenu

:firsttimesetup
cls
color 0f
type logo.ascii
echo.
echo.
echo [96mWelcome to the Simple Radio COM Setup Wizard.
echo Make sure your digirig or other COM protocol device is setup and plugged in.
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
echo [92mNext, what COM port is your digirig connected to?[0m
echo [90mInclude COM. Example: COM5[0m
echo.
set /p COMPort=">"
echo.
echo Fantastic. We'll use COM port %COMPort% to trigger PTT.
:firsttimeaudio
echo.
echo [92mNext, what audio device is your radio's mic input connected to?[0m
echo.
:setupaloop
set /a device+=1
for /f "tokens=1,2 delims=: skip=4" %%A in ('playsound AudioFiles\Calibrate.mp3 %device%') do (
        if "%%~B"=="" goto breaksetupa
        echo Device %device%: %%~B
        set device%device%=%%~B
        goto setupaloop
)
goto detectadloop
:breaksetupa
echo.
echo Enter Device to act as INPUT to radio:
set /p NewRadioInput=">"
cls
echo Use Device %NewRadioInput% -!device%NewRadioInput%!?
choice
if %errorlevel%==2 goto :firsttimeaudio
set RadioInput=%NewRadioInput%
set InputName=!device%NewRadioInput%!
echo.
echo Alright %callsign%, we'll use%InputName% as your radio's mic input.
echo.
echo [92mThat's it for the initial setup![0m
echo But there are more settings to explore in the settings menu, such
echo as the TTS voice, voice speed, and voice volume, or timeout settings.
echo @set "COMPort=%COMPort%">settings.cmd
echo @set "Timeout=%Timeout%">>settings.cmd
echo @set "RadioInput=%RadioInput%">>settings.cmd
echo @set "InputName=%InputName%">>settings.cmd
echo @set "voice=%voice%">>settings.cmd
echo @set "voice.rate=%voice.rate%">>settings.cmd
echo @set "voice.volume=%voice.volume%">>settings.cmd
echo @set "callsign=%callsign%">>settings.cmd
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
for /f "tokens=1* delims=" %%A in ('powershell -File "CompareDateToNow.ps1" "%starts%"') do ( 
    if not "%%~A"=="True" (
        timeout /t 1 /nobreak >nul
        goto csschedloop
    )
)
echo Starting TX
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto :mainmenu
echo. >Transmit
timeout /t 1 /nobreak >nul
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\BeforeTX\*.cmd" /b') do (
        call "PluginFiles\BeforeTX\%%~a"
    )
)
call "playsound.exe" "%file%" %RadioInput%
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
if %cancel%==True goto :mainmenu
echo. >Transmit
timeout /t 1 /nobreak >nul
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\BeforeTX\*.cmd" /b') do (
        call "PluginFiles\BeforeTX\%%~a"
    )
)
call "playsound.exe" "%file%" %RadioInput%
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
if %cancel%==True goto :mainmenu
echo. >Transmit
timeout /t 1 /nobreak >nul
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\BeforeTX\*.cmd" /b') do (
        call "PluginFiles\BeforeTX\%%~a"
    )
)
call "playsound.exe" "%file%" %RadioInput%
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
echo [93m1] Basic Transmit
echo [96m2] Transmit Audio File
echo [95m3] Transmit Custom TTS Message
echo [31m4] DISTRESS MODE[0m
echo S] Settings
echo P] Plugins
echo [90mX] Exit[0m
choice /c x1234SP
if %errorlevel%==1 exit /B
set /a erl=%errorlevel%-1
if %erl%==1 goto basic
if %erl%==2 goto audio
if %erl%==3 goto custom
if %erl%==4 goto distress
if %erl%==5 goto settings
if %erl%==6 goto plugins

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
ffmpeg -i -y "%file%" "%cd%\%session%.mp3" >nul
set file=%session%.mp3
for /f "tokens=1,2,3 delims=:" %%A in ('powershell -File "audio file length.ps1" "%cd%\%file%"') do (
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
start /MIN powershell -file "PTT Trigger.ps1" %COMPort% %sostimeout%
echo SOS Transmission was started by %username% on %date% at %time%>>"%appdata%\SOSLog.log"
:distreaudloop
echo.
echo Repeating Distress Mesage.
echo.
echo TO FORCE STOP TRANSMISSION CLOSE POWERSHELL WINODW
echo.
echo DISTRESS MODE DISTRESS MODE DISTRESS MDOE.
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto :mainmenu
echo. >Transmit
timeout /t 1 /nobreak >nul
color 4f
title Simple Radio COM by W1BTR [ON AIR]
echo [102;31m[ON AIR][0m
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\BeforeTX\*.cmd" /b') do (
        call "PluginFiles\BeforeTX\%%~a"
    )
)
call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
timeout /t 1 /nobreak >nul
call "playsound.exe" "AudioFiles\SOS.mp3" %RadioInput% >transmitaudio.log
call "playsound.exe" "%file%" %RadioInput% >transmitaudio.log
call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
timeout /t 1 /nobreak >nul
call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
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
start /MIN powershell -file "PTT Trigger.ps1" %COMPort% %distresstimeout%
echo SOS Transmission was started by %username% on %date% at %time%>>"%appdata%\SOSLog.log"
echo.
:BasicSOSLoop
echo.
echo Repeating Distress Mesage.
echo.
echo TO FORCE STOP TRANSMISSION CLOSE POWERSHELL WINODW
echo.
echo DISTRESS MODE DISTRESS MODE DISTRESS MDOE.
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto :mainmenu
echo. >Transmit
timeout /t 1 /nobreak >nul
color 4f
title Simple Radio COM by W1BTR [ON AIR]
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1 delims=" %%a in ('dir "PluginFiles\BeforeTX\*.cmd" /b') do (
        call "PluginFiles\BeforeTX\%%~a"
    )
)
call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
call "playsound.exe" "%file:"=%" %RadioInput% >transmitaudio.log
call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
timeout /t 1 /nobreak >nul
call "playsound.exe" "%morse%" %RadioInput% >transmitaudio.log
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
if %errorlevel%==1 goto goto postdistress
echo Repeating Transmission.
goto BasicSOSLoop

:postdistress
call ps1s.bat /tk "Simple Radio COM Ps1 Serial Interface" >nul
start /MIN powershell -file "PTT Trigger.ps1" %COMPort% %Timeout%
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
set file="Audio%session%.wav"
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
echo @set "InputName=%InputName%">>settings.cmd
echo @set "voice=%voice%">>settings.cmd
echo @set "voice.rate=%voice.rate%">>settings.cmd
echo @set "voice.volume=%voice.volume%">>settings.cmd
echo @set "callsign=%callsign%">>settings.cmd
echo 1] COM Port: %COMPort%
echo 2] Timeout: %Timeout%
echo 3] Radio Input: %RadioInput% -%InputName%
if "%voice%"=="0" (
    echo 4] TTS Voice: Male - DAVID
) ELSE (
    echo 4] TTS Voice: Female - ZIRA
)
echo 5] TTS Speed - %voice.rate%/10
echo 6] TTS Volume - %voice.volume%/100
echo [90mX] Back[0m
choice /c 1234567X
if %errorlevel%==1 (
        set /p COMPort=">"
        goto settings
)
if %errorlevel%==2 (
        set /p Timeout=">"
        goto settings
)

if %errorlevel%==3 goto audiodevice
if %errorlevel%==4 if "%voice%"=="0" (
    set voice=1
    ) ELSE (
    set voice=0
    )
)
if %errorlevel%==5 (
    set /p voice.rate=">"
    if not !voice.rate! LSS 11 set voice.rate=1
)
if %errorlevel%==6 (
    set /p voice.volume=">"
    if not !voice.volume! LSS 101 set voice.volume=100
)
if %errorlevel%==7 (
    set /p callsign=">"
)
if %errorlevel%==8 goto mainmenu
goto settings


:audiodevice
cls
echo Detecting Audio Devices...
set device=0
:detectadloop
set /a device+=1
for /f "tokens=1,2 delims=: skip=4" %%A in ('playsound AudioFiles\Calibrate.mp3 %device%') do (
        if "%%~B"=="" goto breakdeva
        echo Device %device%: %%~B
        set device%device%=%%~B
        goto detectadloop
)
goto detectadloop
:breakdeva
echo.
echo Enter Device to act as INPUT to radio:
set /p NewRadioInput=">"
cls
echo Use Device %NewRadioInput% -!device%NewRadioInput%!?
choice
if %errorlevel%==2 goto settings
set RadioInput=%NewRadioInput%
set InputName=!device%NewRadioInput%!
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
echo [96mNote: This device only controls PTT. While other modes output audio to the
echo radio this mode cannot forward audio. It is recommended that you use Voicemeeter
echo or another mixer to send your microphone's output to the radio input.
echo.
echo Toggle PTT with the Space bar. Press X or Backspace to quit.
echo Use number 0-9,#,* for DTMF. Alternative * is - / # is =.
echo.
:kbdloopbasic
call kbd.exe
set _kbd=%errorlevel%
if %_kbd%==120 goto mainmenu
if %_kbd%==8 goto mainmenu
if %_kbd%==113 goto mainmenu
if not %_kbd%==32 goto kbdloopbasic
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto :mainmenu
echo.>Transmit
color e0
timeout /t 1 /nobreak >nul
title Simple Radio COM by W1BTR [ON AIR]
if exist OnStartTX.cmd call OnStartTX.cmd
color 60
echo [102;31m[ON AIR][0m
:txkbdloopbasic
call kbd.exe
if %errorlevel%==49 call "playsound.exe" "DTMF\Dtmf-1.wav" %RadioInput% >nul
if %errorlevel%==50 call "playsound.exe" "DTMF\Dtmf-2.wav" %RadioInput% >nul
if %errorlevel%==51 call "playsound.exe" "DTMF\Dtmf-3.wav" %RadioInput% >nul
if %errorlevel%==52 call "playsound.exe" "DTMF\Dtmf-4.wav" %RadioInput% >nul
if %errorlevel%==53 call "playsound.exe" "DTMF\Dtmf-5.wav" %RadioInput% >nul
if %errorlevel%==54 call "playsound.exe" "DTMF\Dtmf-6.wav" %RadioInput% >nul
if %errorlevel%==55 call "playsound.exe" "DTMF\Dtmf-7.wav" %RadioInput% >nul
if %errorlevel%==56 call "playsound.exe" "DTMF\Dtmf-8.wav" %RadioInput% >nul
if %errorlevel%==57 call "playsound.exe" "DTMF\Dtmf-9.wav" %RadioInput% >nul
if %errorlevel%==48 call "playsound.exe" "DTMF\Dtmf-0.wav" %RadioInput% >nul
if %errorlevel%==45 call "playsound.exe" "DTMF\Dtmf-star.wav" %RadioInput% >nul
if %errorlevel%==61 call "playsound.exe" "DTMF\Dtmf-pound.wav" %RadioInput% >nul
if %errorlevel%==42 call "playsound.exe" "DTMF\Dtmf-star.wav" %RadioInput% >nul
if %errorlevel%==47 call "playsound.exe" "DTMF\Dtmf-pound.wav" %RadioInput% >nul
if %errorlevel%==35 call "playsound.exe" "DTMF\Dtmf-pound.wav" %RadioInput% >nul

if %errorlevel%==32 (
        if exist OnEndTX.cmd call OnEndTX.cmd
        if exist Transmit del /f /q Transmit
        color e0
        timeout /t 1 /nobreak >nul
        color 0f
        title Simple Radio COM by W1BTR
        goto :basic
)
if %errorlevel%==120 (
        if exist Transmit del /f /q Transmit
        color 0f
        title Simple Radio COM by W1BTR
        goto mainmenu
)
if %errorlevel%==8 (
        if exist Transmit del /f /q Transmit
        color 0f
        title Simple Radio COM by W1BTR
        goto mainmenu
)
if %errorlevel%==113 (
        if exist Transmit del /f /q Transmit
        color 0f
        title Simple Radio COM by W1BTR
        goto mainmenu
)
goto txkbdloopbasic

:audio
cls
color 0f
type logo.ascii
echo.
echo.
echo [92mTransmit and Audio File[0m
set /a maxtx=%timeout%-5
echo.
echo [90mMax Transmission Length is %maxtx% seconds. Raise timeout to increase.
echo You will choose when the file plays in the next screen.[0m
echo.
echo [96mEnter File that will be used (or X to exit):[0m

set /p file=">"
if /i "%file%"=="X" goto mainmenu
if not exist "%file:"=%" (
        echo File not found.
        pause
        goto mainmenu
)
for /f "tokens=1 delims=" %%A in ('echo "%file:"=%"') do (set extension=%%~xA)
if not "%extension%"==".wav" (
    if not "%extension%"==".mp3" goto convertfile
)
:returnfromconvert
copy "%file:"=%" "%cd%\" /Y >nul 2>nul
set deletefile=%file%
:FromTTS
for /f "tokens=1 delims=" %%A in ('echo "%file:"=%"') do (set file=%%~nxA)
for /f "tokens=1,2,3 delims=:" %%A in ('powershell -File "audio file length.ps1" "%cd%\%file:"=%"') do (
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
echo TO FORCE STOP TRANSMISSION CLOSE POWERSHELL WINODW
echo.
echo Will take %_total% seconds to transmit.
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto :mainmenu
echo. >Transmit
echo [102;31m[ON AIR][0m
timeout /t 1 /nobreak >nul
title Simple Radio COM by W1BTR [ON AIR]
if exist OnStartTX.cmd call OnStartTX.cmd
call "playsound.exe" "%file:"=%" %RadioInput% >transmitaudio.log
if exist OnEndTX.cmd call OnEndTX.cmd
echo Ending Transmission
set premature=False
if not exist Transmit set premature=True
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
pause
goto mainmenu

:convertfile
echo This file is incompatible with the player.
echo.
echo Convert with ffmpeg?
choice
if %errorlevel%==2 goto mainmenu
color 07
ffmpeg -i -y "%file:"=%" "%file:"=%.wav" >nul
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
echo Preparing to Play File: %file%
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
echo TO FORCE STOP TRANSMISSION CLOSE POWERSHELL WINODW
echo.
echo Will take %_total% seconds to transmit.
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto :mainmenu
echo. >Transmit
echo [102;31m[ON AIR][0m
timeout /t 1 /nobreak >nul
title Simple Radio COM by W1BTR [ON AIR]
if exist OnStartTX.cmd call OnStartTX.cmd
call "playsound.exe" "%file:"=%" %RadioInput% >transmitaudio.log
if exist OnEndTX.cmd call OnEndTX.cmd
echo Ending Transmission
set premature=False
if not exist Transmit set premature=True
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
echo Preparing to transmit audio file: %file%
echo File has length of %_total% seconds.
echo.
echo Waiting for:   %wait%
echo Current Time:  %wait%
for /f "tokens=1* delims=" %%A in ('powershell -File "CompareDateToNow.ps1" "%startingtime%"') do ( 
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
echo TO FORCE STOP TRANSMISSION CLOSE POWERSHELL WINODW
echo.
echo Will take %_total% seconds to transmit.
set cancel=False
if exist BeforeTX.cmd call BeforeTX.cmd
if %cancel%==True goto :mainmenu
echo. >Transmit
echo [102;31m[ON AIR][0m
timeout /t 1 /nobreak >nul
title Simple Radio COM by W1BTR [ON AIR]
if exist OnStartTX.cmd call OnStartTX.cmd
call "playsound.exe" "%file:"=%" %RadioInput% >transmitaudio.log
if exist OnEndTX.cmd call OnEndTX.cmd
echo Ending Transmission
set premature=False
if not exist Transmit set premature=True
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
for /f "tokens=* delims=" %%A in ('powershell -File "CompareDateToNow.ps1" "%startingtime%"') do ( 
    if not "%%~A"=="True" (
        timeout /t 1 /nobreak >nul
        goto :extraaudioloop
    )
)
goto :beginaudiotransmit


rem to repeat (Get-Date $date).AddDays(1)

call "playsound.exe" "%file:"=%" %RadioInput% >transmitaudio.log




:error
echo Please report this bug to https://github.com/ITCMD/Simple-Radio-COM/issues
if exist Transmit del /f /q Transmit
timeout /t 3 >nul
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
