@echo off
pushd %~dp0
powershell.exe -noprofile -executionpolicy bypass -file makeapp.ps1 -SourceFolder .\Build -SetupFile Install.ps1
popd
