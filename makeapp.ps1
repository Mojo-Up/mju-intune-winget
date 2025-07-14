[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)] [string] $SourceFolder,
    [Parameter(Mandatory = $True)] [string] $SetupFile,
    [Parameter(Mandatory = $False)] [string] $OutputFolder = ""
)

install-module intunewin32app
import-module intunewin32app

if ($OutputFolder -eq "") {
    $OutputFolder = "$PSScriptRoot\Output"
}
New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -Force
