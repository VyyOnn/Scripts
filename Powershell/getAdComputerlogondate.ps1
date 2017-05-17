## This script gets all the computers that have not logged on for a certain amount of days.
Import-Module activedirectory

$logon = Get-Date

$logon = $logon.AddDays(-90) ## You can change the amount of days here.

$logondate = Get-ADComputer -Filter 'LastLogonDate -lt $logon' -Properties LastLogonDate | Select-Object Name, LastLogonDate | Sort-Object Name

$logondate | Export-Csv C:\whateverpath ## Select where you want this csv to be saved.
