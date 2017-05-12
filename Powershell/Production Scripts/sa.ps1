#Uses CSV to find service account specified by filter
$computers = Get-Content "allwindowsservers.csv"
ForEach ($computer in $computers) {Get-WmiObject win32_service -Filter "StartName='vion\\administrator'" -computer $Computer | Select-Object StartName, Caption, SystemName}