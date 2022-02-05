$host.UI.RawUI.WindowTitle = "Simple Radio COM Ps1 Serial Interface"

$comp = $args[0]
$timeoutvar = $args[1]
#$comp = "com5"
$port = new-object system.io.ports.serialport $comp
Write-Output "Opening Connection to COM device over port $comp. Timeout is $timeoutvar."
$port.open()

while($true){
    Write-Output "Waiting for Transmission Signal"
    while (!(Test-Path ".\Transmit")) { Start-Sleep 1 }
    Write-Output "Transmitting"
    $port.RtsEnable = "True"
    $timeout = New-TimeSpan -Seconds $timeoutvar
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while (Test-Path ".\Transmit") {
        Start-Sleep 1
        if ($stopwatch.elapsed -gt $timeout) {
            Write-Output "Timed Out at $timeoutvar seconds"
            Remove-Item '.\Transmit'
        } 
    }
    $stopwatch.stop()
    $port.RtsEnable = ""
    Write-Output "Stopped."
}
