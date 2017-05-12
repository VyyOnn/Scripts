#Imports Active Directory Powershell Module
Import-Module ActiveDirectory
#Queries AD for users and selects outputs based on filters below, and exports results to CSV file.
 Get-ADUser -SearchBase `ou=Vion Users,dc=vion,dc=local' -Filter * -Properties samaccountname,name,sn,DisplayName, givenName, EmailAddress, Title, Manager, Department | Where {$_.Enabled -eq $true} | select samaccountname,name,sn,DisplayName, givenName, EmailAddress, Title, Manager, Department | Sort-Object name | Export-CSV "C:\scripts\allusersinfo.csv"


