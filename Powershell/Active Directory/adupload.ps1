#this script will set the properties of the user's as determined by a csv 

Import-Module activedirectory
$usercsv = Import-CSV c:\scripts\adusers6816.csv


$usercsv| % {
$user = Get-ADUser -properties samaccountname -f "samaccountname -eq '$($_.samaccountname)'" 
$Name = $_.Name
$surname = $_.surName
$givenname = $_.givenName
$displayname = $_.displayName
$employeeID = $_.employeeID
$description = $_.description
$department = $_.department
$manager = $_.manager
$email = $_.email
$title = $_.title
$office = $_.office

Set-ADUSer $user -surname $surname -givenname $givenname -display $displayname -employeeID $employeeID -Description $Description -office $office -department $Department -title $title -manager $manager -email $email}
