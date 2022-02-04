@echo off
setlocal EnableDelayedExpansion
:top
Rem Version 23.
Rem Older versions do not have version numbers.
Rem made by SetLucas [Lucas Elliott] with IT Command.
Rem This code is under the GNU Public License Version 3.

set ps1sver=23
set verdate=Dec 4th 2021
set oldnum=NO
set _errorcount=0
set totalnum=
set _pause=false
set randvar=%random%%random%%random%%random%%random%%random%%random%
set _l=false
set _loop=false
set _WaitTime=4
set _pauseloop=false
set _visible=false
pushd "%TEMP%"
if exist "ps1s.%randvar%" goto top
echo. >"ps1s.%randvar%"
if not exist "ps1s.%randvar%" (
	echo Error: No Write permission for temp folder.
	exit /b 8
)
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
set "DEL=%%a"
)
rem Prepare a file "X" with only one dot
<nul > X set /p ".=."
rem Find parameters
if "%~1"=="/?" goto help
if "%~1"=="/h" goto help
if "%~1"=="-?" goto help
if "%~1"=="-h" goto help
if "%~1"=="-v" goto version
if "%~1"=="--help" goto help
if "%~1"=="-help" goto help
if /i "%~1"=="/S" tasklist /fi "imagename eq powershell.exe" /fo list /v & exit /b
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/TS" >nul 2>nul
if %errorlevel%==0 goto loopforts
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/version" >nul 2>nul
if %errorlevel%==0 goto version
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/ver" >nul 2>nul
if %errorlevel%==0 goto version
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/TK" >nul 2>nul
if %errorlevel%==0 goto loopfortk
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/s" >nul 2>nul
if %errorlevel%==0 set _silent=true
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/p" >nul 2>nul
if %errorlevel%==0 set _pause=true
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/w" >nul 2>nul
if %errorlevel%==0 set _loop=true
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/v" >nul 2>nul
if %errorlevel%==0 set _visible=true
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/g" >nul 2>nul
if %errorlevel%==0 goto get
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/k" >nul 2>nul
if %errorlevel%==0 goto lkill
echo "{%~1} {%~2} {%~3} {%~4} {%~5} {%~6} {%~7}" | find /i "/l" >nul 2>nul
if %errorlevel%==0 set _pauseloop=true & cls
goto nxt


