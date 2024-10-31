# Copy Language Features
# https://osdbuilder.osdeploy.com/docs/contentpacks/multilang-content/oslanguagepacks

[CmdletBinding(DefaultParameterSetName = "SO")]
Param (
    [Parameter(Mandatory)]
    [ValidateSet('21H2','22H2','23H2','24H2')]
    [string]$OSVersion
)

Split-Path $MyInvocation.MyCommand.Path | Push-Location
$Error.Clear()

$LPs = @{
    '21H2' = @{
        ISO          = 'D:\ISOs\Win11\21H2\SW_DVD9_Win_11_21H2_x64_MultiLang_LangPackAll_LIP_LoF_X22-62148.iso'
        Languages    = @('en-us', 'es-es', 'ca-es')
        LanguagesLXP = @('en-us', 'es-es', 'ca-es')
        BaseLanguage = 'en-us'
    }
    '22H2' = @{
        ISO          = 'D:\ISOs\Win11\22H2\SW_DVD9_Win_11_22H2_x64_MultiLang_LangPackAll_LIP_LoF_X23-12645.iso'
        Languages    = @('en-us', 'es-es', 'ca-es')
        LanguagesLXP = @('en-us', 'es-es', 'ca-es')
        BaseLanguage = 'en-us'
    }
    '23H2' = @{
        ISO          = 'D:\ISOs\Win11\22H2\SW_DVD9_Win_11_22H2_x64_MultiLang_LangPackAll_LIP_LoF_X23-12645.iso'
        Languages    = @('en-us', 'es-es', 'ca-es', 'gl-es', 'eu-es')
        LanguagesLXP = @('en-us', 'es-es', 'ca-es', 'gl-es', 'eu-es')
        BaseLanguage = 'en-us'
    }
    '24H2' = @{
        ISO          = 'D:\ISOs\Win11\24H2\SW_DVD9_Win_11_24H2_x64_MultiLang_LangPackAll_LIP_LoF_X23-69888.iso'
        Languages    = @('en-us', 'es-es', 'ca-es', 'gl-es', 'eu-es')
        LanguagesLXP = @('en-us', 'es-es', 'ca-es', 'gl-es', 'eu-es')
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

$Source = $ISODrive + ":\LanguagesAndOptionalFeatures"
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

    $Destination = "$($SetOSDBuilder.PathContentPacks)\MultiLang $Language\OSLanguagePacks\Windows 11 $OSVersion x64"
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

    $Destination = "$($SetOSDBuilder.PathContentPacks)\MultiLang $LanguageLXP\OSLocalExperiencePacks\Windows 11 $OSVersion x64"
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
