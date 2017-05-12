#Imports Active Directory Powershell Module
Import-Module ActiveDirectory
#exports only computer objects with desktop operating systems
Get-ADComputer -Filter {OperatingSystem -NotLike "*server*"} -Property * | Select-Object Name | Export-CSV AllWindowsClients.csv 