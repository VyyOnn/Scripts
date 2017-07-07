#this script is another script that set's the ad user's information based on a csv

Import-Module activedirectory
$usercsv = Import-CSV c:\scripts\lc.csv

$usercsv| % {
$user = Get-ADUser -filter "DisplayName -eq '$($_.displayname)'" 

$manager = Get-ADUser -filter "Displayname -eq '$($_.manager)'"
	if ($_.manager -eq "")
	  {$manager = "administrator"} 
	else {$manager = $manager }
$Description = $_.Description
	if ($_.description -eq "") 
	  {$description = "update"} 
	else 
	  {$description = $_.description }
$Title = $_.Title
	if ($_.Title -eq "") 
	  {$Title = "update"} 
	else 
	  {$Title = $_.Title }
$Telephonenumber = $_.TelephoneNumber
	if ($_.TelephoneNumber -eq "") 
	  {$TelephoneNumber = "update"} 
	else 
	  {$TelephoneNumber = $_.TelephoneNumber }
$Department = $_.Department
	if ($_.Department -eq "") 
	  {$Department = "update"} 
	else 
	  {$Department = $_.Department }
$Mobile = $_.Mobile
	if ($_.Mobile -eq "") 
	  {$Mobile = "update"} 
	else 
	  {$Mobile = $_.Mobile }
Set-ADUSer $user -Description $Description -Title $Title -OfficePhone $TelephoneNumber -MobilePhone $Mobile -department $Department -Manager $manager }
