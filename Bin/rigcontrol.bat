@echo off
cls
echo Rig Control is still currently in development.
echo Sorry for any inconvenience.
pause
exit /b
:top
call settings.cmd
call "hamlib\bin\rigctl.exe"
set D_Model=Rig ID:%model%                               
set D_Model=%D_Model:~0,31%
echo {=======================================================================================}
echo [/  %D_Model%                                %RXTX%       \^|/                     {%PBTN%}  ]
echo [                                                        ^|            _____             ]
echo [         %Mode%                                         ^|         .-'     `-.          ]
echo [                                                        ^|       .'           `.        ]
echo [         VFO A   %FrequencyA%                           ^|      /               .       ]
echo [         VFO B   %FrequencyB%                           ^|     ;                 `      ]
echo [                                                        ^|     ^|                 ^|      ]
echo [         %SMeterScale%                %shift%  %CTCSS%  ^|     ;                 ;      ]
echo [         [90m123456789+[0m                          ^|      \               /       ]          
echo [         %Split%   RIT:%RIT%   XIT:%XIT%                ^|       `;           .'        ] 
echo [                                                        ^|         \-._____.-'          ]         
echo [   Power:   %PowerScale%                                ^|                              ]
echo [\______________________________________________________/^|\____________________________/]
echo {=======================================================================================}
pause
goto top

    
echo off
setlocal
set "spaces=                                           "
set "timestamp=01/08/2013 14:30"
set "machineName=PC-Name"
set "message=Message goes here"
set "line=%timestamp% - %machineName%%spaces%"
set "line=%line:~0,43%- %message%
echo %line%                                        

:getDataUpdate
rem https://www.mankier.com/1/rigctl
set num=0
for /f "tokens=1 delims=" %%A in ('call hamlib\Bin\rigctl.exe --model=%model% get_mode get_vfo get_freq get_split_vfo get_rptr_shift get_rptr_offs get_ctcss_tone get_ctcss_sql get_ts get_level 'AF' get_level 'STRENGTH') do (
    set /a num+=1
    set Value!num!=%%~A
)
rem apply to friendly variables
set mode=%value1%

