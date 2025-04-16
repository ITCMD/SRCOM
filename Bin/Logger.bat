@echo off
mode con:cols=97 lines=44
setlocal EnableDelayedExpansion
:reset
title SRLog - Simple Radio Logger by W1BTR
rem version 5.2.beta
cls
if not exist kbd.exe (
    echo [91mERROR: [97mSRLogger depends on KBD.exe for navigation.
    echo Please ensure this file is in the same folder as SRLogger.
    pause
    exit /b
)
if not exist Logs md Logs\
cd Logs\
rem you can change this command to communicate directly with your rig without FLRig if you need to:
set rigctlcmd=call "..\Hamlib\Bin\rigctl.exe" --model=4
rem =======================================================
rem defaults [These are all changable in the settings, do not change these values]
set query=TRUE
set rig=1
set FLRig=0
set datetimeoncall=TRUE
set FreqOften=FALSE
set FlrigNow=1
set Logfile=001.hamlog
set RSTD=59
set TerminalMode=FALSE
set startedflrig=FALSE
set Freq=14.2520
set countrysearch=TRUE
set statesearch=TRUE
set Power=100
set flriglaunch=FALSE
set rigmulti=100
set logsearchstat=Search All Logs in Log Folder
set searchlogcommand=dir /b /s *.hamlog
set mode=SSB
set tserial=NONE
set tstate=NONE
set tclass=NONE
set satlog=N
set contactsearch=TRUE
set countrysearch=TRUE
set statesearch=TRUE
rem setup
if exist ..\srlogSettings.cmd call ..\srlogsettings.cmd
if "%satlog%"=="Y" (
    set Satellite=[93mSatellite
    set SatColor=[7m
)
if "%callsign%"=="" (
    echo Please enter your callsign:
    set /p callsign=">"
    set tcall=!callsign!
    call :savesettings
    call :callsignlookup
)
if "%gridsquare%"=="" (
    set gridsquare=%tsquare%
    echo Please enter your gridsquare or press enter for %tsquare%:
    set /p gridsquare=">"
    call :savesettings
)
if "%op%"=="" (
    echo Please enter your name:
    set /p op=">"
    call :savesettings
)
if "%license%"=="" (
    echo Choose License
    echo N] Novice
    echo T] Technician
    echo G] General
    echo A] Advanced
    echo E] Extra
    choice /c 12345ntgae
    if !errorlevel!==1 set license=N
    if !errorlevel!==2 set license=T
    if !errorlevel!==3 set license=G
    if !errorlevel!==4 set license=A
    if !errorlevel!==5 set license=E
    if !errorlevel!==6 set license=N
    if !errorlevel!==7 set license=T
    if !errorlevel!==8 set license=G
    if !errorlevel!==9 set license=A
    if !errorlevel!==10 set license=E
    call :savesettings
)
if "%flriglaunch%"=="TRUE" (
    if exist "%flrigpath%" (
        tasklist | find /i "flrig.exe" >nul 2>nul
        if !errorlevel!==0 goto skiplaunchflrig
        echo Launching FLRig . . .
        set startedflrig=TRUE
        start "" "%flrigpath%"
        timeout /t 3
    ) ELSE (
        echo ERROR:
        echo Could not find "%flrigpath%"
        echo Failed to launch FLRig.
        pause
    )
)
:skiplaunchflrig
if "%FLRig%"=="1" (
    %rigctlcmd% get_freq >nul 2>rigctlerror
    find /i "error" "rigctlerror" 2>nul >nul
    if !errorlevel!==0 goto ErrorFLRig
    for /f %%i in ("rigctlerror") do set size=%%~zi

    if "!size!"=="0" goto ErrorFLRigTimeout
    del /f /q rigctlerror
)
call :setdatetime
goto clear


:ErrorFLRigTimeout
cls
echo [91mFLRig Error[90m
echo Connection to FLRig timed out (no response).
echo.
echo [0mMake sure FLRig is launched and configured
echo.
echo 1] Retry
echo 2] Disable FLRig
echo 3] Reboot FLRig
choice /c 123
if %errorlevel%==1 (
    cd ..
    goto reset
)
if %errorlevel%==3 (
    taskkill /f /im flrig.exe 2>nul
    taskkill /f /im flrig.exe 2>nul
    taskkill /f /im flrig.exe 2>nul
    cd ..
    goto reset
)
set flrig=0
set flrignow=0
call :savesettings
goto clear

