@echo off
if exist "PluginFiles\AfterTX\*.cmd" (
    for /f "tokens=1" %%A in ('dir /b "PluginFiles\AfterTX\*.cmd"') do (
        call "PluginFiles\AfterTX\%%~A"
    )
)