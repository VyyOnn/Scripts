#Script to search based on 60 days or older and export to file
$datecutoff=(Get-Date).AddDays(-60)

Get-ADUser  -Properties LastLogonDate -Filter {LastLogonDate -lt $datecutoff} | Sort LastLogonDate |FT Name, LastLogonDate -Autosize | Out-File C:\scripts\usersolderthan60days.txt

Get-ADUser  -Properties LastLogonDate -Filter {LastLogonDate -lt $datecutoff} | Move-ADObject -TargetPath 'OU=Disabled Users,DC=vion,DC=local'