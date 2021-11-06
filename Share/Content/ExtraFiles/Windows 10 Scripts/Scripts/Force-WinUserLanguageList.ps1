# https://patrickvandenborn.blogspot.com/2019/10/wvd-and-vdi-automation-change-in.html

$preferred_list = New-WinUserLanguageList -Language 'es-ES'
$preferred_list.Add('ca-ES')
$preferred_list.Add('en-US')
$preferred_list[2].InputMethodTips.Clear()
$preferred_list[2].InputMethodTips.Add('0409:0000040A')
Set-WinUserLanguageList -LanguageList $preferred_list -Force
