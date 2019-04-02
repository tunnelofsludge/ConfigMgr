#Enter Drive Letter That needs to be de-duped
$Volume = "D:"

#Make Sure the drive be deduplicated is not the drive where the operating system is installed. 
if ($Volume -ne $env:SystemDrive) {
    Write-Host "Drive is not a System Drive, Continuing..."
    Set-Location -Path "$Volume\" #Changes to Location to be Deduped

    #Folders that are going to be Deduped, and shouldn't be excluded
    $SCCMFolders = @("SCCMContentLib", "SMSPKG$(($Volume).Replace(':',''))$")

    #Get all the folders in the directory, except the ones to be deduped. These will be Excluded from the actual Dedupe Job
    $Excluded = Get-ChildItem -Path "$Volume\" -Directory | Where-Object {($_.Name -notin @($SCCMFolders))} | Select-Object FullName


    #Setup Dedupe Job
    Write-Host "Installing the Data Deduplication Feature"
    Import-Module ServerManager
    Add-WindowsFeature –name FS-Data-Deduplication
    Enable-DedupVolume –Volume $Volume
    $DedupeArguments = @{
        Volume             = $Volume
        MinimumFileAgeDays = 1
        ExcludeFileType    = @('PNG', 'CAB', 'ZIP', 'LZA')
        ExcludeFolder      = $($Excluded.FullName)
    }
    Set-DedupVolume @DedupeArguments
    Write-Host "Starting Dedupe Job..."
    Start-DedupJob -Type Optimization -Volume $Volume

#Loop the status of the dedupe job until it's done
    Do {
        Get-DedupJob
        Start-Sleep -Seconds 15
        Get-DedupStatus -Volume $Volume | Format-Table
        Start-Sleep -Seconds 15
    }
    Until (!(Get-DedupJob))
}
Else {
    Write-Output "Cannot Dedupe the System Drive"
}