<#	
    .NOTES
        ===========================================================================
         Created on:   	28/5/2025
         Author:        Jean-Pierre Simonis
         Version:   	1.0.0
         Organisation: 	Mojo Up
         Filename:      detection.ps1
        ===========================================================================
    .DESCRIPTION
        Detection of installation status of the deployed package within the Windows Package Manager (WinGet) public repository (runs as SYSTEM). 
        Can be packaged and deployed as a Win32App in Intune
        Use as a template for any application deployed with WinGet from intune.
        Simply specify the Package ID in the variables sections of this script. 
    .PARAMETER PackageID
        Specify the WinGet ID. Use WinGet Search "SoftwareName" to locate the PackageID or use reference from https://winget.run/
    .EXAMPLE
        powershell.exe -exectuionpolicy bypass -file .\detection.ps1
#>

##########################
#        Variables       #
##########################

#Please update this with the PackageID you want to check
$PackageID = "Google.Chrome"


##########################
#        Execution       #
##########################

#Trying to check installation status of package with Windows Package Manager
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
            Write-Host "$($PackageID) is installed"
            # Return exit code 0 to indicate to intune successful deployment of the package
            Exit 0
        }
        else {
            Write-Host "$($PackageID) not detected"
            # Return exit code 1 to indicate to intune unsuccessful deployment of the package
            Exit 1
        }

    }
    Catch {
        Throw "Failed to check status of package $($_)"
    }
}
Else {
    Write-Host "Package $($PackageID) not available" -ForegroundColor Yellow
}