# Copy Language Features On Demand (Basic, Handwriting, OCR, Speech, TextToSpeech)
# https://osdbuilder.osdeploy.com/docs/contentpacks/multilang-content/oslanguagefeatures

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
        ISO          = 'D:\ISOs\Win10\1903\SW_DVD9_NTRL_Win_10_1903_64Bit_MultiLang_FOD_1_X22-01658.iso'
        Languages    = @('es-es', 'en-us', 'ca-es')
        BaseLanguage = 'en-us'
    }
    '1909' = @{
        ISO          = 'D:\ISOs\Win10\1909\SW_DVD9_NTRL_Win_10_1903_64Bit_MultiLang_FOD_1_X22-01658.iso'
        Languages    = @('es-es', 'en-us', 'ca-es')
        BaseLanguage = 'en-us'	
    }
    '2004' = @{
        ISO          = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_64Bit_MultiLang_FOD_1_X22-21311.iso'
        Languages    = @('es-es', 'en-us', 'ca-es')
        BaseLanguage = 'en-us'
    }
    '20H2' = @{
        ISO          = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_64Bit_MultiLang_FOD_1_X22-21311.iso'
        Languages    = @('es-es', 'en-us', 'ca-es')
        BaseLanguage = 'en-us'
    }
    '21H2' = @{
        ISO          = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_64Bit_MultiLang_FOD_1_X22-21311.iso'
        Languages    = @('es-es', 'en-us', 'ca-es')
        BaseLanguage = 'en-us'
    }
    '22H2' = @{
        ISO          = 'D:\ISOs\Win10\2004\SW_DVD9_NTRL_Win_10_2004_64Bit_MultiLang_FOD_1_X22-21311.iso'
        Languages    = @('es-es', 'en-us', 'ca-es')
        BaseLanguage = 'en-us'
    }
}

# Do not modify below this line
# =============================

# ISO file of OS Version
$ISO = $LPs[$OSVersion].ISO

# Language Packs we want to copy (i.e. languages we support)
$Languages = $LPs[$OSVersion].Languages

# The Language of Base Media (i.e. the OSImport one)
$BaseLanguage = $LPs[$OSVersion].BaseLanguage

# Test if this ISO is mounted. If not, mount it and get DriveLetter
$ISODrive = (Get-DiskImage -ImagePath $ISO | Get-Volume).DriveLetter
If (!$ISODrive) {
    $mountResult = Mount-DiskImage -ImagePath $ISO -PassThru
    $ISODrive = ($mountResult | Get-Volume).DriveLetter
}

$Source = $ISODrive + ":\"
Write-Output "ISO File is $ISO"
Write-Output "LP FOD is $Source"

# Initialize OSDBuilder Variables
Initialize-OSDBuilder

foreach ($Language in $Languages) {
    Write-Output "Processing $Language FOD ..."
    New-OSDBuilderContentPack -ContentType MultiLang -Name "MultiLang $Language"

    $Destination = "$($SetOSDBuilder.PathContentPacks)\MultiLang $Language\OSLanguageFeatures\Windows 10 $OSVersion x64"
    New-Item -Path "$Destination" -ItemType Directory -Force | Out-Null
    Write-Output "Destination $Destination"
    
    $LanguageFeatures = Get-ChildItem $Source | ? { $_.Name -match 'LanguageFeatures' } | ? { $_.Name -like "*-$($Language)-*" }

    # If you want to exclude your Base Language, swap the following lines
    # foreach ($item in $LanguageFeatures | ? {$_.Name -notmatch $BaseLanguage}) {
    foreach ($item in $LanguageFeatures) {
        Write-Output "- $item"
        Copy-Item $item.FullName "$Destination" -ea SilentlyContinue
    }
}

Dismount-DiskImage -ImagePath $ISO | Out-Null

Pop-Location
