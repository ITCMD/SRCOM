On Error Resume Next
Dim FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set OutPutFile = FSO.OpenTextFile("Busy.Lockout" ,2 , True)
OutPutFile.WriteLine("True")
Set FSO= Nothing