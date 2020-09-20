<#
.SYNOPSIS
Sets Start or End times, Gets some PC data before imaging or upgrading

.DESCRIPTION
This script gets the Start and End time of a task sequence to pass into Slack/Teams notifications. There's addtional Task Sequence variables, for 
pulling the operating system build and/or usename of the computer primarily prior to in-place upgrades. 

.PARAMETER StartEnd
Specfies if this is the start or end of the task sequence. It will use these values in a New-TimeSpan in the main scripts to determine upgrading/imaging time.

.EXAMPLE
Get-TSDuration -StartEnd Start
Sets the start time of the task sequence.

.NOTES
Created by John Kuntz
2017-12-01 Initial script build
2019-06-18 Added a test for connectivity to World Clock Api. Added the current build information into the TS Variable "OSBuildVersion"
2019-07-11 Worldclockapi not working, so the traditional Get-Date is used and converted to UTC
2019-07-22 Added .ToString('u') to the Get-Date commands to force a standard formatting between cultures. 
2020-09-19 Adopted script used by internal Teams messages. Switched to using Universal Time, added more information for in-place upgrades.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Start', 'End')]
    [string]$StartEnd = 'Start'
)

# Set New ComObject
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment

## Set the Task Sequence Variable based on the parameter passed.

if ($StartEnd -eq 'Start') {
    # Start Time Variable
    
    $tsenv.Value('StartTime') = (Get-Date).ToUniversalTime().ToString('u')
    Write-Output "Task Sequence Start Time is $($tsenv.Value('StartTime'))"

    # Gets Logged In User for In-Place Upgrade Reporting
    $tsenv.Value('XLoggedInUser') = (Get-CimInstance –ClassName Win32_ComputerSystem | Select-Object UserName -ErrorAction SilentlyContinue).Username 

    # If the OS is Windows 10, set the OSBuildVersion to Windows 10 + Build Version
    if (((Get-CimInstance Win32_OperatingSystem).Caption) -like "*10*") {
        $tsenv.Value('OSBuildVersion') = "Windows 10 $((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name 'ReleaseId').ReleaseId)"
    }
    else {
        # If the OS is not Windows 10, set the OSBuildVersion to the operating system caption
        $tsenv.Value('OSBuildVersion') = (Get-CimInstance Win32_OperatingSystem).Caption
    }
}
if ($StartEnd -eq 'End') {
    # End Time Variable
    
    $tsenv.Value('EndTime') = (Get-Date).ToUniversalTime().ToString('u')
    Write-Output "Task Sequence End Time is $($tsenv.Value('EndTime'))"
}