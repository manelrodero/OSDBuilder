#   v1.1 Manel Rodero
#   http://www.manelrodero.com/
#
#   v1.0 David Segura
#   http://osdeploy.com
#
#   OSBuilder Script
#   Set-TimeZoneRomance.ps1

#======================================================================================
if (Test-Path $MountDirectory) {
    if (Test-Path $Logs) {
        Dism /Image:"$MountDirectory" /Set-TimeZone:"Romance Standard Time" /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-SetTimeZone.log"
    }
}
#======================================================================================
#   Testing
#======================================================================================
#   [void](Read-Host 'Press Enter to continue')
