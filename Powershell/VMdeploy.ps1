#Deploys multiple virtual machines specified by number array
1..5 | Foreach {
$IT = Get-OSCustomizationSpec 'IT' | New-OSCustomizationSpec -Name IT$_ -Type NonPersistent
Get-OSCustomizationNicMapping -spec $VSC| Set-OSCustomizationNicMapping -IPmode UseStaticIP -IpAddress 192.168.100.23$_ -SubnetMask '255.255.255.0' -DefaultGateway '192.168.100.22' -Dns '192.168.100.1', '192.168.100.10' -whatif }

