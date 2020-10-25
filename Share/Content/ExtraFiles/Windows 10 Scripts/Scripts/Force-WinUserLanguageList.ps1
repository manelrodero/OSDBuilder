$prefered_list = Get-WinUserLanguageList
$prefered_list.Add("es-es")
$prefered_list.Add("ca-es")
$prefered_list.Add("en-us")
Set-WinUserLanguageList($prefered_list) -Force
