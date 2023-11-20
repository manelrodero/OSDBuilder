# https://patrickvandenborn.blogspot.com/2019/10/wvd-and-vdi-automation-change-in.html

$preferred_list = New-WinUserLanguageList -Language 'en-US'
$preferred_list.Add('es-ES')
$preferred_list.Add('ca-ES')
$preferred_list[0].InputMethodTips.Clear()
$preferred_list[0].InputMethodTips.Add('0409:0000040A')
Set-WinUserLanguageList -LanguageList $preferred_list -Force
Set-WinUILanguageOverride -Language 'en-US'
Set-Culture -CultureInfo 'en-US'
