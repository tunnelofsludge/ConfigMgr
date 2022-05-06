   try {
        Import-Module WebAdministration -ErrorAction Stop
    }
    catch {
        return "Error"
    }
    $date = Get-Date
    $thumb = (Get-ChildItem IIS:SSLBindings | Where-Object { $_.Store -eq "My" -and $_.Port -eq "443" }).Thumbprint
    $expires = (Get-ChildItem -path cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq "$thumb" } | Select-Object NotAfter).NotAfter

    If ($expires -lt $date) {
        Write-Output "Non-Compliant"
    }
    else {
        Write-Output "Compliant"
    }
