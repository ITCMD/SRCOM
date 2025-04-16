@echo off
cls
echo [96mDownloading files...[90m
echo Downloading Simple-Radio-COM.bat...
curl https://raw.githubusercontent.com/ITCMD/SRCOM/main/Simple-Radio-COM.bat -s --progress-bar -o Simple-Radio-COM.bat
echo Downloading Logger.cmd...
curl https://raw.githubusercontent.com/ITCMD/SRLog/main/Simple-Radio-Logger.bat -s --progress-bar -o Logger.bat
echo.
echo [92mDone![0m
pause
cd ..
Simple-Radio-COM.bat -Updated