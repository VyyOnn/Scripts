Get-ADComputer -Filter {OperatingSystem -Like "*server*"} -Property * | Select-Object Name,OperatingSystem,IPv4Address,DNSHostName | Export-CSV AllWindowsservers.csv 