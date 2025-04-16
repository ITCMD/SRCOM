param (
    [switch]$s
)

function Get-ComPortsWithDescriptions {
    $comPorts = @{}
    $currentPorts = [System.IO.Ports.SerialPort]::GetPortNames()
    if ($currentPorts.Count -gt 0) {
        $wmiPorts = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match '^(.*\((COM\d+)\))$' }
        foreach ($port in $wmiPorts) {
            if ($port.Name -match '^(.*\((COM\d+)\))$') {
                $name = $matches[2]
                $description = $matches[1]
                $comPorts[$name] = $description
            }
        }
    }
    return $comPorts
}

# Run the function
$comPorts = Get-ComPortsWithDescriptions

# Display the results
if ($comPorts.Count -gt 0) {
    if ($s) {
        # Only output port names
        foreach ($port in $comPorts.Keys) {
            Write-Host "$port"
        }
    } else {
        # Output port names with descriptions
        foreach ($port in $comPorts.Keys) {
            Write-Host "$port : $($comPorts[$port])"
        }
    }
} else {
    Write-Host "No COM ports found."
}