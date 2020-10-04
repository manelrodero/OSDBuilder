#   v1.0 Manel Rodero
#   http://www.manelrodero.com/
#
#   OSBuilder Script
#   Disable-ConsumerApps.ps1

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

# Fixing why Sysprep fails in Windows 10 due to Windows Store updates
# https://deploymentresearch.com/Research/Post/615/Fixing-why-Sysprep-fails-in-Windows-10-due-to-Windows-Store-updates
#
# Removing Windows 10 in-box apps during a task sequence
# https://blogs.technet.microsoft.com/mniehaus/2015/11/11/removing-windows-10-in-box-apps-during-a-task-sequence/
#
# Walkthrough: Building a Windows 10 1709 (Fall Creators Update) Reference Image with Microsoft Deployment Toolkit
# https://gal.vin/2017/10/17/building-windows-10-1709-fall-creators-update-reference-image-walkthrough/
#
# Disabling Windows 10 Consumer Experience
# https://www.windowsmanagementexperts.com/disabling-windows-10-consumer-experience/disabling-windows-10-consumer-experience.htm

# Disable Consumer Experience (no añade Candy Crush, Solitaire, etc.) -> Windows Cloud Content -> DisableWindowsConsumerFeatures (1=Off, 0=On)
# Disable Windows Store Updates -> AutoDownload (2=Always Off, 4=Always On)

$RegCommands =
'add HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f',
'add HKLM\SOFTWARE\Policies\Microsoft\WindowsStore /v AutoDownload /t REG_DWORD /d 2 /f',
'add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate /v AutoDownload /t REG_DWORD /d 2 /f'

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
