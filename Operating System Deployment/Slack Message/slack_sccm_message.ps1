<#  
  .NOTES
  ===========================================================================
   Created with:   Visual Studio Code
   Created on:     2019-03-30
   Created by:     John Kuntz 
   Filename:       slack_sccm_message.ps1
  ===========================================================================
  .DESCRIPTION
    This script uses Slack API to send messages regarding the success or failure of an in-place upgrade
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false, HelpMessage = "Determines the message format for successful or unsuccessful imaging")]
    [ValidateSet('Pass', 'Fail')]
    [string]$PassFail = 'Pass'
)
#Uses TS Env doesnt give much on x64 arch
try {
    $TSenv = New-Object -COMObject 'Microsoft.SMS.TSEnvironment' -ErrorAction Stop
    }
catch {
    "Can't Create TS Environment Variable"
}
if ($TSenv) {
    $logdir = $TSenv.Value("_SMSTSLogPath")
}

Else {
    $logdir = Join-Path $env:SystemRoot "Temp"
}
$ErrorActionPreference = 'Stop'
$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$logFile = "OSD_Slack_Message_$($timeStamp).log"
Start-Transcript -Path $(Join-Path $logDir $logFile)
$uri = '<SLACK URI HERE>'
#Date and Time
$DateTime = Get-Date -Format "yyyy-MM-dd HH:mm"

#Computer Make
$Make = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer

#Computer Model
$Model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model

#Computer Name
$Name = (Get-CimInstance -ClassName Win32_ComputerSystem).Name

#Computer Serial Number
[string]$SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber

#IP Address of the Computer
$IPAddress = ((Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration) | Where-Object {$_.ipaddress -notlike $null} | Select-Object -ExpandProperty ipaddress -First 1)[0]

#Declare Task Sequence Variables
If ($TSEnv){
$TSName = $TSenv.Value("_SMSTSPackageName")
$TSAppInstall = $TSenv.Value("_TSAppInstallStatus")
$TSUser = $TSenv.Value("XAuthenticatedUser")
$TSOperatingSystem = $TSenv.Value("XCMWindowsVersion")
$TSLogs = $TSenv.Value("_smstsmachinename")
$TSLogLocation = "file:{0}" -f ($(Join-Path '\\<SERVERNAME>\TS_Logs' $TSLogs) -replace "\\", "/" -replace " ", "%20")


# Use the Start and End TaskSequence Varaibles to Determine the Duration
$Timespan = New-TimeSpan -Start ($TSenv.Value('StartTime')) -End ($TSenv.Value('EndTime'))
}

if (!($Timespan.Hours)) {
    $Hours = '0 Hours'
}
Else {
    $Hours = "$($Timespan.Hours) Hours"
}
if (!($Timespan.Minutes)) {
    $Minutes = '0 Minutes'
}
Else {
    $Minutes = "$($Timespan.Minutes) Minutes"
}
if (!($Timespan.Seconds)) {
    $Seconds = '0 Minutes'
}
Else {
    $Seconds = "$($Timespan.Seconds) Seconds"
}
$Duration = "$Hours $Minutes $Seconds"
# these values would be retrieved from or set by an application
$color = ''
$Status = ''
$icon = ''
$thumb = ''
$footer = ''
if ($PassFail -eq 'Pass') {
    $color = '#25AE88'
    $status = 'Successful'
    $icon = ':success:'
    $footer = 'Slack API'
}
if ($PassFail -eq 'Fail') {
    $color = 'danger'
    $status = 'Failed'
    $icon = ':error:'
    $footer = "Log folder located at \\<SERVERNAME>\TS_LOGS\$TSLogs"   
}

#Slack Message Attachment Parameters
$slacknotification = @{
    attachments = @(
        @{
            author_name = "Computer Imaged by $TSUser"
            author_icon = 'https://i.imgur.com/419ZLhh.png'
            title       = "$Name Imaging $Status" 
            pretext     = "$TSName - $TSOperatingSystem"
            fields      = @(
                @{
                    title = 'Name'
                    value = "$name"
                    short = $True
                }
                @{
                    title = 'Finished'
                    value = "$datetime"
                    short = $True
                }
                @{
                    title = 'Duration'
                    value = "$Duration"
                    short = $True
                }
                @{
                    title = 'IP Address'
                    value = "$IPAddress"
                    short = $True
                }
                @{
                    title = 'Manufacturer'
                    value = "$make"
                    short = $True
                }
                @{
                    title = 'Model'
                    value = "$model"
                    short = $True
                }
                @{
                    title = 'Serial Number'
                    value = "$serialnumber"
                    short = $True
                }
                @{
                    title = 'Installed Application Status'
                    value = "$TSAppInstall"
                    short = $True
                }
            )
            thumb_url   = 'https://i.imgur.com/iHXyk2o.png'
            footer      = "$footer"
            footer_icon = "https://i.imgur.com/YmxkBUk.png"
            color       = "$color"
            mrkdwn_in   = @('text')
            actions     = @(
                @{
                    type = "button"
                    text = "Logs"
                    url  = "$TSLogLocation"
                })
        }
    )
} | ConvertTo-Json -Depth 6


#Send Slack Message
try {
    (Invoke-RestMethod -uri $uri -Body $slacknotification -Method Post -ContentType application/json -WarningAction Stop).BaseResponse
    Write-Output $_.Exception.Message
}
Catch [System.Net.WebException] {
    Write-Verbose "An exception was caught: $($_.Exception.Message)"
    Write-Error $_.Exception.Response.StatusCode.Value__ 
}
Stop-Transcript