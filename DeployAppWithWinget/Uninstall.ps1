<#	
    .NOTES
        ===========================================================================
         Created on:   	28/5/2025
         Author:        Jean-Pierre Simonis
         Version:   	1.0.0
         Organisation: 	Mojo Up
         Filename:      uninstall.ps1
        ===========================================================================
    .DESCRIPTION
        Uninstalls the specified package within the Windows Package Manager (WinGet) public repository (runs as SYSTEM). 
        Can be packaged and deployed as a Win32App in Intune
        Use as a template for any install with WinGet. Simply specify the PackageID as a parameter. 
    .PARAMETER PackageName
        Specify the WinGet ID. Use WinGet Search "SoftwareName" to locate the PackageID or use reference from https://winget.run/
    .EXAMPLE
        powershell.exe -exectuionpolicy bypass -file .\uninstall.ps1 -PackageID "Adobe.Acrobat.Reader.64-bit"
    .EXAMPLE
        powershell.exe -executionpolicy bypass -file .\uninstall.ps1 -PackageID "Google.Chrome"
#>
param (
	$PackageID
)

##########################
#        Execution       #
##########################

#Start Logging
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$($PackageID)_Uninstall.log" -Append

#Trying to uninstall package with Windows Package Manager
IF ($PackageID){
    try {
        Write-Host "Checking installation status of $($PackageID) via Windows Package Manager" -ForegroundColor Green

        #Get the path to the Winget executable
        $ResolveWingetPath = Resolve-Path "$env:ProgramW6432\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
        if ($ResolveWingetPath){
               $WingetPath = $ResolveWingetPath[-1].Path
        }
        $Winget = Get-ChildItem $WingetPath -File | Where-Object { $_.name -like "Winget.exe" } | Select-Object -ExpandProperty fullname
        
        # If multiple versions are found, select the latest one
        if ($Winget.count -gt 1) { $Winget = $Winget[-1] }

        # List requested WinGet package (if installed)
        $InstalledApps = & $Winget list --id $PackageID

        #Check output of $installedApps to see if the package id is present
        if ($InstalledApps -split "`n" | Where-Object { $_ -match [regex]::Escape($PackageID) }) {
            Write-Host "Trying to uninstall $($PackageID) via Windows Package Manager"
            
            # Uninstall requested WinGet package
            & $Winget uninstall --id $PackageID --silent
        }
        else {
            Write-Host "$($PackageID) not installed or detected"
        }

    }
    Catch {
        Throw "Failed to uninstall package $($_)"
    }
}
Else {
    Write-Host "Package $($PackageID) not available" -ForegroundColor Yellow
}
Stop-Transcript