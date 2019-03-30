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
    $tsenv.Value('StartTime') = Get-Date
}
if ($StartEnd -eq 'End') {
    $tsenv.Value('EndTime') = Get-Date
}