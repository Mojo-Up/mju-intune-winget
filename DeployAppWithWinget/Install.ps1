<#	
    .NOTES
        ===========================================================================
         Created on:   	28/5/2025
         Author:        Jean-Pierre Simonis
         Version:   	1.0.0
         Organisation: 	Mojo Up
         Filename:      install.ps1
        ===========================================================================
    .DESCRIPTION
        Installs the specified package within the Windows Package Manager (WinGet) public repository (runs as SYSTEM). 
        Can be packaged and deployed as a Win32App in Intune
        Use as a template for any install with WinGet. Simply specify the PackageID as a parameter. 
    .PARAMETER PackageName
        Specify the WinGet ID. Use WinGet Search "SoftwareName" to locate the PackageID or use reference from https://winget.run/
    .EXAMPLE
        powershell.exe -exectuionpolicy bypass -file .\install.ps1 -PackageID "Adobe.Acrobat.Reader.64-bit"
    .EXAMPLE
        powershell.exe -executionpolicy bypass -file .\install.ps1 -PackageID "Google.Chrome"
#>
param (
	$PackageID
)

##########################
#        Execution       #
##########################

#Start Logging
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$($PackageID)_Install.log" -Append

#Trying to install package with Windows Package Manager
IF ($PackageID){
    try {
        Write-Host "Installing $($PackageID) via Windows Package Manager" -ForegroundColor Green

        #Get the path to the Winget executable
        $ResolveWingetPath = Resolve-Path "$env:ProgramW6432\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
        if ($ResolveWingetPath){
               $WingetPath = $ResolveWingetPath[-1].Path
        }
        $Winget = Get-ChildItem $WingetPath -File | Where-Object { $_.name -like "Winget.exe" } | Select-Object -ExpandProperty fullname
        
        # If multiple versions are found, select the latest one
        if ($Winget.count -gt 1) { $Winget = $Winget[-1] }

        # Install requested WinGet package
        & $Winget install --id $PackageID --silent --accept-source-agreements --accept-package-agreements

    }
    Catch {
        Throw "Failed to install package $($_)"
    }
}
Else {
    Write-Host "Package $($PackageID) not available" -ForegroundColor Yellow
}
Stop-Transcript