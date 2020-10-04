# Import Features on Demand (FOD)
# https://osdbuilder.osdeploy.com/docs/contentpacks/content/oscapability

[CmdletBinding(DefaultParameterSetName = "SO")]
Param (
    [Parameter(Mandatory)]
    [ValidateSet('1903', '1909', '2004')]
    [string]$OSVersion
)

Split-Path $MyInvocation.MyCommand.Path | Push-Location
$Error.Clear()

$FODs = @{
    '1903' = @{
        ISO       = 'E:\EQUIPS\ISOs\Win10\1903\SW_DVD9_NTRL_Win_10_1903_64Bit_MultiLang_FOD_1_X22-01658.iso'
        Languages = @($null, 'es-es', 'en-us', 'fr-fr', 'ca-es')
    }
    '1909' = @{
        ISO       = 'E:\EQUIPS\ISOs\win10\1909\SW_DVD9_NTRL_Win_10_1903_64Bit_MultiLang_FOD_1_X22-01658.iso'
        Languages = @($null, 'es-es', 'en-us', 'fr-fr', 'ca-es')
    }
    '2004' = @{
        ISO       = 'E:\EQUIPS\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_64Bit_MultiLang_FOD_1_X22-21311.iso'
        Languages = @($null, 'es-es', 'en-us', 'fr-fr', 'ca-es')
    }
}

# Do not modify below this line
# =============================

# ISO file of OS Version
$ISO = $FODs[$OSVersion].ISO

# Languages we support (First value must be $null for Language Neutral)
# Add additional values for additional installed languages
$Languages = $FODs[$OSVersion].Languages

# Test if this ISO is mounted. If not, mount it and get DriveLetter
$ISODrive = (Get-DiskImage -ImagePath $ISO | Get-Volume).DriveLetter
If (!$ISODrive) {
    $mountResult = Mount-DiskImage -ImagePath $ISO -PassThru
    $ISODrive = ($mountResult | Get-Volume).DriveLetter
}
$Source = $ISODrive + ":\"
$SourceMetadata = $Source + "metadata\"
Write-Output "ISO File is $ISO"
Write-Output "ISO Mounted Drive is $Source"
Write-Output "ISO Metadata is $SourceMetadata"

# Initialize OSDBuilder Variables
Initialize-OSDBuilder

New-OSDBuilderContentPack -Name "RSAT" -ContentType OS

$Destination = "$($SetOSDBuilder.PathContentPacks)\RSAT\OSCapability\$OSVersion x64 RSAT"
$DestinationMetadata = $Destination + "\metadata"
Write-Output "Destination $Destination"
Write-Output "Metadata $DestinationMetadata"

$Architectures = @('x86', 'amd64', 'wow64')
if (!(Test-Path $Destination)) { New-Item $Destination -ItemType Directory -Force | Out-Null }
if (!(Test-Path $DestinationMetadata)) { New-Item $DestinationMetadata -ItemType Directory -Force | Out-Null }

foreach ($Language in $Languages) {
    if ($Language) { Write-Output "Processing Language $Language..." } else { Write-Output "Processing Language Neutral..." }

    # Metadata
    Get-ChildItem $SourceMetadata -Recurse -Include DesktopTargetCompDB_Neutral.xml.cab, "DesktopTargetCompDB_$Language.xml.cab" | ForEach-Object {
        Write-Output "- $($_.Name)"
        Copy-Item $_.FullName $DestinationMetadata -Force
    }

    Write-Output "- FoDMetadata_Client.cab"
    Copy-Item $Source\FoDMetadata_Client.cab $Destination -Force

    # FOD
    foreach ($Architecture in $Architectures) {
        Write-Output "Processing Architecture $Architecture..."
        Get-ChildItem $Source -Recurse -Include "Microsoft-Windows*FoD*$Architecture~$Language~.cab" -Exclude *Holographic* | ForEach-Object {
            Write-Output "- $($_.Name)"
            Copy-Item $_.FullName $Destination -Force
        }
    }
}

# Clean
$ExtraDirs = @('Media', 'OSDrivers', 'OSExtraFiles', 'OSPackages', 'OSPoshMods', 'OSRegistry', 'OSScripts', 'OSStartLayout')
foreach ($Dir in $ExtraDirs) {
    Remove-Item "$($SetOSDBuilder.PathContentPacks)\RSAT\$Dir" -Recurse
}

If ($ISODrive) {
    Dismount-DiskImage -ImagePath $ISO | Out-Null
}

Pop-Location