#Imports Active Directory Powershell Module
Import-Module ActiveDirectory
#Queries AD for users and selects outputs based on filters below, and exports results to CSV file.
Get-ADUser -Filter * -Properties DisplayName, EmailAddress, Title, Manager, Department | Where {$_.Enabled -eq $true} | select DisplayName, EmailAddress, Title, Manager, Department | Export-CSV "C:\scripts\allusersinfo1.csv"
