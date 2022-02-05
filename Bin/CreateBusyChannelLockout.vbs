Dim FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set OutPutFile = FSO.OpenTextFile("G:\Github\Simple-Radio-COM\Bin\Busy.Lockout" ,2 , True)
OutPutFile.WriteLine("True")
Set FSO= Nothing