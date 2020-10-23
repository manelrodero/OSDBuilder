# Copy WinPE ADK
# https://osdbuilder.osdeploy.com/docs/contentpacks/content/peadk

[CmdletBinding(DefaultParameterSetName = "SO")]
Param (
    [Parameter(Mandatory)]
    [ValidateSet('1903', '1909', '2004', '2009')]
    [string]$OSVersion
)

Split-Path $MyInvocation.MyCommand.Path | Push-Location
$Error.Clear()

$WinPEOCs = @{
    '1903' = @{
        ISO          = 'E:\EQUIPS\ISOs\Win10\1903\SW_DVD9_NTRL_Win_10_1903_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-01656.iso'
        Languages    = @('es-es', 'en-us')
        Architecture = 'x64'
    }
    '1909' = @{
        ISO          = 'E:\EQUIPS\ISOs\win10\1909\SW_DVD9_NTRL_Win_10_1903_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-01656.iso'
        Languages    = @('es-es', 'en-us')
        Architecture = 'x64'
    }
    '2004' = @{
        ISO          = 'E:\EQUIPS\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-21307.iso'
        Languages    = @('es-es', 'en-us')
        Architecture = 'x64'
    }
    '2009' = @{
        ISO          = 'E:\EQUIPS\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-21307.iso'
        Languages    = @('es-es', 'en-us')
        Architecture = 'x64'
    }
}

# Do not modify below this line
# =============================

$Source = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment'
$Source_Architecture = 'amd64'

# ISO file of OS Version
$ISO = $WinPEOCs[$OSVersion].ISO

# Languages we support (Add additional values for additional installed languages)
$Languages = $WinPEOCs[$OSVersion].Languages

# Architecture
$Architecture = $WinPEOCs[$OSVersion].Architecture

# Locate WinPE_Ocs directory in Windows ADK install directory
$WinPEOCs = $Source + "\" + $Source_Architecture + "\WinPE_OCs"
Write-Output "Source is $Source"
Write-Output "WinPE OCs is $WinPEOCs"

# Initialize OSDBuilder Variables
Initialize-OSDBuilder

New-OSDBuilderContentPack -Name "PEADK" -ContentType WinPE

$Destination = "$($SetOSDBuilder.PathContentPacks)\PEADK\PEADK\$OSVersion x64"
Write-Output "Destination $Destination"

if (!(Test-Path $Destination)) { New-Item $Destination -ItemType Directory -Force | Out-Null }

Get-ChildItem $WinPEOCs -Include WinPE* | ForEach-Object {
    Write-Output "- $($_.Name)"
    Copy-Item $_.FullName $Destination -Force
}

foreach ($Language in $Languages) {
    Write-Output "Processing Language $Language..."
    $WinPEOCsLang = $WinPEOCs + "\" + $Language
    $DestinationLang = $Destination + "\" + $Language
    Write-Output "Destination $DestinationLang"
    if (!(Test-Path $DestinationLang)) { New-Item $DestinationLang -ItemType Directory -Force | Out-Null }
    Get-ChildItem $WinPEOCsLang -Include lp.cab, WinPE* -Recurse | ForEach-Object {
        Write-Output "- $($_.Name)"
        Copy-Item $_.FullName $DestinationLang -Force
    }
}

# Test if this ISO is mounted. If not, mount it and get DriveLetter
$ISODrive = (Get-DiskImage -ImagePath $ISO | Get-Volume).DriveLetter
If (!$ISODrive) {
    $mountResult = Mount-DiskImage -ImagePath $ISO -PassThru
    $ISODrive = ($mountResult | Get-Volume).DriveLetter
}
$Source = $ISODrive + ":\"
$WinPEOCs = $Source + "Windows Preinstallation Environment\" + $Architecture + "\WinPE_OCs"
Write-Output "ISO File is $ISO"
Write-Output "ISO Mounted Drive is $Source"
Write-Output "ISO WinPE_OCs is $WinPEOCs"
Write-Output "$Destination"

Get-ChildItem $WinPEOCs -Include WinPE* | ForEach-Object {
    Write-Output "- $($_.Name)"
    Copy-Item $_.FullName $Destination -Force
}

foreach ($Language in $Languages) {
    $WinPEOCsLang = $WinPEOCs + "\" + $Language
    $DestinationLang = $Destination + "\" + $Language
    Write-Output "Destination $DestinationLang"
    if (!(Test-Path $DestinationLang)) { New-Item $DestinationLang -ItemType Directory -Force | Out-Null }
    Get-ChildItem $WinPEOCsLang -Include lp.cab, WinPE* -Recurse | ForEach-Object {
        Write-Output "- $($_.Name)"
        Copy-Item $_.FullName $DestinationLang -Force
    }
}

# Clean
$ExtraDirs = @('PEDaRT', 'PEDrivers', 'PEExtraFiles', 'PEPoshMods', 'PERegistry', 'PEScripts')
foreach ($Dir in $ExtraDirs) {
    Remove-Item "$($SetOSDBuilder.PathContentPacks)\PEADK\$Dir" -Recurse
}

If ($ISODrive) {
    Dismount-DiskImage -ImagePath $ISO | Out-Null
}

Pop-Location