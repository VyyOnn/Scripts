#Deploys multiple virtual machines specified by number array
$IT = Get-OSCustomizationSpec 'IT'
4..8 | Foreach {
New-VM -vmhost vionits-dc01-esxi00.vionits.com -Name IT-$_ -Template IT-Template -Datastore DC01-HUS_DATASTORE1 -Location "IT" -OSCustomizationspec $IT 
New-OSCustomizationSpec -Spec $IT -Name IT-$_ -Type NonPersistent 
Get-OSCustomizationNicMapping -OSCustomizationSpec IT-$_ | Set-OSCustomizationNicMapping -IPmode UseStaticIP -IpAddress 192.168.100.23$_ -SubnetMask '255.255.255.0' -DefaultGateway '192.168.100.22' -Dns '192.168.100.1', '192.168.100.241'}

