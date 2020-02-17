<#
.SYNOPSIS
Gets patch compliance on clients

.DESCRIPTION
This script checks the date of the last hotfix installed. If the last hotfix installed date is greater than 
the desired threshold ($lastpatchdays) it returns $false for non-compliance. If there is a hotfix installed
before the threshold, the script checks to see when the computer was last rebooted. If the last hotfix install date
is greater than the last reboot, it returns false and is non-compliant. Otherwise the client is patched and rebooted.

A reminder that PATCHING IS REBOOTING!

.NOTES
2020-02-14 - Initial build. Happy Valentines Day!
2020-02-15 - Added the check for the last reboot and made the patching threshold a variable
2020-02-16 - Added Exception method to catch, Write-Output added to display last patch/reboot time
#>
$date = Get-Date
$lastreboot = (Get-CimInstance -ClassName win32_operatingsystem -ErrorAction Stop | Select-Object lastbootuptime).lastbootuptime
#Days since last patched
[int]$lastpatchdays = 60 

try {
    $lasthotfix = (Get-Hotfix -ErrorAction Stop | Sort-Object InstalledOn | Select-Object -Last 1).InstalledOn

    $timespan = New-TimeSpan -Start $lasthotfix -End $date

    if ($($timespan).Days -gt $lastpatchdays) {
        #Non Compliant machines should report false
        $false
        Write-Output "Last Patch Installed $lasthotfix"
    }
    elseif ($lasthotfix -gt $lastreboot) {
        #Patching IS Rebooting!!!!!
        $false
        Write-Output "Last Reboot $lastreboot"
    }
    else {
        #Computer is Compliant and patched
        $true
        
    }
}
catch {
    $Error[0].Exception.Message
    Write-Output 'Error Occurred'
}