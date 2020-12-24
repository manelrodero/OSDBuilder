#   v1.0 Manel Rodero
#   http://www.manelrodero.com/
#
#   OSBuilder Script
#   Set-FileExplorerOptions.ps1

#======================================================================================
#   Remove Files
#======================================================================================

#======================================================================================
#   Load Registry Hives
#======================================================================================
$RegDefault = "$MountDirectory\Windows\System32\Config\Default"
if (Test-Path $RegDefault) {
    Write-Host "Loading $RegDefault" -ForegroundColor Cyan
    Start-Process reg -ArgumentList "load HKLM\MountDefault $RegDefault" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
}
$RegDefaultUser = "$MountDirectory\Users\Default\ntuser.dat"
if (Test-Path $RegDefaultUser) {
    Write-Host "Loading $RegDefaultUser" -ForegroundColor Cyan
    Start-Process reg -ArgumentList "load HKLM\MountDefaultUser $RegDefaultUser" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
}
$RegSoftware = "$MountDirectory\Windows\System32\Config\Software"
if (Test-Path $RegSoftware) {
    Write-Host "Loading $RegSoftware" -ForegroundColor Cyan
    Start-Process reg -ArgumentList "load HKLM\MountSoftware $RegSoftware" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
}
$RegSystem = "$MountDirectory\Windows\System32\Config\System"
if (Test-Path $RegSystem) {
    Write-Host "Loading $RegSystem" -ForegroundColor Cyan
    Start-Process reg -ArgumentList "load HKLM\MountSystem $RegSystem" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
}

#======================================================================================
#   Registry Commands
#======================================================================================

# Folder Options > General > Open File Explorer to: This PC (instead of Quick Access)
# Folder Options > General > Privacy: Show recently used files in Quick access (disable)
# Folder Options > General > Privacy: Show frequently used folders in Quick Access (disable)
# Folder Options > View > Display the full path in the title bar (enable)
# Folder Options > View > Hide extensions for known file types (disable)
# Folder Options > View > Use Sharing Wizard (disable)
# Folder Options > View > Show all folders (enable)
# Folder Options > View > Always show icons, never thumbnails (enable)

$RegCommands =
'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f',
'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowRecent /t REG_DWORD /d 0 /f',
'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f',
'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v FullPath /t REG_DWORD /d 1 /f',
'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f',
'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v SharingWizardOn /t REG_DWORD /d 0 /f',
'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v NavPaneShowAllFolders /t REG_DWORD /d 1 /f',
'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 1 /f'

foreach ($Command in $RegCommands) {
    if ($Command -like "*HKCU*") {
        $Command = $Command -replace "HKCU","HKLM\MountDefaultUser"
        Write-Host "reg $Command" -ForegroundColor Green
        Start-Process reg -ArgumentList $Command -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
    } elseif ($Command -like "*HKLM\Software*") {
        $Command = $Command -replace "HKLM\\Software","HKLM\MountSoftware"
        Write-Host "reg $Command" -ForegroundColor Green
        Start-Process reg -ArgumentList $Command -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
    } elseif ($Command -like "*HKLM\System*") {
        $Command = $Command -replace "HKLM\\System","HKLM\MountSystem"
        Write-Host "reg $Command" -ForegroundColor Green
        Start-Process reg -ArgumentList $Command -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
}

#======================================================================================
#   Unload Registry Hives
#======================================================================================
Start-Process reg -ArgumentList "unload HKLM\MountDefault" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
Start-Process reg -ArgumentList "unload HKLM\MountDefaultUser" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
Start-Process reg -ArgumentList "unload HKLM\MountSoftware" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
Start-Process reg -ArgumentList "unload HKLM\MountSystem" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue

#======================================================================================
#   Testing
#======================================================================================
#   [void](Read-Host 'Press Enter to continue')
