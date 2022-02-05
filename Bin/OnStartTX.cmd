@echo off
if exist "PluginFiles\OnStartTX\*.cmd" (
    for /f "tokens=1" %%A in ('dir /b "PluginFiles\OnStartTX\*.cmd"') do (
        call "PluginFiles\OnStartTX\%%~A"
    )
)