:ErrorFLRig
cls
echo [91mFLRig Error[90m
type rigctlerror
echo.
echo [0mMake sure FLRig is launched and configured
echo.
echo 1] Retry
echo 2] Disable FLRig
choice /c 12
if %errorlevel%==1 (
    cd ..
    goto reset
)
set flrig=0
set flrignow=0
call :savesettings
goto clear
:mainmenu
cls
if exist "SearchList.*.temp" del "SearchList.*.temp"
if "%flrig%"=="1" (
    echo  [92mF1[0m-View Logs [92mF2[0m-Export [92mF3[0m-%satcolor%Sattelite Mode[0m [92mF4[0m-Grid Square [92mF5[0m-Operator [92mF6[0m-License [92mF7[0m-More[0m [92mF8[0m-[102;30mFLRig[0m
) ELSE (
    echo  [92mF1[0m-View Logs [92mF2[0m-Export [92mF3[0m-%satcolor%Sattelite Mode[0m [92mF4[0m-Grid Square [92mF5[0m-Operator [92mF6[0m-License [92mF7[0m-More[0m [92mF8[0m-FLRig[0m
)
echo [90m-------------------------------------------------------------------------------------------------[0m
call :showrecentlog
echo [90m-------------------------------------------------------------------------------------------------[0m
echo  [96m[ENTER] to save below log entry[0m ^| Welcome to SRCOM Logger ^| User: [102;30m%callsign%-%op%-%gridsquare%[0m
call :rangeband
echo [90m-Key----Description-----------VALUE--------------------------------------------------------------[0m
rem  ----------------------------------------------------------------------------------------------
echo  0 F Frequency / Mode: [97;4m%Freq%[0m %modecolor%%mode%[31m %power% Watts[0m %Satellite%[0m
if "%tcall%"=="" (
    echo  1 C   Their Callsign:
    goto skipcsq
)
for /f "tokens=1 delims==" %%A in ('set pre_val 2^>nul') do (
    set %%~A=
)
set prevcount=0
set PrevTrigger=False
set prev=
rem dir /b /s *.hamlog
if exist "*.hamlog" (
    if "%contactsearch%"=="TRUE" (
        for /f "delims=" %%A in ('%searchlogcommand%') do (
            for /f "skip=2 delims=" %%B in ('find /i ",%tcall%," "%%~A"') do (
                set /a prevcount+=1
                set pre_fileVal!prevcount!=%%~nA%%~xA
                set pre_Val!prevcount!=%%~B
                set PrevTrigger=True
                set prev=[91;7m!prevcount! Contacts in History [Press H][0m
            )
        )
    )
)
rem previous lookups?
if %query%==TRUE (
    echo  1 C   Their Callsign: [92m%tcall% [90m[%TLicense: =%] [0mZ -^> QRZ.com   %prev%
) ELSE (
    echo  1 C   Their Callsign: [92m%tcall% Z -^> QRZ.com   %prev%[0m
)
:skipcsq
if %query%==TRUE (
if "%tstat%"=="C" echo                      [91mLicense Cancelled[0m
if "%tstat%"=="E" echo                      [91mLicense Expired[0m
if "%tstat%"=="A" echo                      [92mLicense Active[0m
if "%tstat%"=="T" echo                      [101;30mLICENSE TERMINATED[0m
)                        
if "%top%"=="NONE" (
    echo  2 O             Name:
) ELSE (
    echo  2 O             Name: %top%
) 
if "%tsquare%"=="" (
    echo  3 Q              QTH: %qthmsg%
) ELSE (
    echo  3 Q              QTH: %qthmsg% [36m[%tsquare%][0m
)
echo  4 S         RST Sent: %RSTs%
echo  5 R         RST Recv: %RSTr%
echo  6 D         UTC Date: %ldate%
echo  7 T         UTC Time: %ltime%
echo  8 N             Note: [97m%note%[0m
if not "%ctd%"=="" (
    echo  9 X     Contest Data: [93m%ctd:#=^|%[0m
) ELSE (
    echo  9 X     Contest Data:
)
echo [90m-------------------------------------------------------------------------------------------------[0m
echo  [32mF-Frequency/Mode C-Callsign D-Date T-Time S-RSTs R-RSTr A-AutoUTC O-Name Q-QTH X-Contest DATA
echo  N-Note Z-QRZ V-A599 P-Power G-DebuG ESC-Clear End-Exit     PRESS \ FOR HELP AND KEYBIND GUIDE[96m
:kbd
call ..\kbd.exe
if %errorlevel%==97 (
    call :setdatetime
    goto mainmenu
)
if %errorlevel%==79 goto end
if %errorlevel%==27 goto clear
if %errorlevel%==48 goto freqmode
if %errorlevel%==102 goto freqmode
if %errorlevel%==118 (
    set RSTs=%RSTD%
    set RSTr=%RSTD%
    goto mainmenu
)
if %errorlevel%==13 goto savelog
if %errorlevel%==9 goto savelog
if %errorlevel%==99 goto tcall
if %errorlevel%==103 goto debug
if %errorlevel%==49 goto tcall
if %errorlevel%==100 goto date
if %errorlevel%==54 goto date
if %errorlevel%==116 goto time
if %errorlevel%==55 goto time
if %errorlevel%==66 goto flrigmenu
if %errorlevel%==112 goto Power
if %errorlevel%==115 goto rsts
if %errorlevel%==119 goto tcallw
if %errorlevel%==101 goto tcalle
if %errorlevel%==107 goto tcallk
if %errorlevel%==97 goto tcalla
if %errorlevel%==104 if not "%prev%"=="" goto history
if %errorlevel%==52 goto rsts
if %errorlevel%==114 goto rstr
if %errorlevel%==53 goto rstr
if %errorlevel%==111 goto name
if %errorlevel%==50 goto name
if %errorlevel%==113 goto qth
if %errorlevel%==51 goto qth
if %errorlevel%==120 goto ctd
if %errorlevel%==57 goto ctd
if %errorlevel%==110 goto note
if %errorlevel%==56 goto note
if %errorlevel%==59 goto viewlogs
if %errorlevel%==122 (
    start https://www.qrz.com/db/%tcall%
    goto mainmenu
)
if %errorlevel%==59 goto viewlogs
if %errorlevel%==60 goto exportlogs
if %errorlevel%==61 (
    if "%satlog%"=="Y" (
        set Satellite=
        set SatColor=
        set satlog=N
        call :savesettings
        goto mainmenu
    ) ELSE (
        set Satellite=[93mSatellite
        set SatColor=[7m
        set satlog=Y
        call :savesettings
        goto mainmenu
    )
)
if %errorlevel%==62 goto setgridsquare
if %errorlevel%==63 goto setop
if %errorlevel%==64 goto license
if %errorlevel%==65 goto MoreSettings
if %errorlevel%==92 goto help
if %errorlevel%==79 cd ..&exit /b & exit /b
goto kbd

:help
cls
echo.
type ..\help.srlog.txt | more
echo.
pause
goto mainmenu

:power
echo Enter power in Watts (Example: 20)
set /p power=">"
goto mainmenu

:exportlogs
cls
echo Select format to export current log in:
echo.
echo 1] ADIF
echo X] Cancel
echo.
choice /c 1x
if %errorlevel%==1 goto adifexport
if %errorlevel%==3 goto mainmenu


:FLRigMenu
call :savesettings
cls
echo [96mFLRIG Menu[0m
echo.
if "%flrig%"=="1" (
    echo 1] FLRig: [96mEnabled[0m
) ELSE (
    echo 1] FLRig: [91mDisabled[0m
)
echo 2] FLRig Launch: [96m%flriglaunch%[0m
if %FLRigFreq%==1 (
    echo 3] Frequency Pull: [96mTRUE[0m
) ELSE (
    echo 3] Frequency Pull: [91mFALSE[0m
)
if %FLRigMode%==1 (
    echo 4] Mode Pull: [96mTRUE[0m
) ELSE (
    echo 4] Mode Pull: [91mFALSE[0m
)
if %FLRigWatts%==1 (
    echo 5] Power Pull: [96mTRUE[0m
) ELSE (
    echo 5] Power Pull: [91mFALSE[0m
)
echo 6] FLRig Power Adjustment: [92m*!rigmulti![0m
echo X] Back
choice /c 123456X
if %errorlevel%==1 (
    if %flrig%==1 (
        set flrig=0
    ) ELSE (
        set flrig=1
    )
    goto flrigmenu
)

if %errorlevel%==2 goto flriglaunch
if %errorlevel%==3 (
    if %FLRigFreq%==1 (
        set FLRigFreq=0
    ) ELSE (
        set FLRigFreq=1
    )
    goto flrigmenu   
)
if %errorlevel%==4 (
    if %FLRigMode%==1 (
        set FLRigMode=0
    ) ELSE (
        set FLRigMode=1
    )
    goto flrigmenu   
)
if %errorlevel%==5 (
    if %FLRigWatts%==1 (
        set FLRigWatts=0
    ) ELSE (
        set FLRigWatts=1
    )
    goto flrigmenu   
)
if %errorlevel%==6 goto poweradjust
goto mainmenu


:flriglaunch
echo.
echo [92mWould you like flrig to automatically launch on startup if it is not running?[0m
choice
if %errorlevel%==2 (
    set flriglaunch=FALSE
    goto FLRigMenu
)
set flrigpath=
dir /b "C:\Program Files (x86)\flrig-*" >nul 2>nul
if %errorlevel%==0 for /f "tokens=*" %%A in ('dir /b "C:\Program Files (x86)\flrig-*"') do set flrigpath=C:\Program Files (x86)\%%~A\flrig.exe
dir /b "C:\Program Files\flrig-*" >nul 2>nul
if %errorlevel%==0 for /f "tokens=*" %%A in ('dir /b "C:\Program Files\flrig-*"') do set flrigpath=C:\Program Files\%%~A\flrig.exe
if not "%flrigpath%"=="" echo [92mUse %flrigpath%?[0m
if not "%flrigpath%"=="" (
    choice
    if %errorlevel%==1 (
        set flriglaunch=TRUE
        goto skipmanualflrig
    )
)
echo Enter path to flrig (or drag and drop exe into this window and press enter):
echo [90mEnter -X to cancel[0m
set /p flrigpath=">"
set flrigpath=%flrigpath:"=%"
if /i "%flrig:"=%"=="-x" goto flriglaunch
if not exist "%flrigpath%" echo (
    File not found.
    pause
    set flrigpath=
    set flriglaunch=FALSE
    goto flriglaunch
)
:skipmanualflrig
tasklist | find /i "flrig.exe" >nul 2>nul
if %errorlevel%==0 (
    echo FLRig is already running, so not launching now.
) ELSE (
    echo Launching FLrig now . . .
    start "" "%flrigpath%"
)
goto FLRigMenu

:adifexport
cls
set adife=%logfile%.ADI
echo Exporting to %adife%...[97m
echo This will take some time.[90m
call :getlen2 op op_len
call :getlen2 gridsquare gs_len
call :getlen2 callsign calllength
echo ADIF Export for SRLogger by W1BTR>"%adife%"
(echo ^<PROGRAMID:3^>FLE)>>"%adife%"
(echo ^<ADIF_VER:5^>3.1.0)>>"%adife%"
(echo ^<EOH^>)>>"%adife%"
for /f "usebackq tokens=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18 delims=," %%A in ("%logfile%") do (
    set UniqueID=%%~A
    set pcall=%%~B
    call :getlen2 pcall pcall_len
    set pname=%%~J
    call :getlen2 pname pname_len
    set pdate=%%~C
    set pdate=!pdate:-=!
    set ptime=%%~D
    set ptime=!ptime::=!
    set pfreq=%%~F
    call :getlen2 pfreq pfreq_len
    set pband=%%~E
    call :getlen2 pband pband_len
    set pmode=%%~G
    call :getlen2 pmode pmode_len
    set prsts=%%~H
    call :getlen2 prsts prsts_len
    set prstr=%%~I
    call :getlen2 prstr prstr_len
    set psatt=%%~K
    set pserl=%%~L
    call :getlen2 pserl pserl_len
    set pnote=%%~M
    call :getlen2 pnote pnote_len
    set prig=%%~N
    set pstate=%%~O
    call :getlen2 pstate pstate_len
    set pclass=%%~P
    call :getlen2 pclass pclass_len
    set ppower=%%~Q
    call :getlen2 ppower ppower_len
    set pextra=
    if not "!psatt!"=="N" set pextra= ^<PROP_MODE:3^>SAT
    if not "!pnote!"=="NONE" set pextra=!pextra! ^<COMMENT:!pnote_len!^>!pnote!
    if not "!pserl!"=="NONE" set pextra=!pextra! ^<SRX:!pserl_len!^>!pserl!
    if not "!pstate!"=="NONE" set pextra=!pextra! ^<STATE:!pstate_len!^>!pstate!
    if not "!pclass!"=="NONE" set pextra=!pextra! ^<CLASS:!pclass_len!^>!pclass!
    if not "!ppower!"=="NONE" set pextra=!pextra! ^<TX_PWR:!ppower_len!^>!ppower!
    echo ^<STATION_CALLSIGN:!calllength!^>%callsign% ^<CALL:!pcall_len!^>!pcall! ^<QSO_DATE:8^>!pdate! ^<TIME_ON:4^>!ptime! ^<BAND:!pband_len!^>!pband! ^<MODE:!pmode_len!^>!pmode! ^<FREQ:!pfreq_len!^>!pfreq! ^<RST_SENT:!prsts_len!^>!prsts! ^<RST_RCVD:!prstr_len!^>!prstr! ^<MY_GRIDSQUARE:!gs_len!^>%gridsquare% ^<MY_NAME:%op_len%^>%op%!pextra! ^<EOR^>
    (
        echo ^<STATION_CALLSIGN:!calllength!^>%callsign% ^<CALL:!pcall_len!^>!pcall! ^<QSO_DATE:8^>!pdate! ^<TIME_ON:4^>!ptime! ^<BAND:!pband_len!^>!pband! ^<MODE:!pmode_len!^>!pmode! ^<FREQ:!pfreq_len!^>!pfreq! ^<RST_SENT:!prsts_len!^>!prsts! ^<RST_RCVD:!prstr_len!^>!prstr! ^<MY_GRIDSQUARE:!gs_len!^>%gridsquare% ^<MY_NAME:%op_len%^>%op%!pextra! ^<EOR^>
    )>>"%adife%"
)
echo [92mdone. Saved to %adife%
pause
goto mainmenu

:viewlogs
set LogMax=35
set TerminalLogMax=23
if "%TerminalMode%"=="TRUE" set LogMax=!TerminalLogMax!
set search=false
mode con:cols=101 lines=44
for /f "tokens=1 delims==" %%A in ('set pre_val') do (
    set %%~A=
) 2>nul
set entrycount=0
set entrytotal=0
set PageTrack=0
set pageNum=1
set pagecount=1
for /f "usebackq tokens=1 delims=" %%A in ("%Logfile: =%") do (
    set /a entrycount+=1
    set /a entrytotal+=1
    if !entrycount! GEQ !LogMax! (
        set /a pagecount+=1
        set entrycount=0
    )
)
set DispNum=0
set skipval=0
set kbdEntry=

:vlogloop
cls
set DispNum=%skipval%
set pagetrack=0
if %skipval% GEQ 1 (
    set "skip=skip=%skipval% "
) ELSE (
    set skip=
)
echo [90m[%LogFile%] [92mF1[0m-Search Logs [92mF2[0m-Export

echo [90m-----------------------------------------------------------------------------------------------------[0m
for /f "%skip%usebackq tokens=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18 delims=," %%A in ("%Logfile: =%") do (
    set /a DispNum+=1
    set PrintDispNum=     #!DispNum!
    set /a PageTrack+=1
    set "pre_val!DispNum!=%%~A,%%~B,%%~C,%%~D,%%~E,%%~F,%%~G,%%~H,%%~I,%%~J,%%~K,%%~L,%%~M,%%~N,%%~O,%%~P,%%~Q"
    set displaycallsign=             %%~B
    set disBand=      %%~E
    set disFreq=        %%~F
    set disMode=        %%~G
    set disRSTs=   %%~H
    set disRSTr=   %%~I
    set name=%%~J
    set disName=                 !name:~0,17!
    if "%%~K"=="Y" (
        set disSat=S
    ) ELSE (
        set disSat=
    )
    if "%%~L"=="NONE" (
        set disContest=
    ) ELSE (
        set disContest=C
    )
    if "%%~O"=="NONE" (
        set disContest=
    ) ELSE (
        set disContest=C
    )
    if "%%~P"=="NONE" (
        set disContest=
    ) ELSE (
        set disContest=C
    )
    if "%%~M"=="NONE" (
        set disNote=
    ) ELSE (
        set disContest=N
    )
    echo [96m!PrintDispNum:~-5! [92m!displaycallsign:~-13![0m %%~C %%~D ^|!disband:~-6! !disFreq:~-8! !disMode:~-8! ^|!disRSTs:~-3! !disRSTr:~-3! ^| [93m!disName:~-17![0m ^| %%~N !disSat!!disContest!!disNote![0m
    if !PageTrack! GEQ !LogMax! (
        goto breakforloop
    )
)
:breakforloop
if not exist "%logfile%" (
    echo [96mNo Contacts in this logbook yet[0m
    echo.
)
echo [90m Page !pageNum! of !PageCount! pages [Use Arrow Keys to Change] Press [S] to Search
echo [90m-----------------------------------------------------------------------------------------------------[0m
echo.
echo Enter Entry # to view: [90m[Esc] to Exit[0m
echo|set /p=">%kbdEntry%"
call ..\kbd.exe
if %errorlevel%==115 goto search
if %errorlevel%==59 goto search
if %errorlevel%==27 goto mainmenu
if %errorlevel%==120 goto mainmenu
if %errorlevel%==103 (
    set|more
    pause
    goto vlogloop
)
if %errorlevel%==13 goto pulldetails
if %errorlevel%==60 goto exportlogs
if %errorlevel%==49 set kbdentry=%kbdentry%1
if %errorlevel%==50 set kbdentry=%kbdentry%2
if %errorlevel%==51 set kbdentry=%kbdentry%3
if %errorlevel%==52 set kbdentry=%kbdentry%4
if %errorlevel%==53 set kbdentry=%kbdentry%5
if %errorlevel%==54 set kbdentry=%kbdentry%6
if %errorlevel%==55 set kbdentry=%kbdentry%7
if %errorlevel%==56 set kbdentry=%kbdentry%8
if %errorlevel%==57 set kbdentry=%kbdentry%9
if %errorlevel%==48 set kbdentry=%kbdentry%0
if %errorlevel%==8 (
    if not "%kbdentry%"=="" set kbdentry=%kbdentry:~,-1%
)
if %errorlevel%==75 (
    if %PageNum% GTR 1 (
        set /a PageNum-=1
        set /a skipval-=!LogMax!
    )
)
if %errorlevel%==77 (
    set /a PageNum+=1
    set /a skipval+=!LogMax!
)
goto vlogloop


:search
cls
echo Search Mode
echo.
echo Enter string to search:
set /p searchstring=">"
echo.
echo 1] Search Current Log
echo 2] Search all Logs in Logs folder
echo x] Cancel
choice /c 12x
if %errorlevel%==3 goto vlogloop
if %errorlevel%==1 (
    set searchcom=
    goto searchcurrent
)
if %errorlevel%==2 (
    set SearchList=SearchList.%random%%random%.temp
    dir /b /s *.hamlog >"!searchlist!"
    goto searchall
)

:searchcurrent
cls
set logfilefor!DispNum!=
echo Searching %logfile%...
for /f "tokens=1 delims==" %%A in ('set pre_val') do (
    set %%~A=
) 2>nul
set entrycount=0
set entrytotal=0
set PageTrack=0
set pageNum=1
set pagecount=1
for /f "skip=2 tokens=1 delims=" %%A in ('find /i "%searchstring:"=%" "%Logfile: =%"') do (
    set /a entrycount+=1
    set /a entrytotal+=1
    if !entrycount! GEQ 35 (
        set /a pagecount+=1
        set entrycount=0
    )
)
set DispNum=0
set skipval=0
set kbdEntry=

:searchlogloop
cls
set DispNum=%skipval%
set pagetrack=0
if %skipval% GEQ 1 (
    set /a searchskipval=!skipval! + 2
) ELSE (
    set searchskipval=2
)
set "skip=skip=!searchskipval! "
echo    [96mSEARCH MODE Results for "%searchstring%" in "%logfile%"
echo [90m-----------------------------------------------------------------------------------------------------[0m
for /f "%skip% tokens=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18 delims=," %%A in ('find /i "%searchstring:"=%" "%Logfile: =%"') do (
    set /a DispNum+=1
    set PrintDispNum=     #!DispNum!
    set /a PageTrack+=1
    set "pre_val!DispNum!=%%~A,%%~B,%%~C,%%~D,%%~E,%%~F,%%~G,%%~H,%%~I,%%~J,%%~K,%%~L,%%~M,%%~N,%%~O,%%~P,%%~Q"
    set displaycallsign=             %%~B
    set disBand=      %%~E
    set disFreq=        %%~F
    set disMode=        %%~G
    set disRSTs=   %%~H
    set disRSTr=   %%~I
    set name=%%~J
    set disName=                 !name:~0,17!
    if "%%~K"=="Y" (
        set disSat=S
    ) ELSE (
        set disSat=
    )
    if "%%~L"=="NONE" (
        set disContest=
    ) ELSE (
        set disContest=C
    )
    if "%%~O"=="NONE" (
        set disContest=
    ) ELSE (
        set disContest=C
    )
    if "%%~P"=="NONE" (
        set disContest=
    ) ELSE (
        set disContest=C
    )
    if "%%~M"=="NONE" (
        set disNote=
    ) ELSE (
        set disContest=N
    )
    echo [96m!PrintDispNum:~-5! [92m!displaycallsign:~-13![0m %%~C %%~D ^|!disband:~-6! !disFreq:~-8! !disMode:~-8! ^|!disRSTs:~-3! !disRSTr:~-3! ^| [93m!disName:~-17![0m ^| %%~N !disSat!!disContest!!disNote![0m
    if !PageTrack! GEQ 35 (
        goto breaksearchloop
    )
)
:breaksearchloop
echo [90m Page !pageNum! of !PageCount! pages [Use Arrow Keys to Change] Press [X] to Close Search %skip%
echo [90m-----------------------------------------------------------------------------------------------------[0m
echo.
echo Enter Entry # to view: [90m[Esc] or X to Exit[0m
echo|set /p=">%kbdEntry%"
call ..\kbd.exe
if %errorlevel%==120 goto viewlogs
if %errorlevel%==27 goto mainmenu
if %errorlevel%==103 (
    set|more
    pause
    goto searchlogloop
)
if %errorlevel%==13 (
    set search=true
    goto pulldetails
)
if %errorlevel%==49 set kbdentry=%kbdentry%1
if %errorlevel%==50 set kbdentry=%kbdentry%2
if %errorlevel%==51 set kbdentry=%kbdentry%3
if %errorlevel%==52 set kbdentry=%kbdentry%4
if %errorlevel%==53 set kbdentry=%kbdentry%5
if %errorlevel%==54 set kbdentry=%kbdentry%6
if %errorlevel%==55 set kbdentry=%kbdentry%7
if %errorlevel%==56 set kbdentry=%kbdentry%8
if %errorlevel%==57 set kbdentry=%kbdentry%9
if %errorlevel%==48 set kbdentry=%kbdentry%0
if %errorlevel%==8 (
    if not "%kbdentry%"=="" set kbdentry=%kbdentry:~,-1%
)
if %errorlevel%==75 (
    if %PageNum% GTR 1 (
        set /a PageNum-=1
        set /a skipval-=35
    )
)
if %errorlevel%==77 (
    set /a PageNum+=1
    set /a skipval+=35
)
goto searchlogloop

:searchall
cls
echo Searching all Logs...
for /f "tokens=1 delims==" %%A in ('set pre_val') do (
    set %%~A=
) 2>nul
set entrycount=0
set entrytotal=0
set PageTrack=0
set pageNum=1
set pagecount=1
for /f "usebackq tokens=1 delims=" %%A in ("%searchlist%") do (
    find /i "%searchstring%" "%%~A" >nul 2>nul  
    if !errorlevel!==0 (
        set /a entrycount+=1
        set /a entrytotal+=1
    )
    if !entrycount! GEQ 35 (
        set /a pagecount+=1
        set entrycount=0
    )
)
set DispNum=0
set skipval=0
set kbdEntry=
:searchallloop
cls
set DispNum=%skipval%
set pagetrack=0
if %skipval% GEQ 1 (
    set /a searchskipval=!skipval! + 2
) ELSE (
    set searchskipval=2
)
set "skip=skip=!searchskipval! "
echo    [96mSEARCH MODE: Search Results for "%searchstring%" in All Logs
echo [90m-----------------------------------------------------------------------------------------------------[0m
for /f "usebackq tokens=1 delims=" %%Y in ("%searchlist%") do (
    for /f "%skip% tokens=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18 delims=," %%A in ('find /i "%searchstring:"=%" "%%~Y"') do (
        set /a DispNum+=1
        set PrintDispNum=     #!DispNum!
        set logfilefor!DispNum!=%%~Y
        set /a PageTrack+=1
        set "pre_val!DispNum!=%%~A,%%~B,%%~C,%%~D,%%~E,%%~F,%%~G,%%~H,%%~I,%%~J,%%~K,%%~L,%%~M,%%~N,%%~O,%%~P,%%~Q"
        set displaycallsign=             %%~B
        set disBand=      %%~E
        set disFreq=        %%~F
        set disMode=        %%~G
        set disRSTs=   %%~H
        set disRSTr=   %%~I
        set name=%%~J
        set disName=                 !name:~0,17!
        if "%%~K"=="Y" (
            set disSat=S
        ) ELSE (
            set disSat=
        )
        if "%%~L"=="NONE" (
            set disContest=
        ) ELSE (
            set disContest=C
        )
        if "%%~O"=="NONE" (
            set disContest=
        ) ELSE (
            set disContest=C
        )
        if "%%~P"=="NONE" (
            set disContest=
        ) ELSE (
            set disContest=C
        )
        if "%%~M"=="NONE" (
            set disNote=
        ) ELSE (
            set disContest=N
        )
        echo [96m!PrintDispNum:~-5! [92m!displaycallsign:~-13![0m %%~C %%~D ^|!disband:~-6! !disFreq:~-8! !disMode:~-8! ^|!disRSTs:~-3! !disRSTr:~-3! ^| [93m!disName:~-17![0m ^| %%~N !disSat!!disContest!!disNote![0m
        if !PageTrack! GEQ 20 (
            goto breaksearchallloop
        )
    )
)
:breaksearchallloop
echo [90m Page !pageNum! of !PageCount! pages [Use Arrow Keys to Change] Press [X] to Close Search %skip%
echo [90m-----------------------------------------------------------------------------------------------------[0m
echo.
echo Enter Entry # to view: [90m[Esc] to Exit[0m
echo|set /p=">%kbdEntry%"
call ..\kbd.exe
if %errorlevel%==120 goto viewlogs
if %errorlevel%==27 goto mainmenu
if %errorlevel%==103 (
    set|more
    pause
    goto searchallloop
)
if %errorlevel%==13 (
    set search=true
    goto pulldetails
)
if %errorlevel%==49 set kbdentry=%kbdentry%1
if %errorlevel%==50 set kbdentry=%kbdentry%2
if %errorlevel%==51 set kbdentry=%kbdentry%3
if %errorlevel%==52 set kbdentry=%kbdentry%4
if %errorlevel%==53 set kbdentry=%kbdentry%5
if %errorlevel%==54 set kbdentry=%kbdentry%6
if %errorlevel%==55 set kbdentry=%kbdentry%7
if %errorlevel%==56 set kbdentry=%kbdentry%8
if %errorlevel%==57 set kbdentry=%kbdentry%9
if %errorlevel%==48 set kbdentry=%kbdentry%0
if %errorlevel%==8 (
    if not "%kbdentry%"=="" set kbdentry=%kbdentry:~,-1%
)
if %errorlevel%==75 (
    if %PageNum% GTR 1 (
        set /a PageNum-=1
        set /a skipval-=35
    )
)
if %errorlevel%==77 (
    set /a PageNum+=1
    set /a skipval+=35
)
goto searchallloop

rem EOS2



:pulldetails
if /i "!pre_val%kbdentry%!"=="" goto vlogloop
set change=False
for /f "tokens=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18 delims=," %%A in ('echo !pre_val%kbdentry%!') do (
    set UniqueID=%%~A
    set pcall=%%~B
    echo %%~L]%%~M]%%~N]%%~O]%%~P
    set pname=%%~J
    set pdate=%%~C
    set ptime=%%~D
    set pfreq=%%~F
    set pband=%%~E
    set pmode=%%~G
    set prsts=%%~H
    set prstr=%%~I
    set psatt=%%~K
    set pserl=%%~L
    set pnote=%%~M
    set prig=%%~N
    set pstate=%%~O
    set pclass=%%~P
    set ppower=%%~Q
)
:pulldetailloop
cls
echo [96mLog Entry Details For Log Entry #%kbdEntry% [Unique ID: !UniqueID!]
echo [90m-----------------------------------------------------------------------------------------------------[0m
echo 1     CALLSIGN: [96m!pcall![0m [Press Z for QRZ]
echo 2         NAME: !pname!
echo 3     ON (UTC): [92m!pdate! [97m!ptime![0m
echo 4    FREQUENCY: [7m!pfreq! MHz [0;90m(!pband!)[0m
echo 5         MODE: [95m!pmode![0m
echo 6         RSTs: !prsts!
echo 7         RSTr: !prstr!
echo 8    Satellite: !psatt!
echo 9 CONTEST DATA: SERIAL: !pserl! - CLASS: !pclass! - STATE: !pstate!
echo 0         NOTE: [7m!pnote![0m
echo R          Rig: !prig!
echo P        Power: !ppower!
if not "!logfilefor%kbdentry%!"=="" echo            [90mLog File: !logfilefor%kbdentry%![0m
echo [90m-----------------------------------------------------------------------------------------------------[0m
if "%change%"=="True" echo [91mYou have unsaved changes Press S to save.[0m
echo Press a key to change value. Press Z to Open !pcall!'s QRZ Page. D to Delete. Press X to close.
)
choice /c 1234567890RZXSPD
if %errorlevel%==16 goto deletepulled
if %errorlevel%==14 goto savepulled
if %errorlevel%==15 (
    echo Enter new power level [press enter to cancel]:
    set /p ppower=">"
    set change=True
    goto pulldetailloop
)
if %errorlevel%==12 start https://www.qrz.com/db/!pcall! & goto pulldetails
if %errorlevel%==13 (
    set kbdentry=
    if "%search%"=="true" (
        goto searchlogloop
    ) ELSE (
        goto vlogloop
    )
)
if %errorlevel%==11 (
    Press a key 1-9
    choice /c 123456789
    set prig=!errorlevel!
    set change=True
    goto pulldetailloop
)
if %errorlevel%==10 (
    echo Enter new note [press enter to cancel]:
    set /p pnote=">"
    set change=True
    goto pulldetailloop
)
if %errorlevel%==9 goto editctd
if %errorlevel%==8 (
    echo Satellite as propogation method in log?
    choice
    if !errorlevel!==1 set psatt=Y
    if !errorlevel!==2 set psatt=N
    goto pulldetailloop
)
if %errorlevel%==7 (
    echo Enter new RSTr [press enter to cancel]
    set /p prstr=">"
    set change=True
    goto pulldetailloop
)
if %errorlevel%==6 (
    echo Enter new RSTs [press enter to cancel]
    set /p prsts=">"
    set change=True
    goto pulldetailloop
)
if %errorlevel%==5 (
    echo Enter new Mode [press enter to cancel]
    set /p pmode=">"
    set change=True
    goto pulldetailloop
)
if %errorlevel%==4 (
    echo Enter new Frequency [press enter to cancel]
    set /p pfreq=">"
    set change=True
    goto pulldetailloop
)
if %errorlevel%==3 (
    echo Enter new RSTr [press enter to cancel]
    set /p rstr=">"
    set change=True
    goto pulldetailloop
)
if %errorlevel%==2 (
    echo Enter %pcall%'s name [press enter to cancel]
    set /p pname=">"
    set change=True
    goto pulldetailloop
)
if %errorlevel%==1 (
    echo Enter new Callsign [press enter to cancel]
    set /p pcall=">"
    set change=True
    goto pulldetailloop
)
goto mainmenu

:deletepulled
cls
echo Deleteing QSO with !pcall! - unique ID !UniqueID!...
findstr /i "!UniqueID!,!pcall!" "%LogFile%">>SRLOG.Log.Trashbin
findstr /V /i "!UniqueID!,!pcall!" "%LogFile%">>"%LogFile%.new.temp"
ren "%logfile%" "%logfile%.old"
if not %errorlevel%==0 (
    echo Error: Failed to create median file.
    pause
    goto pulldetails
)
ren "%LogFile%.new.temp" "%logfile%"
if %errorlevel%==0 (
    del /f /q "%logfile%.old"
) ELSE (
    echo Error: Failed to finalize change.
    pause
    goto pulldetails
)
echo [92mCompleted. Deleted entries can be recovered in MORE SETTINGS.[0m
pause
goto viewlogs


:editctd
cls
echo [92mContact: %pcall% - %pdate% %ptime%
echo [90m---------------------------------
echo [96mContest Data[0m
echo 1] Class:  %pclass%
echo 2] State:  %pstate%
echo 3] Serial: %pserl%
choice /c 123X
if %errorlevel%==1 (
    echo Enter Class [i.e. 2A]:
    echo [90mPress Enter to Cancel. Enter NONE to clear.[0m
    set /p pclass=">"
    goto editctd
)
if %errorlevel%==2 (
    echo Enter State [i.e. MA]:
    echo [90mPress Enter to Cancel. Enter NONE to clear.[0m
    set /p pstate=">"
    goto ctd
)
if %errorlevel%==3 (
    echo Enter Serial [i.e. 59001]:
    echo [90mPress Enter to Cancel. Enter NONE to clear.[0m
    set /p pserl=">"
    goto ctd
)
goto pulldetailloop

:savepulled
set saved=false
set newlogfile=%logfile:"=%.%random%%random%.temp
echo Saving . . . (will take longer for larger logs)
for /f "usebackq tokens=1 delims=" %%A in ("%logfile%") do (
    if "%%~A"=="!pre_val%kbdentry%!" (
        echo %UniqueID%,%pcall%,%pDATE%,%pTIME%,%pband%,%pfreq%,%pmode%,%pRSTs%,%pRSTr%,%pname%,%psatt%,%pserl%,%pnote%,%prig%,%pstate: =%,%pclass: =%,%ppower%
        set saved=true
    ) ELSE (
    echo %%~A
    )
)>>"%newlogfile%"
if "%saved%"=="false" (
    echo Failed to Save. Pre-Existing Entry could not be found.
    echo Is there a blank area?
    echo [90m!pre_val%kbdentry%![0m
    echo.
    echo Report on https://github.com/ITCMD/SRLog
    echo.
    pause
    goto pulldetailloop
)
del /f /q "%logfile%"
ren "%newlogfile%" "%logfile%"
echo [92mSave Success[0m
set change=false
echo.
pause
goto pulldetailloop

:history
cls
mode con:cols=101 lines=44
echo %prevcoun% Previous Contacts with %tcall%.
echo [90m-----------------------------------------------------------------------------------------------------[0m
echo [90m         CALLSIGN  UTC  DATE  TIME    BAND FREQUENCY    MODE    S   R         NAME         RIG SPEC
set DispNum=0
set PageTrack=0
for /f "tokens=1,2,3,4,5,6,7,8,9,10,11,12,13,14,17 delims=," %%A in ('set pre_val') do (
    set /a DispNum+=1
    set /a PageTrack+=1
    set displaycallsign=             %%~B
    set disBand=      %%~E
    set disFreq=        %%~F
    set disMode=        %%~G
    set disRSTs=   %%~H
    set disRSTr=   %%~I
    set name=%%~J
    set disName=                 !name:~0,17!
    if "%%~K"=="Y" (
        set disSat=S
    ) ELSE (
        set disSat=
    )
    if "%%~L"=="NONE" (
        set disContest=
    ) ELSE (
        set disContest=C
    )
    if "%%~O"=="NONE" (
        set disContest=
    ) ELSE (
        set disContest=C
    )
    if "%%~P"=="NONE" (
        set disContest=
    ) ELSE (
        set disContest=C
    )
    if "%%~M"=="NONE" (
        set disNote=
    ) ELSE (
        set disNote=N
    )
    echo [96m#!DispNum! [92m!displaycallsign:~-13![0m %%~C %%~D ^|!disband:~-6! !disFreq:~-8! !disMode:~-8! ^|!disRSTs:~-3! !disRSTr:~-3! ^| [93m!disName:~-17![0m ^| [93m%%~N  [96m!disSat!!disContest!!disNote![0m
    if !PageTrack!==25 (
        pause
        set PageTrack=0
    )
)
echo [90m-----------------------------------------------------------------------------------------------------[0m
echo [96mEnter Log Entry to View or -X to go back
set /p View=">"
if /i "%viewe%"=="-X" goto closehistory
if "!pre_val%view%!"=="" goto mainmenu
set ViewVal=!pre_val%view%!
rem go to view area with stuff pre-set
echo Not Coded yet.
pause
goto mainmenu

:closehistory
mode con:cols=97 lines=44
goto mainmenu

:setgridsquare
set oldtcall=%tcall%
set tcall=%callsign%
call :callsignlookup
set gridsquare=%tsquare%
echo  Please enter your gridsquare or press enter for %tsquare%:
set /p gridsquare=">"
call :savesettings
goto clear

:setop
echo  Enter name of this station's operator:
set /p op=">"
call :savesettings
goto mainmenu


:savelog
if "%flrig%"=="1" (
    if "%flrigfreq%"=="1" (
        for /f "tokens=*" %%A in ('%rigctlcmd% get_freq') do (set rigfreq=%%~A)
        for /f %%n in ('cscript //nologo ..\eval.vbs "!rigfreq!/1000000"') do (set res=%%n)
        if not "!freq!"=="!res!" (
            echo [91mFrequency on radio [!res!] is different from set frequency: !freq![0m
            echo [90mRemember, pressing [ESC] to clear the entry refreshes radio data.[0m
            echo Update frequency to !res!?
            choice
            if %errorlevel%==1 set freq=!res!
        )
    )
)
if "%tcall%"=="" (
    echo  [91mNo Callsign Entered[0m
    pause
    goto mainmenu
)
if "%ctd%"=="" set ctd=NONE
if "%power%"=="" set power=NONE
if "%note%"=="" set note=NONE
if "%tstate%"=="" set tstate=NONE
if "%lDate%"=="" call :setdatetime
if "%lTime%"=="" call :setdatetime
if "!freq!"=="" (
    echo  [91mNo Frequency Entered[0m
    pause
    goto mainmenu
)
if "%rstr%"=="" set rstr=%rstd%
if "%rsts%"=="" set rsts=%rstd%
rem CTN,Callsign,DATE,TIME,Band,Freq,Mode,RSTs,RSTr,Operator,Satellite,Serial,Note,rig,license,class,power
if not exist "..\Ent.Count" (
    echo 1 >"..\Ent.Count"
)
set /p EntryNum=<"..\Ent.Count"
set /a EntryNum=%EntryNum: =%+1
echo %note%
pause
(echo %EntryNum%,%tcall%,%lDATE%,%lTIME%,%band%,!freq!,%mode%,%RSTs%,%RSTr%,%top%,%satlog%,%tserial%,%note%,%rig%,%tstate%,%tclass%,%power%,%tcountry%,%TST%,)>>"%LogFile%"
(echo %EntryNum%)>"..\Ent.Count"
goto clear


:debug
echo.[7m
set | more
pause
echo.[0m
goto mainmenu

:clear
set tcall=
set top=
set RSTs=%RSTD%
set RSTr=%RSTD%
set qth=
set newqth=
set qthmsg=
set ctd=
set note=
set tsquare=
set tserial=NONE
set tstate=NONE
set tclass=NONE
if "%flrig%"=="1" (
    if "%flrigfreq%"=="1" (
        for /f "tokens=*" %%A in ('%rigctlcmd% get_freq') do (set rigfreq=%%~A)
        for /f %%n in ('cscript //nologo ..\eval.vbs "!rigfreq!/1000000"') do (set res=%%n)
        set freq=!res!
    )
    if "%flrigmode%"=="1" (
        set num=0
        for /f "tokens=*" %%A in ('%rigctlcmd% get_mode') do (
            set /a num+=1
            if !num!==1 set mode=%%~A
        )
    )
    if "%FLRigWatts%"=="1" (
        for /f "Tokens=*" %%A in ('%rigctlcmd% get_level RFPOWER') do (set rigpow=%%~A)
        for /f %%n in ('cscript //nologo ..\eval.vbs "!rigpow!*!rigmulti!"') do (set power=%%n)
    )
)
call :setdatetime
goto mainmenu

:note
echo  Enter note (Alphanumeric, space, @$*. Only):
set /p note=" >"
set "note=%note:,=%"
set "note=%note:"=%"
goto mainmenu

:ctd
cls
echo [92mContact: %tcall% - %ldate% %ltime%
echo [90m---------------------------------
echo [96mContest Data[0m
echo 1] Class:  %tclass%
echo 2] State:  %tstate%
echo 3] Serial: %tserial%
choice /c 123X
if %errorlevel%==1 (
    echo Enter Class [i.e. 2A]:
    echo [90mPress Enter to Cancel. Enter NONE to clear.[0m
    set /p tclass=">"
    goto ctd
)
if %errorlevel%==2 (
    echo Enter State [i.e. MA]:
    echo [90mPress Enter to Cancel. Enter NONE to clear.[0m
    set /p tstate=">"
    goto ctd
)
if %errorlevel%==3 (
    echo Enter Serial [i.e. 59001]:
    echo [90mPress Enter to Cancel. Enter NONE to clear.[0m
    set /p tserial=">"
    goto ctd
)
set ctd=
if not "%tclass%"=="NONE" (
    set "ctd=CLASS: %tclass%"
    if not "%tstate%"=="NONE" (
        set "ctd=!ctd! # "
    ) ELSE (
        if not "%tserial%"=="NONE" (
           set "ctd=!ctd! # "
        )
    )
)
if not "%tstate%"=="NONE" (
    set "ctd=%ctd%STATE: %tstate%"
    if not "%tserial%"=="NONE" (
        set "ctd=!ctd! # "
    )
)
if not "%tserial%"=="NONE" (
    set "ctd=%ctd%SERIAL: %tserial%"
)
goto mainmenu




set /p ctd=" >"
set "ctd=%ctd:,=%"
set "ctd=%ctd:"=%"
goto mainmenu

:name
echo  Enter Name of Other Station Operator:
set /p top=" >"
goto mainmenu

:qth
cls
echo.
echo [96mQTH Editor[0m
echo.
echo QTH: %qthmsg%
if "!newqth!"=="TRUE" (
    echo [92;4mNEW COUNTRY OR STATE![0m
)
echo.
echo 1] Country: %tcountry%
echo 2] State: %TST%
echo 3] City: %tcity%
echo 4] Street: %tstreet%
echo 5] Grid Square: %tsquare%
echo [92mA] Auto
echo [91mC] Clear[90m
echo X] Back[0m
echo.
choice /c 12345ACX
echo.
if %errorlevel%==1 (
    echo Enter Other Station's Country [-x cancel]:
    set /p Ntc=">"
    if /i "!ntc!"=="-x" goto qth
    set tcountry=!ntc!
)
if %errorlevel%==2 (
    echo Enter Other Station's State [-x cancel]:
    set /p ntst=">"
    if /i "!ntst!"=="-x" goto qth
    set TST=!ntst!
)
if %errorlevel%==3 (
    echo Enter Other Station's City [-x cancel]:
    set /p ntct=">"
    if /i "!ntct!"=="-x" goto qth
    set tcity=!ntct! 
)
if %errorlevel%==4 (
    echo Enter Other Station's Street [-x cancel]:
    set /p nts=">"
    if /i "!nts!"=="-x" goto qth
    set tstreet=!nts!
)
if %errorlevel%==5 (
    echo Enter Other Station's Grid Square [-x cancel]:
    set /p ntg=">"
    if /i "!ntg!"=="-x" goto qth
    set tsquare=!ntg!
)
if %errorlevel%==6 (
    set preqthtcall=%tcall%
    call :callsignlookup
    set tcall=!preqthtcall!
    goto qth 
)
if %errorlevel%==7 (
    set tst=
    set tcity=
    set tsquare=
    set tstreet=
    set tcountry=
    set qthmsg=
    set newqth=
    goto qth
)
if %errorlevel%==8 goto mainmenu
set "QTH=%TStreet%%Tcity%%TST% %tCountry%"
set newqth=FALSE
set tcountrycode=
set tstatecode=
if "%countrysearch%"=="TRUE" (
    if exist "*.hamlog" (
        for /f "delims=" %%A in ('%searchlogcommand%') do (
            find /i ",%TCountry%," "%%~A" >nul 2>nul
            if not !errorlevel!==0 (
                set tcountrycode=[93;4m
                set newqth=TRUE
            )
        )
    )
)
if "%statesearch%"=="TRUE" (
    if exist "*.hamlog" (
        for /f "delims=" %%A in ('%searchlogcommand%') do (
            find /i ",%TST%," "%%~A" >nul 2>nul
            if not !errorlevel!==0 (
                set tstatecode=[93;4m
                set newqth=TRUE
            )
        )
    )
)
set "qthmsg=%TStreet%%Tcity%%tstatecode%%TST%[0m %tcountrycode%%tCountry%[0m"
goto qth

:SearchSettings
cls
echo [96mSEARCH SETTINGS
echo.
echo [0m1] Previous Contact Search: [92m%contactsearch%
echo [0m2] Previous Country Search: [92m%countrysearch%
echo [0m3] Previous State Search (USA): [92m%statesearch%
echo [96mS[0m] Log Search Methood: [96m%logsearchstat%
echo [90mX] Exit[0m
echo.
choice /c 123sx
if %errorlevel%==5 goto moresettings
if %errorlevel%==1 (
   if "%contactSearch%"=="TRUE" (
        set contactSearch=FALSE
        goto SearchSettings
    ) ELSE (
        set contactSearch=TRUE
        goto SearchSettings
    )    
)
if %errorlevel%==2 (
    if "%CountrySearch%"=="TRUE" (
        set CountrySearch=FALSE
        goto SearchSettings
    ) ELSE (
        set CountrySearch=TRUE
        goto SearchSettings
    )
)
if %errorlevel%==3 (
    if "%StateSearch%"=="TRUE" (
        set StateSearch=FALSE
        goto SearchSettings
    ) ELSE (
        set StateSearch=TRUE
        goto SearchSettings
    )
)
if %errorlevel%==4 (
    if "%logsearchstat%"=="Search only Current Log File" (
        set logsearchstat=Search All Logs in Log Folder
        set searchlogcommand=dir /b /s *.hamlog
    ) ELSE (
        set logsearchstat=Search only Current Log File
        set searchlogcommand=dir /b /s "%logfile:"=%"
    )
    call :savesettings
    goto searchsettings
)
goto mainmenu

:MoreSettings
cls
echo MORE SETTINGS
echo.
echo [0m1] RST Default: [92m%RSTD%
echo [0m2] Export to ADIF
echo [0m3] Current Rig: [92m%rig%
echo [0m4] Log File: [92m%logfile%
echo [0m5] Query Hamdb: [92m%query%
echo [0m6] [92mSearch Settings
echo [0m7] Windows Terminal Mode: [92m%TerminalMode%
echo [0m8] FLRig Pull Frequency on Callsign Entry: [92m%FreqOften%
echo [0m9] Pull Date and Time on Callsign Entry: [92m%datetimeoncall%
echo [0;1mR[0m] Recovery Mode [Recover Deleted Entries]
echo [90mX] Exit[0m
choice /c 123456789PRx
if %errorlevel%==1 (
    if %RSTD%==599 (
        set RSTD=59
    ) ELSE (
        set RSTD=599
    )
    goto moresettings
)
if %errorlevel%==2 goto adifexport
if %errorlevel%==3 goto rig
if %errorlevel%==4 goto logfile
if %errorlevel%==5 (
    if %query%==TRUE (
        set query=FALSE
    ) ELSE (
        set query=TRUE
    )
    goto moresettings
)
if %errorlevel%==6 goto SearchSettings
if %errorlevel%==7 (
    if "%TerminalMode%"=="TRUE" (
        set TerminalMode=FALSE
    ) ELSE (
        set TerminalMode=TRUE
    )
    call :savesettings
    goto moresettings
)
if %errorlevel%==8 (
    if "%FreqOften%"=="TRUE" (
        set FreqOften=FALSE
    ) ELSE (
        set FreqOften=TRUE
    )
    call :savesettings
    goto moresettings
)
if %errorlevel%==9 (
    if "%datetimeoncall%"=="TRUE" (
        set datetimeoncall=FALSE
    ) ELSE (
        set datetimeoncall=TRUE
    )
    call :savesettings
    goto moresettings
)

if %errorlevel%==11 goto recoverdeleted
call :savesettings
goto mainmenu

:recoverdeleted
cls
echo.
echo RECOVERY MODE
echo.
if not exist SRLOG.Log.Trashbin (
    echo Trash bin is empty.
    pause
    goto moresettings
)
type SRLOG.Log.Trashbin
echo [96mTo recover an entry, enter the unique ID and callsign (the first two values)
echo exactly how they appear in the list. For example: [4m761,W1GZ[0m
echo [90mNote: Recovered entries will remain in the recovery list.[0m
echo Enter -X to exit. Enter -E to empty the trash bin.
echo.
:recovermore
set /p recovery=">"
if /i "%recovery%"=="-x" goto moresettings
if /i "%recovery%"=="-E" (
    echo Empty trash. Are you sure?
    choice
    if %errorlevel%==2 goto recovermore
    del /f /q SRLOG.Log.Trashbin
    goto moresettings
)
for /f "tokens=1 skip=2 delims=" %%A in ('find /i "%recovery%" "SRLOG.Log.Trashbin"') do (
    echo [92mRecovering: [0m%%~A
    echo %%~A >>"%logfile:"=%"
)
goto recovermore

:poweradjust
cls
echo [92mFLRig Power Adjustment.[0m
echo.
echo Power adjustment is for if your power shows the wrong power level.
echo This is because some radios report a percentage instead of watts.
echo [90mCurrently set to multiply by:[92m !rigmulti![0m
echo.
echo 1] Multiply by 10 (For Example: Xiegu X6100)
echo 2] Multiply by 100 (For Example: IC-7300)
echo 3] Multiply by 1000
echo [0mX] Cancel
choice /c 123X
if %errorlevel%==1 set rigmulti=10
if %errorlevel%==2 set rigmulti=100
if %errorlevel%==3 set rigmulti=1000
goto flrigmenu

:logfile
cls
echo [92mCurrent Logfile is %logfile%.[96m
echo.
echo 1] Create New Logfile
echo 2] Select Existing Logfile
echo 3] Delete Current Logfile
echo [90mX] Cancel
choice /c 123x
if %errorlevel%==1 goto newlogfile
if %errorlevel%==2 goto selectlogfile
if %errorlevel%==3 goto deletelogfile

:newlogfile
cls
echo Enter new log file name (leave blank to cancel):
echo [90mNote: .hamlog extension will be added to file name[0m
echo.
set /p logfile=">"
if "%logfile%"=="%logfile:.hamlog=%" set logfile=%logfile%.hamlog
call :savesettings
goto moresettings

:selectlogfile
cls
echo Drag and Drop existing log file here:
echo.
set /p newlogfile=">"
set "newlogfile=%newlogfile:"=%"
if not exist "%newlogfile%" (
    echo File not found.
    pause
    goto logfile
)
if "%newlogfile%"=="%newlogfile:.hamlog=%" (
    echo File is not a valid SRLog .hamlog.
    pause
    goto logfile
)
echo.
echo [92mUse "%newlogfile%" as new log file?
choice
if %errorlevel%==2 goto logfile
set logfile=%newlogfile%
goto moresettings

:deletelogfile




:rig
cls
echo Select a rig/setup letter to be saved in each log entry. This tool will allow you to
echo keep track of what Radio, antenna, or other setup you get what contacts on.
echo This letter cannot be exported, and is only for personal notes.
echo.
echo Press a key 1-9. Press X to cancel.
choice /c 123456789X
if %errorlevel%==10 goto mainmenu
set rig=%errorlevel%
call :savesettings
goto MoreSettings

:date
echo  Enter UTC Date in YYYY-MM-DD format
set /p ldate=" >"
goto mainmenu

:time
echo  Enter UTC Time in HH:MM format
set /p ltime=" >"
goto mainmenu

:rsts
echo  Enter SENT RST Report [90m(Enter -G for Guide)[0m:
set /p Entry=" >"
if /i "%Entry%"=="-G" goto rstguide
set rsts=%Entry%
goto mainmenu

:rstr
echo  Enter RECEIVED RST Report [90m(Enter -G for Guide)[0m:
set /p Entry=" >"
if /i "%Entry%"=="-G" goto rstguide
set rstr=%Entry%
goto mainmenu

:rstguide
cls
echo R-S-T: Readability - Strength - Tone
echo.
echo.
echo   VALUE:  ^|         R READABILITY         ^|        S STRENGTH        ^|        TONE (CW Only)        ]
echo ----------------------------------------------------------------------------------------------------]
echo     1     ^|           Unreadable          ^|       Faint Signal       ^|     60 Cycle AC or Less      ]
echo     2     ^|        Barely Readable        ^|     Very Weak Signal     ^|  Very Rough/Harsh/Broad AC   ]
echo     3     ^|   Readable with Difficulty    ^|       Weak Signals       ^|     Rough AC - Rectified     ]
echo     4     ^| Readable with Some Straining  ^|       Fair Signals       ^|  Rough CW - Some Filtering   ]
echo     5     ^|       Perfectly Readable      ^|    Fairly Good Signal    ^| Filtered but Strong Ripples  ]
echo     6     ^|               X               ^|       Good Signals       ^| Filtered - Definite Ripples  ]
echo     7     ^|               X               ^| Moderately Strong Signal ^| Near Pure - Trace of Ripple  ]
echo     8     ^|               X               ^|      Strong Signals      ^| Near Perfect Trace of Wave   ]
echo     9     ^|               X               ^| Extremely Strong Signals ^|      Perfect CW Tone         ]
echo ====================================================================================================]
echo.
pause
goto mainmenu

:tcallw
set oldcall=%tcall%
echo  Enter Other Station's Callsign:
set /p tcall=">W"
set tcall=W%tcall%
goto starttcall

:tcallk
set oldcall=%tcall%
echo  Enter Other Station's Callsign:
set /p tcall=">K"
set tcall=K%tcall%
goto starttcall

:tcalla
set oldcall=%tcall%
echo  Enter Other Station's Callsign:
set /p tcall=">A"
set tcall=A%tcall%
goto starttcall

:tcallE
set oldcall=%tcall%
echo  Enter Other Station's Callsign:
set /p tcall=">E"
set tcall=K%tcall%
goto starttcall

:tcall
set oldcall=%tcall%
echo  Enter Other Station's Callsign (Press Enter to Keep %tcall%)
set /p tcall=">"
:starttcall
set prequerytcall=%tcall%
if /i "%tcall%"=="-x" set tcall=%oldcall%&goto mainmenu
if /i "%tcall%"=="" goto mainmenu
:canceltcall
if not %query%==TRUE (
    set top=NONE
    call :makeCaps tcall
    goto skipquery
)

call :CallsignLookup
if "%tcall%"=="NOT_FOUND" gptp NoTcallFound
:skipquery
set rstr=%RSTD%
set rsts=%RSTD%
if "%datetimeoncall%"=="TRUE" call :setdatetime
if "%FreqOften%"=="TRUE" (
    if "%flrig%"=="1" (
        if "%flrigfreq%"=="1" (
            for /f "tokens=*" %%A in ('%rigctlcmd% get_freq') do (set rigfreq=%%~A)
            for /f %%n in ('cscript //nologo ..\eval.vbs "!rigfreq!/1000000"') do (set res=%%n)
            set freq=!res!
        )
        if "%flrigmode%"=="1" (
            set num=0
            for /f "tokens=*" %%A in ('%rigctlcmd% get_mode') do (
                set /a num+=1
                if !num!==1 set mode=%%~A
            )
        )
        if "%FLRigWatts%"=="1" (
            for /f "Tokens=*" %%A in ('%rigctlcmd% get_level RFPOWER') do (set rigpow=%%~A)
            for /f %%n in ('cscript //nologo ..\eval.vbs "!rigpow!*!rigmulti!"') do (set power=%%n)
        )
    )
)

goto mainmenu

:NoTcallFound
echo  [91mCallsign %prequerytcall% not found.[0m
echo.
echo  1] Retype
echo  2] Override and Continue
echo  X] Cancel
choice /c 12X
if !errorlevel!==1 goto tcall
if !errorlevel!==2 (
    set tcall=%prequerytcall%
    goto mainmenu
)
if !errorlevel!==3 (
    set tcall=%oldcall%
    goto mainmenu
)
exit


:setdatetime
for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set %%x
call :getlength hour hlength
if %hlength%==1 set hour=0%hour%
call :getlength minute mlength
if %mlength%==1 set minute=0%minute%
call :getlength month mlength
if %mlength%==1 set month=0%month%
call :getlength day dlength
if %dlength%==1 set day=0%day%
set ldate=%Year%-%month%-%day%
set ltime=%hour%:%minute%
exit /b


:CallsignLookup
for /f "tokens=1,2 delims=/" %%A in ('echo !tcall!') do (
    set hamdbcall=%%~A
    set leftover=%%~B
)
for /f "tokens=* delims=" %%A in ('curl http://api.hamdb.org/v1/!hamdbcall!/csv/SRCOM -s') do (set "hamdb=%%~A")
set "hamdb=%hamdb:,=,$%"
for /f "tokens=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18* delims=$" %%A in ('echo %hamdb%') do (
    if "%%~A"=="NOT_FOUND " goto :NoTcallFound
    set tcallresult=%%~A
    set TLicense=%%~B
    set TExpire=%%~C
    set TSquare=%%~D
    set TLat=%%~E
    set TLong=%%~F
    set tstat=%%~G
    set TFName=%%~H
    set TMName= %%~I
    set TLName=%%~J
    set TStreet=%%~L
    set TCity=%%~M
    set TST=%%~N
    set TZIP=%%~O
    set TCountry=%%~P
)
set tcallresult=%tcallresult:$=%
set TLicense=%TLicense:$=%
set TExpire=%TExpire:$=%
set TSquare=%TSquare:$=%
set set TLat=%TLat:$=%
set set TLong=%TLong:$=%
set set tstat=%tstat:$=%
set TFName=%TFName:$=%
set TMName=%TMName:$=%
set TLName=%TLName:$=%
set TStreet=%TStreet:$=%
set TCity=%TCity:$=%
set TST=%TST:$=%
set TST=%TST: =%
set TZIP=%TZIP:$=%
set TCountry=%TCountry:$=%
set "top=%TFName: =%%TMName%%TLName%"
set "top=%top:~,-1%"
set "top=%top:  = %"
set "QTH=%TStreet%%Tcity%%TST% %tCountry%"
rem codehere
set tcountrycode=
set tstatecode=
if "%countrysearch%"=="TRUE" (
    if exist "*.hamlog" (
        for /f "delims=" %%A in ('%searchlogcommand%') do (
            find /i ",%TCountry%," "%%~A" >nul 2>nul
            if not !errorlevel!==0 (
                set tcountrycode=[93;4m
            )
        )
    )
)
if "%statesearch%"=="TRUE" (
    if exist "*.hamlog" (
        for /f "delims=" %%A in ('%searchlogcommand%') do (
            find /i ",%TST%," "%%~A" >nul 2>nul
            if not !errorlevel!==0 (
                set tstatecode=[93;4m
            )
        )
    )
)
set "qthmsg=%TStreet%%Tcity%%tstatecode%%TST%[0m %tcountrycode%%tCountry%[0m"
set "tsquare=%tsquare: =%"
if "!leftover!"=="" (
    set tcall=%tcallresult: =%
) ELSE (
    set tcall=%tcallresult: =%/!leftover!
)
exit /b

:license
echo Choose License
echo 1] Novice
echo 2] Technician
echo 3] General
echo 4] Advanced
echo 5] Extra
choice /c 12345
if %errorlevel%==1 set license=N
if %errorlevel%==2 set license=T
if %errorlevel%==3 set license=G
if %errorlevel%==4 set license=A
if %errorlevel%==5 set license=E
call :savesettings
goto mainmenu

:freqmode
echo Enter Frequency in MHz (ie: 14.225), F for FLRig, or press Enter for %freq%:
set /p freq=">"
if /i "%freq%"=="f" (
        for /f "tokens=*" %%A in ('%rigctlcmd% get_freq') do (set rigfreq=%%~A)
        for /f %%n in ('cscript //nologo ..\eval.vbs "!rigfreq!/1000000"') do (set res=%%n)
        set freq=!res!
        for /f "tokens=*" %%A in ('%rigctlcmd% get_mode') do (
            set /a num+=1
            if !num!==1 set mode=%%~A
        )
        call :savesettings
        goto mainmenu
    )
echo Enter Mode or press Enter for %mode%:
set /p mode=">"
for /f "tokens=1,2,3,4 delims=." %%A in ('echo %freq%') do (
    set MHz=%%~A
    set KHz=%%~B%%~C%%~D
)  
call :getlength KHz fleng
if %fleng% GTR 3 (
    set KHz=%KHz:~0,4%
    goto exitzeroloop
)
:zeroloop
if %fleng% GEQ 3 goto exitzeroloop
set KHz=%KHz%0
set /a fleng+=1
goto zeroloop
:exitzeroloop
set freq=%MHz%.%KHz%
rem call :modecolor
call :savesettings
goto mainmenu

:makeCaps
for %%a in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I"
        "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R"
        "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "ä=Ä"
        "ö=Ö" "ü=Ü") do (
call set %~1=%%%~1:%%~a%%
)
EXIT /b

:rangeband
if "%freq%"=="" (
    echo  Enter a fequency to detect band
    exit /b
)
for /f "tokens=1,2 delims=." %%A in ('echo %freq%') do (
    set freqlarge=%%~A
)
if "%freqlarge%"=="1" (
    set band=160m
    if "%license%"=="N" set bandrange=NONE
    if "%license%"=="T" set bandrange=NONE
    if "%license%"=="G" set bandrange=1.8 MHz - 2.0 MHz
    if "%license%"=="A" set bandrange=1.8 MHz - 2.0 MHz
    if "%license%"=="E" set bandrange=1.8 MHz - 2.0 MHz
)
if "%freqlarge%"=="3"  (
    set band=80m
    if "%license%"=="N" set bandrange=NONE [CW ONLY]
    if "%license%"=="T" set bandrange=NONE [CW ONLY]
    if "%license%"=="G" set bandrange=3.8 MHz - 4.0 MHz
    if "%license%"=="A" set bandrange=3.7 MHz - 4.0 MHz
    if "%license%"=="E" set bandrange=3.6 MHz - 4.0 MHz
)
if "%freqlarge%"=="5" (
    set band=60m
    if "%license%"=="N" set bandrange=NONE
    if "%license%"=="T" set bandrange=NONE
    if "%license%"=="G" set bandrange=5.3305, 5.3465, 5.3570, 5.3715, 5.4035 MHz
    if "%license%"=="A" set bandrange=5.3305, 5.3465, 5.3570, 5.3715, 5.4035 MHz
    if "%license%"=="E" set bandrange=5.3305, 5.3465, 5.3570, 5.3715, 5.4035 MHz
)
if "%freqlarge%"=="7" (
    set band=40m
    if "%license%"=="N" set bandrange=NONE [CW ONLY]
    if "%license%"=="T" set bandrange=NONE [CW ONLY]
    if "%license%"=="G" set bandrange=7.175 MHz - 7.300 MHz
    if "%license%"=="A" set bandrange=7.125 MHz - 7.300 MHz
    if "%license%"=="E" set bandrange=7.125 MHz - 7.300 MHz
)
if "%freqlarge%"=="10" (
    set band=30m
    set bandrange=NONE
)
if "%freqlarge%"=="14" (
    set band=20m
    if "%license%"=="N" set bandrange=NONE
    if "%license%"=="T" set bandrange=NONE
    if "%license%"=="G" set bandrange=14.225 MHz - 14.350 MHz
    if "%license%"=="A" set bandrange=14.175 MHz - 14.350 MHz
    if "%license%"=="E" set bandrange=14.150 MHz - 14.350 MHz
)
if "%freqlarge%"=="18" (
    set band=17m
    if "%license%"=="N" set bandrange=NONE
    if "%license%"=="T" set bandrange=NONE
    if "%license%"=="G" set bandrange=18.110 MHz - 18.168 MHz
    if "%license%"=="A" set bandrange=18.110 MHz - 18.168 MHz
    if "%license%"=="E" set bandrange=18.110 MHz - 18.168 MHz
)
if "%freqlarge%"=="21" (
    set band=15m
    if "%license%"=="N" set bandrange=NONE [CW ONLY]
    if "%license%"=="T" set bandrange=NONE [CW ONLY]
    if "%license%"=="G" set bandrange=21.275 MHz - 21.450 MHz
    if "%license%"=="A" set bandrange=21.225 MHz - 21.450 MHz
    if "%license%"=="E" set bandrange=21.200 MHz - 21.450 MHz
)
if "%freqlarge%"=="24" (
    set band=12m
    if "%license%"=="N" set bandrange=NONE
    if "%license%"=="T" set bandrange=NONE
    if "%license%"=="G" set bandrange=24.93 MHz - 24.99 MHz
    if "%license%"=="A" set bandrange=24.93 MHz - 24.99 MHz
    if "%license%"=="E" set bandrange=24.93 MHz - 24.99 MHz
)
if "%freqlarge%"=="28"  (
    set band=10m
    if "%license%"=="N" set bandrange=28.3 MHz - 28.5 MHz
    if "%license%"=="T" set bandrange=28.3 MHz - 28.5 MHz
    if "%license%"=="G" set bandrange=28.3 MHz - 29.7 MHz
    if "%license%"=="A" set bandrange=28.3 MHz - 29.7 MHz
    if "%license%"=="E" set bandrange=28.3 MHz - 29.7 MHz
)
if "%freqlarge%"=="29" (
    set band=10m
    if "%license%"=="N" set bandrange=28.3 MHz - 28.5 MHz
    if "%license%"=="T" set bandrange=28.3 MHz - 28.5 MHz
    if "%license%"=="G" set bandrange=28.3 MHz - 29.7 MHz
    if "%license%"=="A" set bandrange=28.3 MHz - 29.7 MHz
    if "%license%"=="E" set bandrange=28.3 MHz - 29.7 MHz
)
if "%freqlarge%"=="50" (
    set band=6m
    if "%license%"=="N" set bandrange=NONE
    if "%license%"=="T" set bandrange=50 MHz - 54 MHz
    if "%license%"=="G" set bandrange=50 MHz - 54 MHz
    if "%license%"=="A" set bandrange=50 MHz - 54 MHz
    if "%license%"=="E" set bandrange=50 MHz - 54 MHz
)
if "%freqlarge%"=="51" (
    set band=6m
    if "%license%"=="N" set bandrange=NONE
    if "%license%"=="T" set bandrange=50 MHz - 54 MHz
    if "%license%"=="G" set bandrange=50 MHz - 54 MHz
    if "%license%"=="A" set bandrange=50 MHz - 54 MHz
    if "%license%"=="E" set bandrange=50 MHz - 54 MHz
)
if "%freqlarge%"=="52" (
    set band=6m
    if "%license%"=="N" set bandrange=NONE
    if "%license%"=="T" set bandrange=50 MHz - 54 MHz
    if "%license%"=="G" set bandrange=50 MHz - 54 MHz
    if "%license%"=="A" set bandrange=50 MHz - 54 MHz
    if "%license%"=="E" set bandrange=50 MHz - 54 MHz
)
if "%freqlarge%"=="53" (
    set band=6m
    if "%license%"=="N" set bandrange=NONE
    if "%license%"=="T" set bandrange=50 MHz - 54 MHz
    if "%license%"=="G" set bandrange=50 MHz - 54 MHz
    if "%license%"=="A" set bandrange=50 MHz - 54 MHz
    if "%license%"=="E" set bandrange=50 MHz - 54 MHz
)
if %freqlarge% GEQ 144 (
    if %freqlarge% LSS 148 (
        set band=2m
        if "%license%"=="N" set bandrange=NONE
        if "%license%"=="T" set bandrange=144 MHz - 148 MHz
        if "%license%"=="G" set bandrange=144 MHz - 148 MHz
        if "%license%"=="A" set bandrange=144 MHz - 148 MHz
        if "%license%"=="E" set bandrange=144 MHz - 148 MHz
    )
)
if %freqlarge% GEQ 222 (
    if %freqlarge% LSS 225 (
        set band=1.25m
        set bandrange=222 MHz - 225 MHz
    )
)
if %freqlarge% GEQ 420 (
    if %freqlarge% LSS 450 (
        set band=70cm
        if "%license%"=="N" set bandrange=NONE
        if "%license%"=="T" set bandrange=420 MHz - 450 MHz
        if "%license%"=="G" set bandrange=420 MHz - 450 MHz
        if "%license%"=="A" set bandrange=420 MHz - 450 MHz
        if "%license%"=="E" set bandrange=420 MHz - 450 MHz
    )
 )

if %freqlarge% GEQ 902 (
    if %freqlarge% LSS 928 (
        set band=33cm
        if "%license%"=="N" set bandrange=NONE
        if "%license%"=="T" set bandrange=902 MHz - 928 MHz
        if "%license%"=="G" set bandrange=902 MHz - 928 MHz
        if "%license%"=="A" set bandrange=902 MHz - 928 MHz
        if "%license%"=="E" set bandrange=902 MHz - 928 MHz
    )
)
if %freqlarge% GEQ 1240 (
    if %freqlarge% LSS 1295 (
        set band=23cm
        if "%license%"=="N" set bandrange=1270 MHz - 1295 MHz
        if "%license%"=="T" set bandrange=1240 MHz - 1300 MHz
        if "%license%"=="G" set bandrange=240 MHz - 1300 MHz
        if "%license%"=="A" set bandrange=240 MHz - 1300 MHz
        if "%license%"=="E" set bandrange=240 MHz - 1300 MHz
    )
)
echo %bandrange% | find /i "NONE" >nul 2>nul
if %errorlevel%==0 (
    echo  Your voice Range in the %band% band [%license%]: [91m%bandrange%[0m
) ELSE (
    echo  Your voice Range in the %band% band [%license%]: %bandrange%
)
exit /b

13


:showrecentlog
set RecentGTR=10
set TerminalGTR=8
if "%TerminalMode%"=="TRUE" set RecentGTR=!TerminalGTR!
set logskip=0
if not exist "%logfile%" (
    echo [90mNo Contacts in this logbook yet[0m
    exit /b
)
for /f "tokens=1,2 delims=:" %%A in ('find /v /c "" "%logfile%"') do (set contacts=%%~B)
set contacts=!contacts: =!
if !contacts! GTR !RecentGTR! (
    set /a logskip=!contacts!-!RecentGTR!
)
if !contacts! GTR !RecentGTR! (
    echo [92m                                    !RecentGTR! Most Recent Contacts [+!logskip! not shown]
    echo [90m      CALLSIGN  UTC  DATE  TIME    BAND FREQUENCY    MODE    S   R         NAME         RIG SPEC
    for /f "skip=%logskip% usebackq tokens=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18 delims=," %%A in ("%Logfile: =%") do (
        set displaycallsign=             %%~B
        set disBand=      %%~E
        set disFreq=        %%~F
        set disMode=        %%~G
        set disRSTs=   %%~H
        set disRSTr=   %%~I
        set name=%%~J
        set disName=                 !name:~0,17!
        if "%%~K"=="Y" (
            set disSat=S
        ) ELSE (
            set disSat=
        )
        set disContest=
        if "%%~L"=="NONE" (
            set disContest=
        ) ELSE (
            set disContest=C
        )
        if "%%~O"=="NONE" (
            if not "!disContest!"=="C" set disContest=
        ) ELSE (
            set disContest=C
        )
        if "%%~P"=="NONE" (
            if not "!disContest!"=="C" set disContest=
        ) ELSE (
            set disContest=C
        )
        if "%%~M"=="NONE" (
            set disNote=
        ) ELSE (
            set disContest=N
        )
        echo  [92m!displaycallsign:~-13![0m %%~C %%~D ^|!disband:~-6! !disFreq:~-8! !disMode:~-8! ^|!disRSTs:~-3! !disRSTr:~-3! ^| [93m!disName:~-17![0m ^| %%~N !disSat!!disContest!!disNote![0m
    )
) ELSE (
    echo [92m                                     Most Recent Contacts
    echo [90m      CALLSIGN  UTC  DATE  TIME    BAND FREQUENCY    MODE    S   R         NAME         RIG SPEC
    for /f "usebackq tokens=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18 delims=," %%A in ("%Logfile: =%") do (
        set displaycallsign=             %%~B
        set disBand=      %%~E
        set disFreq=        %%~F
        set disMode=        %%~G
        set disRSTs=   %%~H
        set disRSTr=   %%~I
        set name=%%~J
        set disName=                 !name:~0,17!
        if "%%~K"=="Y" (
            set disSat=S
        ) ELSE (
            set disSat=
        )
        set disContest=
        if "%%~L"=="NONE" (
            set disContest=
        ) ELSE (
            set disContest=C
        )
        if "%%~O"=="NONE" (
            if not "!disContest!"=="C" set disContest=
        ) ELSE (
            set disContest=C
        )
        if "%%~P"=="NONE" (
            if not "!disContest!"=="C" set disContest=
        ) ELSE (
            set disContest=C
        )
        if "%%~M"=="NONE" (
            set disNote=
        ) ELSE (
            set disNote=N
        )
        echo  [92m!displaycallsign:~-13![0m %%~C %%~D ^|!disband:~-6! !disFreq:~-8! !disMode:~-8! ^|!disRSTs:~-3! !disRSTr:~-3! ^| [93m!disName:~-17![0m ^| [93m%%~N  [96m!disSat!!disContest!!disNote![0m
    )
)
exit /b




:savesettings
if exist Logs\ (
    set settingslocation=srlogSettings.cmd
) ELSE (
    set settingslocation=..\srlogSettings.cmd
)
echo @echo off >%settingslocation%
echo set "RSTD=!RSTD!">>%settingslocation%
echo set "Callsign=!callsign!">>%settingslocation%
echo set "gridsquare=!gridsquare!">>%settingslocation%
echo set "DefaultMode=!DefaultMode!">>%settingslocation%
echo set "LogFile=!LogFile!">>%settingslocation%
echo set "op=!op!">>%settingslocation%
echo set "freq=!freq!">>%settingslocation%
echo set "power=!power!">>%settingslocation%
echo set "license=!license!">>%settingslocation%
echo set "mode=!mode!">>%settingslocation%
echo set "Sattelite=!Satellite!">>%settingslocation%
echo set "satlog=!satlog!">>%settingslocation%
echo set "rig=!rig!">>%settingslocation%
echo set "searchlogcommand=!searchlogcommand!">>%settingslocation%
echo set "logsearchstat=!logsearchstat!">>%settingslocation%
echo set "query=%query%">>%settingslocation%
echo set "flrig=%flrig%">>%settingslocation%
echo set "FLRigFreq=!FLRigFreq!">>%settingslocation%
echo set "FLRigMode=!FLRigMode!">>%settingslocation%
echo set "FLRigWatts=!FLRigWatts!">>%settingslocation%
echo set "TerminalMode=!TerminalMode!">>%settingslocation%
echo set "FreqOften=!FreqOften!">>%settingslocation%
echo set "tcall=!tcall!">>%settingslocation%
echo set "datetimeoncall=!datetimeoncall!">>%settingslocation%
echo set "rigmulti=!rigmulti!">>%settingslocation%
echo set "countrysearch=!countrysearch!">>%settingslocation%
echo set "statesearch=!statesearch!">>%settingslocation%
echo set "contactsearch=!contactsearch!">>%settingslocation%
echo set "flriglaunch=!flriglaunch!">>%settingslocation%
echo set "flrigpath=!flrigpath!">>%settingslocation%
exit /b

:end
cd ..
if "%startedflrig%"=="TRUE" (
    taskkill /im "flrig.exe" >nul 2>nul
    taskkill /im "flrig.exe" >nul 2>nul
)
exit

:getlength
rem call :getlength VarofString ReturnVar
setlocal disableDelayedExpansion
set len=0
if defined %~1 for /f "delims=:" %%N in (
  '"(cmd /v:on /c echo(!%~1!&echo()|findstr /o ^^"'
) do set /a "len=%%N-4"
endlocal & if "%~2" neq "" (set %~2=%len%) else echo %len%
exit /b

:getlen2
rem call :getlength VarofString ReturnVar
setlocal disableDelayedExpansion
set len=0
if defined %~1 for /f "delims=:" %%N in (
  '"(cmd /v:on /c echo(!%~1!&echo()|findstr /o ^^"'
) do set /a "len=%%N-3"
endlocal & if "%~2" neq "" (set %~2=%len%) else echo %len%
exit /b