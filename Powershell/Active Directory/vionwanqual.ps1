#this script runs a report on servers and pulls their name, os, ip, fqdn, firewall, ie version, nla, and rdp. Exports into csv

#import's module for activedirectory commandlets
import-module activedirectory

#import's list of servers
$servers = Import-CSV c:\scripts\serverlist.csv

#for each loop on server list
$servers| % {
#name, os, ip address, fqdn
Get-ADComputer -Identity $_.Name -Property * | Select-Object Name,OperatingSystem,IPv4Address,DNSHostName,OperatingSystemServicePack

Invoke-Command -ComputerName $_.Name -ScriptBlock {

#firewall status
netsh -r $_.Name -c advfirewall show allprofiles | findstr /i "profile state" 

#ie versipon
 (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Internet Explorer').svcVersion 
 (Get-WmiObject Win32_OperatingSystem).EncryptionLevel
 (Get-WmiObject Win32_OperatingSystem).SerialNumber
 (Get-WmiObject Win32_OperatingSystem).OSArchitecture

#nla setting
#(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-#tcp'").userauthenticationRequired

#rdp version
#(Get-WmiObject Win32_TSGeneralSetting)" -Namespace root\cimv2\terminalservices  -Filter "TerminalName='RDP-tcp'").terminalprotocol
}
}  

#out-file c:\scripts\wan4.csv

#Export-Csv 'C:\Scripts\wan1.csv'

#-ComputerName $_.Name

#user list
#application list
#service list