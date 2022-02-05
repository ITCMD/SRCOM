@echo off
cd Bin
del /f /q settings.cmd
del /f /q *.log
del /f /q Callsign.wav
del /f /q PluginFiles\Lockout_Settings.cmd
del /f /q PluginFiles\Callsigns\*.*
del /f /q PluginFiles\AfterTX\*.*
del /f /q PluginFiles\OnStartTX\*.*
del /f /q PluginFiles\BeforeTX\*.*