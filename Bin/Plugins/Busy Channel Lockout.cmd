@echo off
set wait=0
call settings.cmd
if not "%~1"=="" goto menu
call PluginFiles\Lockout_settings.cmd
rem strip delay of any spaces.
set wait=%wait: =%
if not exist "Busy.Lockout" exit /b
echo [95mBusy Channel Lockout Detected. Waiting for break...[0m
echo [90mPress Q or X to cancel transmission. Press T to bypass.[0m

:waitloop
choice /c qxtg /t 1 /d g >nul
if %errorlevel%==1 goto cancel
if %errorlevel%==2 goto cancel
if %errorlevel%==3 exit /b
if exist "Busy.Lockout" goto waitloop
if not "%wait%"=="0" (
    echo [90mBusy Lockout Ended. Waiting for %wait% seconds...[0m
)
timeout /t %wait% /nobreak >nul
if exist "Busy.Lockout" (
    echo [90mLockout detected again. Waiting more...[0m
    goto waitloop
)
exit /b

:cancel
set cancel=True
exit /b

:menu
cls
echo Simple Radio COM Busy Channel Lockout Plugin
echo.
echo 1] Enable / Change Busy Channel Lockout
echo 2] Disable Busy Channel Lockout
echo 3] First Time Setup Guide.
echo X] Exit
echo.
choice /c 123X
goto %errorlevel%

:4
exit /b


:3
cls
echo This requires Voicemeeter Banana to work.
echo Do you have voicemeeter Banana installed?
choice
if %errorlevel%==2 (
    start https://vb-audio.com/Voicemeeter/banana.htm
    exit /b
)
cls
echo [92mGreat. First, figure out which strip is your radio's output.[0m
echo This is the Voicemeeter input where the radio plays audio to.
echo.
echo if you have not set up voicemeeter yet, choose one of the "hardware inputs"
echo which are the three strips to the left. On the top where it says "Select Input Device"
echo choose the input that comes from the radio. If you are using a digirig,
echo this will be called "USB PnP Sound Device."
echo.
echo Make sure that in the menu you have "Start Voicemeeter with Windows" selected,
echo or you will have to launch voicemeeter manually.
echo.
echo Then, open Macro Buttons (a program included with Voicemeeter).
echo.
echo Right click the top of the Macro Buttons window and make sure 
echo "Run on windows Startup" is checked.
echo.
echo Once you have completed these steps,
pause
echo.
echo.
echo.
echo [92mNow, select an unused macro button and right-click it.[0m
echo the Macro's menu will open. Confirm that "Button Type" is set to
echo "push button". Then, enable "Trigger" at the bottom and make sure the
echo strip selected is the radio's output. You should see a green bar
echo move when the radio is playing audio.
echo.
echo Move the red triangle to the right-most end of the bar, and move
echo the green triangle near the lowest. If your radio outputs electronic
echo noise when nothing is being transmitted, move the green triangle above it.
echo.
echo Once you have completed these steps,
pause
echo.
echo.
echo.
echo [92mWith that done, we are ready to insert the code the macro will run.[0m
echo.
echo paste the following text into 
echo [95m"Request for Button ON / Trigger IN:"
echo.
echo [107;30mSystem.Execute("%windir%\System32\wscript.exe","%cd%\","/c CreateBusyChannelLockout.vbs");[0m
echo.
echo.
echo paste the following text into
echo [95m"Request for Button OFF / Trigger OUT:"
echo.
echo [107;30mSystem.Execute("%windir%\System32\wscript.exe","%cd%","/C EndBusyChannelLockout.vbs");[0m
echo.
echo.
echo Once you have done this,
pause
echo.
echo.
echo.
echo [92mNow that the settings are fine tuned, press "OK" to save the macro.[0m
echo.
echo When your radio outputs audio, you should see the macro change color to 
echo indicate that the radio is playing. When the macro is active, the file 
echo "Busy.Lockout" will be created in the Bin directory, informing this plugin
echo that the channel is busy.
echo.
echo.
echo And that's it. You can now use the plugin to lock out the channel.
echo.
pause
goto menu


:2
cls
if not exist "PluginFiles\BeforeTX\0a_busylockout.cmd" (
    echo Busy Channel Lockout is not enabled.
    pause
    goto menu
)
del /f /q "PluginFiles\BeforeTX\0a_busylockout.cmd"
echo.
echo Busy Channel Lockout Disabled.
pause
goto menu

:1
cls
echo When a transmission is detected on channel Simple Radio COM will wait
echo for a break in the conversation (Press Q or X during the wait to cancel).
echo.
echo Once a break is detected, how long do you want this program to wait for
echo any other transmissions to begin before transmitting? (in seconds).
echo Enter 0 for no wait.
echo.
set /p sec=">"
echo.
echo Enabling plugin...
if not exist "PluginFiles\BeforeTX" mkdir "PluginFiles\BeforeTX"
echo @set wait=%sec% >PluginFiles\Lockout_Settings.cmd
echo copy "%~0" "PluginFiles\BeforeTX\0a_busylockout.cmd"
copy "%~0" "PluginFiles\BeforeTX\0a_busylockout.cmd" >nul
echo.
echo Done.
pause
goto menu



