<#  
  .NOTES
  ===========================================================================
   Created with:   Visual Studio Code
   Created on:     2018-03-21
   Created by:     John Kuntz 
   Filename:       upgrade_slack_message.ps1
  ===========================================================================
  .DESCRIPTION
    This script uses Slack API to send messages regarding the success or failure of an in-place upgrade
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Pass', 'Fail')]
    [string]$PassFail = 'Pass'
)
$uri = '<WEBHOOK URL HERE>'
# Date and Time
$DateTime = Get-Date -Format "yyyy-MM-dd HH:mm" #Time
# Time
$Time = get-date -format HH:mm
# Computer Make
$Make = (Get-WmiObject -Class Win32_BIOS).Manufacturer
# Computer Model
$Model = (Get-WmiObject -Class Win32_ComputerSystem).Model
# Computer Name
$Name = (Get-WmiObject -Class Win32_ComputerSystem).Name
# Computer Serial Number
[string]$SerialNumber = (Get-WmiObject win32_bios).SerialNumber
# IP Address of the Computer
$IPAddress = (Get-WmiObject win32_Networkadapterconfiguration | Where-Object { $_.ipaddress -notlike $null }).IPaddress | Select-Object -First 1
# Uses TS Env doesnt give much on x64 arch
$TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue
$TSName = $TSenv.Value("_SMSTSPackageName")
# Use the Start and End TaskSequence Varaibles to Determine the Duration
$Timespan = New-TimeSpan -Start ($TSenv.Value('StartTime')) -End ($TSenv.Value('EndTime'))
$Hours = $Timespan.Hours
$Minutes = $Timespan.Minutes
$Seconds = $Timespan.Seconds
$Duration = "$(if ($Hours -ne $null){"$Hours Hours"}) $(if ($Minutes -ne $null){"$Minutes Minutes"}) $(if ($Seconds -ne $null){"$Seconds Seconds"})"
# these values would be retrieved from or set by an application
$color = ''
$Status = ''
$icon = ''
$thumb = ''
if ($PassFail -eq 'Pass') {
    $color = 'good'
    $status = 'Successful'
    $icon = ':heavy_check_mark:'
    $thumb = 'https://i.imgur.com/BftO0Na.png'
}
if ($PassFail -eq 'Fail') {
    $color = 'danger'
    $status = 'Failed'
    $icon = ':x:'
    $thumb = 'https://i.imgur.com/ThR4QSe.png'
}

#Slack Message Attachment Parameters
$slacknotification = @{
    attachments = @(
        @{
            author_name = "<Company> In-Place Upgrade "
            author_icon = 'https://i.imgur.com/419ZLhh.png'
            title       = "$Name Upgrade $status $icon" 
            pretext     = "$TSName"
            text        = "Name: *$Name* `nFinished: *$datetime* `nDuration: *$Duration* `nIP Address: *$IPAddress* `nMake: *$make* `nModel: *$Model* `nSerial: *$SerialNumber*"
            thumb_url   = "$thumb"
            footer      = "Slack API"
            footer_icon = "https://platform.slack-edge.com/img/default_application_icon.png"
            color       = "$color"
            mrkdwn_in   = @('text')
          
        }
    )
} | ConvertTo-Json -Depth 6


#Send Slack Message
Invoke-RestMethod -uri $uri -Body $slacknotification -Method Post -ContentType application/json
