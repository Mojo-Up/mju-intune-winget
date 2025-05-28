<#	
    .NOTES
        ===========================================================================
         Created on:   	28/5/2025
         Author:        Jean-Pierre Simonis
         Version:   	1.0.0
         Organisation: 	Mojo Up
         Filename:      WinGet-UpdateApplications.ps1
        ===========================================================================
    .DESCRIPTION
        Automate the update of any applications installed and managed by the WinGet public repository (runs as SYSTEM).
        To be used as an Intune PowerShell remedation script to update any application with available upgrades with
        Windows Package Manager (WinGet).
    .EXAMPLE
        powershell.exe -exectuionpolicy bypass -file .\WinGet-UpdateApplications.ps1
#>

##########################
#        Exceptions      #
##########################

# Please specify exceptions for package ids that should not be updated by Windows Package Manager.
$Exceptions = @(
	'Microsoft.Teams'
	'Microsoft.Office'
    'Microsoft.DotNet.SDK.8'
)

##########################
#        Execution       #
##########################

#Start Logging
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\WinGet-UpdateApplications.log" -Append

#Trying to check installation status of all packages with Windows Package Manager

try {
    Write-Host "Checking for available application updates via Windows Package Manager" -ForegroundColor Green

    #Get the path to the Winget executable
    $ResolveWingetPath = Resolve-Path "$env:ProgramW6432\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
    if ($ResolveWingetPath){
            $WingetPath = $ResolveWingetPath[-1].Path
    }
    $Winget = Get-ChildItem $WingetPath -File | Where-Object { $_.name -like "Winget.exe" } | Select-Object -ExpandProperty fullname
    
    # If multiple versions are found, select the latest one
    if ($Winget.count -gt 1) { $Winget = $Winget[-1] }

    # List requested WinGet package (if installed)
    $WingetOutput = & $Winget list -e --upgrade-available

    # Convert output to array and skip header lines
    $lines = $WingetOutput | Where-Object { $_.Trim() -ne "" }
    $lines = $lines | Select-Object -Skip 2  # Skip the header and separator

    # Parse each line into an object, excluding exceptions
    $AvailableUpdates = foreach ($line in $lines) {
        # Use regex to split columns by two or more spaces
        if ($line -match '^(.*?)\s{2,}(.*?)\s{2,}(.*?)\s{2,}(.*?)\s{2,}(.*?)$') {
            $id = $matches[2].Trim()
            if ($Exceptions -notcontains $id) {
                [PSCustomObject]@{
                    Name      = $matches[1].Trim()
                    Id        = $id
                    Version   = $matches[3].Trim()
                    Available = $matches[4].Trim()
                    Source    = $matches[5].Trim()
                }
            }
        }
    }

    # Remove the first record as it contains the header row data from winget output
    $AvailableUpdates = $AvailableUpdates | Where-Object { $_ } | Select-Object -Skip 1

    # Write-Host the list of exceptions into logs
    if ($Exceptions.Count -gt 0) {
        Write-Host "The following application Ids are excluded from update evaluation:"
        foreach ($ex in $Exceptions) {
            Write-Host "  - $ex"
        }
        Write-Host ""
    }

    # Write-Host the list of applications with available updates (not in exceptions) into Logs
    $UpdatesToShow = $AvailableUpdates | Where-Object { $null -ne $_.Available -and $_.Available.Trim() -ne "" }
    if ($UpdatesToShow.Count -gt 0) {
        Write-Host "Applications with available updates:"
        foreach ($update in $UpdatesToShow) {
            Write-Host "  $($update.Name) [$($update.Id)] - Current: $($update.Version), Available: $($update.Available)"
        }
        Write-Host ""
    }

    # Perform update of applicable applications
    # Write-Host the list of applications with available updates (not in exceptions)
    $AppsToUpdate = $AvailableUpdates | Where-Object { $null -ne $_.Available -and $_.Available.Trim() -ne "" }
    if ($AppsToUpdate.Count -gt 0) {
        Write-Host "Updating Applications via Windows Package Manager" -ForegroundColor Green
        foreach ($update in $AppsToUpdate) {
            Write-Host "  $($update.Name) [$($update.Id)] - Current: $($update.Version), Available: $($update.Available)"
            # update requested WinGet package
            & $Winget upgrade --id $update.Id --silent --accept-source-agreements --accept-package-agreements
        }
        Write-Host ""
        # Return exit code 0 to indicate successful intune powershell remediation complete
        Exit 0
    }
    else {
        Write-Host "No applications with available updates found." -ForegroundColor Yellow
        # Return exit code 1 to indicate failed intune powershell remediation
        Exit 1
    }
}
Catch {
    Write-Host "Failed to update the Windows Package Manager (Winget) applications $($_)"
    Throw "Failed to update the Windows Package Manager (Winget) applications $($_)"
}
Stop-Transcript