Set objShell = CreateObject("WScript.Shell")
strPath = "Bin\Simple-Radio-COM.bat"
' Launch the batch file with conhost.exe
objShell.Run "conhost.exe cmd.exe /c """ & strPath & """", 1, False