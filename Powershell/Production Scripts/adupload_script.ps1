$usercsv = Import-CSV c:\scripts\testul.csv
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
Set-ADUSer $user -surname $surname -givenname $givenname -display $displayname -employeeID $employeeID -Description $Description -department $Department -title $title-manager $manager -email $email}