:version
cls
echo [=================================================]
echo [[96mps1s[0m - powershell.exe instance manager and toolset]
echo [+++++++++++++++++++++++++++++++++++++++++++++++++]
echo [   Made by SetLucas (Lucas Elliott) with ITCMD   ]
echo [  GNU Public license - Please Reference Usage    ]
echo [=================================================]
echo.
echo [90;4mhttps://github.com/ITCMD/PS1S[0m
echo [96mps1s Version: %ps1sver%  from  [90m%verdate%[0m.
echo.
echo Check for updates?
choice
if %errorlevel%==2 exit /b
echo.
for /f "tokens=1,2 delims=#" %%A in ('curl -s -L https://github.com/ITCMD/ps1s/raw/master/version-number.txt') do (
	set curver=%%~A
	set badver=%%~B
)
set vercheck=
for /f "delims=0123456789" %%i in ("%curver%") do set "vercheck=%%i"
if defined vercheck (
	echo Query to Update Failed. Value recieved was not numerical.
	echo Please check your connection and manually look for an update
	echo on https://github.com/ITCMD/ps1s or try again later.
	echo.
	echo Apologies for any inconvenience. The update system may have changed.
	endlocal
	exit /b 1
)
if %curver% GTR %ps1sver% (
	if %ps1sver% LEQ %badver% (
		echo [93mUpdate Available:[0m
		echo.
		echo [91mUpdate is urgent.[0m
		echo This version of ps1s has been deemed unstable.
		echo updating is strongly recommended.
		echo download from https://github.com/ITCMD/ps1s
		exit /b 9
	) ELSE (
		echo [92mUpdate Available:[0m Version %curver%
		echo.
		echo [32mUpdate is not urgent.[0m
		echo This update includes new features and / or bug fixes.
		echo Updating to this version is recommended in non-automated
		echo circumstances, but is not necessary. View the update at
		echo https://github.com/ITCMD/ps1s
		exit /b 8
	)
)
if %curver% LSS %ps1sver% (
	echo [95mVersion Discrepency.[0m
	echo.
	echo The version number of ps1s you have [%ps1sver%] is higher
	echo than the latest version according to the github page [%curver%].
	echo Perhaps you have a beta or have disabled updates.
	echo View the latest official release at: https://github.com/ITCMD/ps1s.
	exit /b 69
)
if %curver%==%ps1sver% (
	echo [92;4mYou are up to date.[0m
	echo.
	echo [32mThere are no public updates available at this time.[0m
	exit /b 0
)
echo ERROR: Unexpected result from server:
curl -L https://github.com/ITCMD/ps1s/raw/master/version-number.txt
exit /b 1



:lkill
if "%returnedpidlist%"=="" goto nxt
if /i "%~1"=="/k" (
	set _gv=%~2
) Else (
	shift
	goto lkill
)
if "%_gv%"=="" (
	echo Error: Syntax incorrect. Provide a value for /k.
	exit /b 2
)

if "%_visible%"=="true" (
	echo Error: Cannot use with /v.
	exit /b 2
)
set _foundpid=false
for %%A in (%returnedpidlist%) do (
	if "!_foundpid!"=="true" (
		taskkill /f /PID "%%~A"
		endlocal & exit /b !errorlevel!
	)
	if "%_gv%"=="%%~A" set _foundpid=true
)
echo ERROR: Could not find item %_gv% in previous ps1s list.
endlocal exit /b 1
exit /b


:get
if "%returnedpidlist%"=="" goto nxt
if /i "%~1"=="/g" (
	set _gv=%~2
) Else (
	shift
	goto get
)
if "%_gv%"=="" (
	echo Error: Syntax incorrect. Provide a value for /g.
	exit /b 2
)
if "%_visible%"=="true" (
	echo Error: Cannot use with /v.
	exit /b 2
)
set _foundpid=false
for %%A in (%returnedpidlist%) do (
	if "!_foundpid!"=="true" (
		echo %%~A|clip
		endlocal & exit /b !errorlevel!
	)
	if "%_gv%"=="%%~A" set _foundpid=true
)
echo ERROR: Could not find item #%_gv% in previous ps1s list.
endlocal exit /b 1
exit /b


:loopfortk
if /i "%~1"=="/TK" goto endfortkloop
if "%~1"=="" echo Error. Could not find instance with that title. & exit /b
shift
goto loopfortk
:endfortkloop
shift
set _ts=%~1
goto taskkill


:taskkill
Rem Get Title List
set num=0
tasklist /fi "imagename eq powershell.exe" /fo list /v | find /I "Window Title:" >ps1s.%randvar%
for /F "tokens=*" %%A in  (ps1s.%randvar%) do  (
set /a num+=1
set "Title!num!=%%A"
)
set totalnum=!num!
Rem Get PID List
set num=0
tasklist /fi "imagename eq powershell.exe" /fo list /v | find /I "PID:" >ps1s.%randvar%
for /F "tokens=*" %%A in (ps1s.%randvar%) do  (
set /a num+=1
set PID!num!=%%A
)
Rem error check
if not %num%==%totalnum% goto :taskkill
Rem Clear Temp Files
del /f /q "ps1s.%randvar%"
set num=0
:tkloop
Rem Go in loop checking if PID title matches given title.
set /a num+=1
if "!Title%num%!"=="Window Title: %_ts%" goto isritetk
Rem Check if there is a window with same title but selected text.
if "!Title%num%!"=="Window Title: Select %_ts%" goto isritetk
Rem if gone through all possible PIDs exit with error code 1
if %num%==%totalnum% exit /b 1
goto tkloop
:isritetk
Rem Correct Instance was found. Separate PID.
set str=!PID%num%!
set "result=%str::=" & set "result=%"
set result=%result: =%
Rem Check PID matches title and repeat up to 3 times if not.
tasklist /fi "PID eq %result%" /fo list /v | find /I "Window Title: %_ts%" >nul 2>nul
if %errorlevel%==0 goto validatedtk
tasklist /fi "PID eq %result%" /fo list /v | find /I "Window Title: Select %_ts%" >nul 2>nul
if %errorlevel%==0 goto validatedtk
if %_errorcount% GTR 2 exit /b 1
set /a _errorcount+=1
goto taskkill
:validatedtk
Rem Exit Temp and Taskkill.
popd
taskkill /f /PID %result%
endlocal
exit /b

:loopforts
Rem start of /TS process. Extract Variable with shifting for stability.
if "%~2"=="" (
	echo ERROR: No Title Given. Use /h for syntax.
	exit /b 2
)
set _ts=%~2
goto ts


:nxt
Rem Start of Scan process for Display Modes (default, /w, /p, /l).
Rem Set Window Titles to Vars
set checkchangesum=
set num=0
tasklist /fi "imagename eq powershell.exe" /fo list /v | find /I "Window Title:" >ps1s.%randvar%
for /F "tokens=*" %%A in  (ps1s.%randvar%) do  (
	set /a num+=1
	set Title!num!=%%A
	set "checkchangesum=!checkchangesum!%%~A"
)
set totalnum=%num%
Rem Set Mem to Vars
set num=0
tasklist /fi "imagename eq powershell.exe" /fo list /v | find /I "Mem Usage:" >ps1s.%randvar%
for /F "tokens=*" %%A in  (ps1s.%randvar%) do  (
	set /a num+=1
	set Mem!num!=%%A
)
set totalmemnum=%num%
Rem Set PIDs to Vars and set checksum to test if change on /w
set num=0
tasklist /fi "imagename eq powershell.exe" /fo list /v | find /I "PID:" >ps1s.%randvar%
for /F "tokens=*" %%A in  (ps1s.%randvar%) do  (
	set /a num+=1
	set str=%%~A
	set str=!str:~14!
	set PID!num!=!str!
	set "checkchangesum=!checkchangesum!!num!!str!"
)
rem clean temp file
del /f /q "ps1s.%randvar%"
rem check for errors and restart if present.
if not %num%==%totalnum% goto nxt
if not %num%==%totalmemnum% goto nxt
rem check for title and pid mismatches with up to 3 retries
set num=0
:nxtverloop
set /a num+=1
tasklist /fi "PID eq !PID%num%!" /fo list /v | find /i "!title%num%!" >nul 2>nul
if not %errorlevel%==0 (
	if %_errorcount% GTR 2 (
		set >"%appdata%\ps1s.%randvar%.crashreport.log"
		echo ERROR: Fatal mismatch in title and PID.
		echo.
		echo Please report @ https://github.com/ITCMD/ps1s
		echo Please attach the file:
		echo "%apdata%\ps1s.%randvar%.crashreport.log"
		echo and the output of ps1s /S
		endlocal
		exit /b 1
	)
	set /a _errorcount+=1
	goto nxt
)


rem if on loop, goto area to check for change before displaying
if "%_loop%"=="true" goto lloop


:Display
rem display section
set returnedpidlist=
echo [92mps1s by IT Command       (use /? for help)     %totalnum% Windows Open[0m
echo =====================================================================================================
set num=0
:tpds
rem Checks if /v is active to determine whether it should ignore powershell.exe instances with no title.
set /a num+=1
if "%_visible%"=="true" (
	echo !Title%num%! | find /i "Window Title: Windows Powershell" >nul 2>nul
	if !errorlevel!==0 goto detstop
	echo !Title%num%! | find /i "Window Title: Select Windows Powershell" >nul 2>nul
	if !errorlevel!==0 goto detstop
)
rem sets initial number
if %num% LSS 10 call :Colorecho21 08 "%num% ]   "
if %num% GTR 9 call :Colorecho21 08 "%num%]   "
rem cleans up and displays pid
rem set str=!PID%num%!
rem set "result=%str::=" & set "result=%"
rem set result=%result: =%
set result=!PID%num%!

call :Colorecho21 0b "PID:  %result%  "
rem sets storepid value for /k and /g
set "storepid=%storepid%%num% %result% "
rem displays space if short pid and displays title 
if %result% LSS 10000 call :Colorecho21 0f " "
call :Colorecho21 0e "!Mem%num%!  "
echo [92m!Title%num%![0m
:detstop
rem goes to stop section if at end, otherwise loops display action.
if %num%==%totalnum% goto stops
goto tpds
:stops
echo =====================================================================================================
rem determines pause, pause loop, or wait.
if "%_pause%"=="true" pause
if /i "%~1"=="/l" echo Press any key to continue or CTRL+C to quit . . . & pause>nul & cls & goto nxt
if /i "%~2"=="/l" echo Press any key to continue or CTRL+C to quit . . . & pause>nul & cls & goto nxt
if /i "%~3"=="/l" echo Press any key to continue or CTRL+C to quit . . . & pause>nul & cls & goto nxt
if /i "%~1"=="/w" goto waiting
if /i "%~2"=="/w" goto waiting
if /i "%~3"=="/w" goto waiting
goto exit


:waiting
rem sets checksum to previous sum and waits designated time
set PrevSum=%checkchangesum%
timeout /t %_WaitTime% >nul 2>nul
goto nxt

:lloop
rem checks if sums match which means no change.
if not "%checkchangesum%"=="%PrevSum%" cls & goto Display
goto waiting




:help
call :Colorecho21 0f "ps1s Command Prompt Window Lister by IT Command"
echo.
echo.
echo ps1s [/S] [/P] [/L] [/W] [/V] [/Ver] [/G Num] [/K Num] [/TK String] [/TS String]
echo.
echo  /S         Displays the simple but high information version (fast)
echo  /P         Pauses Before Exiting. Usefull if using from Run.
echo  /L         Pauses and refreshes on press of key. Use CTRL+C to quit.
echo  /W         Refreshes only when a new cmd instance starts (new PID).
echo  /G         For use when listing entries. Copies an entry from a
echo             displayed list to clipboard.
echo  /K         For use when listing entries. Kills an entry from
echo             displayed list.
echo  Note:      /G and /K will pull numbers and PIDs from the previous ps1s
echo             list through a variable to increase accuracy.
echo  Num        The number of the entry to copy to clipboard or kill.
echo  /V         Ignores unnamed windows.
echo  /Ver       Prints the current version of ps1s and allows you to check
echo             for an update. /version may also be used.
echo  /TS        Use within a batch file to search for a Window Title.
echo  /TK        Use within a batch file to kill a matching Window Title.
echo  String     The Window Title to search for with /TS or /TK
echo.
echo.
echo  with /TS the errorlevel will be set to 1 if the title was not found.
echo  If it is found, the errorlevel will be set to the PID of the cmd instance.
echo.
pause
echo.
echo Example:
echo.
echo    ps1s /TS "My Window"
echo.
echo     The Above Command Will set the errorlevel to the PID of the cmd instance
echo     with the title "My Window" (set with the title command). If the instance
echo     is not found (there is no running window) the errorlevel will be 1.
echo     if the Syntax was incorrect, errorlevel will be set to 2.
echo.
echo.
call :Colorecho21 07 " Created by Lucas Elliott with IT Command"
call :Colorecho21 0b "  www.itcommand.net"
echo.
echo.
goto exit


:ts
set num=0
rem gets titles
tasklist /fi "imagename eq powershell.exe" /fo list /v | find /I "Window Title:" >ps1s.%randvar%
for /F "tokens=*" %%A in  (ps1s.%randvar%) do  (
	set /a num+=1
	set Title!num!=%%A
)
set totalnum=%num%
rem gets PIDs
set num=0
tasklist /fi "imagename eq powershell.exe" /fo list /v | find /I "PID:" >ps1s.%randvar%
for /F "tokens=*" %%A in  (ps1s.%randvar%) do  (
	set /a num+=1
	set PID!num!=%%A
)
rem checks for errors and restarts ts if found
if not %num%==%totalnum% goto ts
del /f /q ps1s.%randvar%
set num=0
:tsloop
set /a num+=1
if "!Title%num%!"=="Window Title: %_ts%" goto isrite
if %num%==%totalnum% (
	popd
	endlocal
	exit /b 1
)
goto tsloop
:isrite
::window was found
set str=!PID%num%!
set "result=%str::=" & set "result=%"
set result=%result: =%
Rem Check PID matches title and repeat up to 3 times if not.
tasklist /fi "PID eq %result%" /fo list /v | find /I "Window Title: %_ts%" >nul 2>nul
if %errorlevel%==0 goto validatedtk
tasklist /fi "PID eq %result%" /fo list /v | find /I "Window Title: Select %_ts%" >nul 2>nul
if %errorlevel%==0 goto validatedtk
if %_errorcount% GTR 2 exit /b 1
set /a _errorcount+=1
goto taskkill
:validatedtk
popd
endlocal & exit /b %result%


rem colorecho function for compatibility with older versions of windows and speed in echoing.
:colorEcho21
set "param=^%~2" !
set "param=!param:"=\"!"
findstr /p /A:%1 "." "!param!\..\X" nul
<nul set /p ".=%DEL%%DEL%%DEL%%DEL%%DEL%%DEL%%DEL%"
exit /b


:exit
popd
endlocal & set returnedpidlist=%storepid%
exit /b