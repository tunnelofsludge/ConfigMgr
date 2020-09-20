[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Start', 'End')]
    [string]$StartEnd = 'Start'
)

# Set New ComObject
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment

# Set the Task Sequence Variable based on the parameter passed.
if ($StartEnd -eq 'Start') {
    $tsenv.Value('StartTime') = (get-date).ToUniversalTime()
    #Gets Logged In User for In-Place Upgrade Reporting
    $tsenv.Value('XLoggedInUser') = (Get-CimInstance –ClassName Win32_ComputerSystem | Select-Object UserName -ErrorAction SilentlyContinue).Username 
}
if ($StartEnd -eq 'End') {
    $tsenv.Value('EndTime') = (get-date).ToUniversalTime()
}
