$path = $args[0]
$shell = New-Object -COMObject Shell.Application
$folder = Split-Path $path
$file = Split-Path $path -Leaf
$shellfolder = $shell.Namespace($folder)
$shellfile = $shellfolder.ParseName($file)

write-host $shellfolder.GetDetailsOf($shellfile, 27); 