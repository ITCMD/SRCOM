On Error Resume Next
Set fs = CreateObject("Scripting.Filesystemobject")
If fs.FileExists("Busy.Lockout") Then
fs.DeleteFile( "Busy.Lockout" )
end if