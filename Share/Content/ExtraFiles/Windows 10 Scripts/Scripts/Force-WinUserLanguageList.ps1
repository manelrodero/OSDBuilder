# https://patrickvandenborn.blogspot.com/2019/10/wvd-and-vdi-automation-change-in.html

$preferred_list = Get-WinUserLanguageList
$preferred_list.Add("es-es")
$preferred_list.Add("ca-es")
$preferred_list.Add("en-us")
Set-WinUserLanguageList($preferred_list) -Force
