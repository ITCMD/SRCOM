@echo off
if not exist PluginFiles (
    echo Could not find Bin folder.
    echo Make sure you run this file from Simple Radio COM
    pause
    exit /B
)
if not exist PluginFiles\AfterTX mkdir PluginFiles\AfterTX
if not exist PluginFiles\Callsigns md "PluginFiles\Callsigns"
:menu
cls
echo Simple Radio COM End with Callsign Plugin.
echo Allows adding of TTS or Voice Callsign after Transmission.
echo.
echo 1] Enable / Change Callsign
echo 2] Disable Callsign
echo X] Exit
choice /c 12X
goto %errorlevel%

:1
cls
echo 1] Use TTS
echo 2] Use .wav File
echo X] Cancel
choice /c 12X
if %errorlevel%==3 goto menu
if %errorlevel%==2 goto wav
echo.
call settings.cmd
echo 1] "%callsign% for ID"
echo 2] "%callsign%"
choice /c 12
if %errorlevel%==1 set custommessage=%callsign% for ID
if %errorlevel%==2 set custommessage=%callsign%
echo Generating File . . .
set session=%random%%random%
echo Const SAFT48kHz16BitStereo = 39 >tts%session%.vbs
echo Const SSFMCreateForWrite = 3 ' Creates file even if file exists and so destroys or overwrites the existing file >>tts%session%.vbs
echo Dim oFileStream, oVoice >>tts%session%.vbs
echo Set oFileStream = CreateObject("SAPI.SpFileStream") >>tts%session%.vbs
echo oFileStream.Format.Type = SAFT48kHz16BitStereo >>tts%session%.vbs
echo oFileStream.Open "Callsign%session%.wav", SSFMCreateForWrite >>tts%session%.vbs
echo Set oVoice = CreateObject("SAPI.SpVoice") >>tts%session%.vbs
echo Set oVoice.AudioOutputStream = oFileStream >>tts%session%.vbs
echo Set oVoice.Voice = oVoice.GetVoices.Item(%voice%) >>tts%session%.vbs
echo oVoice.Rate = %voice.rate% >>tts%session%.vbs
echo oVoice.Volume = %voice.volume% >>tts%session%.vbs
echo oVoice.Speak "%custommessage%" >>tts%session%.vbs
echo oFileStream.Close >>tts%session%.vbs
cscript tts%session%.vbs >nul
del /f /q tts%session%.vbs
move "Callsign%session%.wav" "PluginFiles\Callsigns\Callsign.wav" >nul
set audiofile=PluginFiles\Callsigns\Callsign.wav
:savesetting
echo @call settings.cmd>"PluginFiles\AfterTX\9y_Callsign.cmd"
echo @call playsound "%audiofile%" %RadioInput% ^>nul>>"PluginFiles\AfterTX\9y_Callsign.cmd"
echo.
echo Callsign saved.
pause
goto menu

:wav
echo Enter WAV file for callsign message.
echo.
echo This file will be copied locally.
echo.
set /p callfile=">"
if not exist %callfile% (
    echo File not found.
    pause
    goto menu
)
copy %callfile% PluginFiles\Callsigns\Callsign.wav /y >nul
set audiofile=PluginFiles\Callsigns\Callsign.wav
goto savesetting