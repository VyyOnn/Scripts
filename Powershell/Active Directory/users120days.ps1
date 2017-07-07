#Script to search based on 120 days or older and export to file
$datecutoff=(Get-Date).AddDays(-120)

Get-ADUser  -Properties LastLogonDate -Filter {LastLogonDate -lt $datecutoff} |Where {$_.Enabled -eq $false} | Sort LastLogonDate |FT Name, LastLogonDate -Autosize | Out-File C:\scripts\usersolderthan120days.txt

Get-ADUser  -Properties LastLogonDate -Filter {LastLogonDate -lt $datecutoff} |Where {$_.Enabled -eq $false} | Move-ADObject -TargetPath 'OU=Obsolete Users,DC=vion,DC=local'