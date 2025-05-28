<#	
    .NOTES
        ===========================================================================
         Created on:   	28/5/2025
         Author:        Jean-Pierre Simonis
         Version:   	1.0.0
         Organisation: 	Mojo Up
         Filename:      WinGet-UpdateDetection.ps1
        ===========================================================================
    .DESCRIPTION
        Detection of the installation status any deployed package within the WinGet public repository (runs as SYSTEM).
        To be used as an Intune PowerShell script for the detection of application upgrades with Windows Package Manager
        (WinGet).
    .EXAMPLE
        powershell.exe -exectuionpolicy bypass -file .\WinGet-UpdateDetection.ps1
#>

##########################
#        Exceptions      #
##########################

# Please specify exceptions for package ids that should not be checked for updates by Windows Package Manager (WinGet).
$Exceptions = @(
	'Microsoft.Teams'
	'Microsoft.Office'
    'Microsoft.DotNet.SDK.8'
)

##########################
#        Execution       #
##########################

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

    # Write-Host the list of exceptions
    if ($Exceptions.Count -gt 0) {
        Write-Host "The following application Ids are excluded from update evaluation:"
        foreach ($ex in $Exceptions) {
            Write-Host "  - $ex"
        }
        Write-Host ""
    }

    # Write-Host the list of applications with available updates (not in exceptions)
    $UpdatesToShow = $AvailableUpdates | Where-Object { $null -ne $_.Available -and $_.Available.Trim() -ne "" }
    if ($UpdatesToShow.Count -gt 0) {
        Write-Host "Applications with available updates:"
        foreach ($update in $UpdatesToShow) {
            Write-Host "  $($update.Name) [$($update.Id)] - Current: $($update.Version), Available: $($update.Available)"
        }
        Write-Host ""
    }

    # Iterate $AvailableUpdates and check if there are any records with the Available value is not null or empty
    $HasUpdates = $false
    foreach ($update in $AvailableUpdates) {
        if ($null -ne $update.Available -and $update.Available.Trim() -ne "") {
            $HasUpdates = $true
            break
        }
    }

    if ($HasUpdates) {
        Write-Host "At least one application has an available update."
        # Return exit code 1 to indicate intune powershell remediation is needed
        Exit 1
    } else {
        Write-Host "No application updates available."
        # Return exit code 0 to indicate no intune powershell remediation is needed
        Exit 0
    }


}
Catch {
    Throw "Failed to check the Windows Package Manager applications update status $($_)"
}
