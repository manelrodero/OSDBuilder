# Copy Language Features
# https://osdbuilder.osdeploy.com/docs/contentpacks/multilang-content/oslanguagepacks

[CmdletBinding(DefaultParameterSetName = "SO")]
Param (
    [Parameter(Mandatory)]
    [ValidateSet('1903', '1909', '2004', '20H2', '21H2', '22H2')]
    [string]$OSVersion
)

Split-Path $MyInvocation.MyCommand.Path | Push-Location
$Error.Clear()

$LPs = @{
    '1903' = @{
        ISO          = 'D:\ISOs\Win10\1903\SW_DVD9_NTRL_Win_10_1903_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-01656.iso'
        Languages    = @('es-es', 'en-us')
        LanguagesLXP = @('ca-es', 'es-es', 'en-us')
        BaseLanguage = 'en-us'
    }
    '1909' = @{
        ISO          = 'D:\ISOs\Win10\1909\SW_DVD9_NTRL_Win_10_1903_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-01656.iso'
        Languages    = @('es-es', 'en-us')
        LanguagesLXP = @('ca-es', 'es-es', 'en-us')
        BaseLanguage = 'en-us'
    }
    '2004' = @{
        ISO          = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-21307.iso'
        ISOExtraLXP  = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultLng_LngPkAll_LIP_2022.6C_LXP_X23-17081.ISO'
        Languages    = @('es-es', 'en-us')
        LanguagesLXP = @('ca-es', 'es-es', 'en-us')
        BaseLanguage = 'en-us'
    }
    '20H2' = @{
        ISO          = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-21307.iso'
        ISOExtraLXP  = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultLng_LngPkAll_LIP_2022.6C_LXP_X23-17081.ISO'
        Languages    = @('es-es', 'en-us')
        LanguagesLXP = @('ca-es', 'es-es', 'en-us')
        BaseLanguage = 'en-us'
    }
    '21H2' = @{
        ISO          = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-21307.iso'
        ISOExtraLXP  = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultLng_LngPkAll_LIP_2022.6C_LXP_X23-17081.ISO'
        Languages    = @('es-es', 'en-us')
        LanguagesLXP = @('ca-es', 'es-es', 'en-us')
        BaseLanguage = 'en-us'
    }
    '22H2' = @{
        ISO          = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-21307.iso'
        ISOExtraLXP  = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultLng_LngPkAll_LIP_2022.6C_LXP_X23-17081.ISO'
        Languages    = @('es-es', 'en-us')
        LanguagesLXP = @('ca-es', 'es-es', 'en-us')
        BaseLanguage = 'en-us'
    }
}

# Do not modify below this line
# =============================

# ISO file of OS Version
$ISO = $LPs[$OSVersion].ISO
if ($LPs[$OSVersion].ISOExtraLXP) {
    $ISOExtraLXP = $LPs[$OSVersion].ISOExtraLXP
}

# Language Packs we want to copy (i.e. languages we support)
$Languages = $LPs[$OSVersion].Languages

# Language Experience Packs we want to copy (i.e. languages we support)
$LanguagesLXP = $LPs[$OSVersion].LanguagesLXP

# The Language of Base Media (i.e. the OSImport one)
$BaseLanguage = $LPs[$OSVersion].BaseLanguage

# Test if this ISO is mounted. If not, mount it and get DriveLetter
$ISODrive = (Get-DiskImage -ImagePath $ISO | Get-Volume).DriveLetter
If (!$ISODrive) {
    $mountResult = Mount-DiskImage -ImagePath $ISO -PassThru
    $ISODrive = ($mountResult | Get-Volume).DriveLetter
}

# Test if there is an ISO with Extra LP
if ($ISOExtraLXP) {
    $ISOExtraDrive = (Get-DiskImage -ImagePath $ISOExtraLXP | Get-Volume).DriveLetter
    If (!$ISOExtraDrive) {
        $mountResult = Mount-DiskImage -ImagePath $ISOExtraLXP -PassThru
        $ISOExtraDrive = ($mountResult | Get-Volume).DriveLetter
    }
}

$Source = $ISODrive + ":\x64\langpacks"
$SourceLXP = $ISODrive + ":\LocalExperiencePack"
Write-Output "ISO File is $ISO"
Write-Output "LP is $Source"
Write-Output "LXP is $SourceLXP"

if ($ISOExtraDrive) {
    $SourceExtraLXP = $ISOExtraDrive + ":\LocalExperiencePack"
    Write-Output "LXP Extra is $SourceExtraLXP"
}

# Initialize OSDBuilder Variables
Initialize-OSDBuilder

foreach ($Language in $Languages) {
    Write-Output "Processing $Language LP ..."
    New-OSDBuilderContentPack -ContentType MultiLang -Name "MultiLang $Language"

    $Destination = "$($SetOSDBuilder.PathContentPacks)\MultiLang $Language\OSLanguagePacks\Windows 10 $OSVersion x64"
    New-Item -Path "$Destination" -ItemType Directory -Force | Out-Null
    Write-Output "Destination $Destination"

    $LanguageFeatures = Get-ChildItem $Source | ? { $_.Name -match 'Language-Pack' } | ? { $_.Name -like "*_$($Language).*" }

    # If you want to exclude your Base Language, swap the following lines
    # foreach ($item in $LanguageFeatures | ? {$_.Name -notmatch $BaseLanguage}) {
    foreach ($item in $LanguageFeatures) {
        Write-Output "- $item"
        Copy-Item $item.FullName "$Destination" -ea SilentlyContinue
    }
}

foreach ($LanguageLXP in $LanguagesLXP) {
    Write-Output "Processing $LanguageLXP LXP ..."
    New-OSDBuilderContentPack -ContentType MultiLang -Name "MultiLang $LanguageLXP"

    $Destination = "$($SetOSDBuilder.PathContentPacks)\MultiLang $LanguageLXP\OSLocalExperiencePacks\Windows 10 $OSVersion x64"
    New-Item -Path "$Destination" -ItemType Directory -Force | Out-Null
    Write-Output "Destination $Destination"

    if (Test-Path $SourceLXP\$LanguageLXP) {
    
        $LanguageFeatures = Get-ChildItem $SourceLXP\$LanguageLXP

        # If you want to exclude your Base Language, swap the following lines
        # foreach ($item in $LanguageFeatures | ? {$_.Name -notmatch $BaseLanguage}) {
        foreach ($item in $LanguageFeatures) {
            Write-Output "- $item"
            Copy-Item $item.FullName "$Destination" -ea SilentlyContinue
        }
    }
    if ($SourceExtraLXP) {
        if (Test-Path $SourceExtraLXP\$LanguageLXP) {
    
            $LanguageFeatures = Get-ChildItem $SourceExtraLXP\$LanguageLXP
    
            # If you want to exclude your Base Language, swap the following lines
            # foreach ($item in $LanguageFeatures | ? {$_.Name -notmatch $BaseLanguage}) {
            foreach ($item in $LanguageFeatures) {
                Write-Output "- (Extra) $item"
                Copy-Item $item.FullName "$Destination" -ea SilentlyContinue
            }
        }
    }
}

Dismount-DiskImage -ImagePath $ISO | Out-Null
if ($ISOExtraLXP) { Dismount-DiskImage -ImagePath $ISOExtraLXP | Out-Null }
Pop-Location
