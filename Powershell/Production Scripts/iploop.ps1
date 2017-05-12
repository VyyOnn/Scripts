$VSC = Get-OSCustomizationSpec 'VSC'
21..21 | Foreach {
New-VM -vmhost esx01.vion.local -Name VSC-$_ -Template VSC-Template -Datastore VSC -Location VSC_VM's' | New-OSCustomizationSpec -Name VSC$_ -Type NonPersistent 
Get-OSCustomizationNicMapping -spec $VSC| Set-OSCustomizationNicMapping -IPmode UseStaticIP -IpAddress 192.168.100.2$_ -SubnetMask '255.255.255.0' -DefaultGateway '192.168.100.22' -Dns '192.168.100.1', '192.168.100.10' | -OSCustomizationSpec VSC$_}
