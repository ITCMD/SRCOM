@echo off
if exist "PluginFiles\BeforeTX\*.cmd" (
    for /f "tokens=1" %%A in ('dir /b "PluginFiles\BeforeTX\*.cmd"') do (
        call "PluginFiles\BeforeTX\%%~A"
    )
)