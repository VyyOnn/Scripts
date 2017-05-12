#Imports Active Directory Powershell Module
Import-Module ActiveDirectory
#exports only computer objects with desktop operating systems
Get-ADComputer -Filter {OperatingSystem -NotLike "*server*"} -Property * | Select-Object Name | Export-CSV AllWindows1.csv 
#Uses CSV to find mac address of each adcomputer
$computers = Get-Content "allwindows1.csv"
ForEach ($computer in $computers) {getmac /s $Computer}