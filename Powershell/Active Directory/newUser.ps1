#This script will create a new user

Import-Module activedirectory

#OU Path

$path = "OU Path here"

####General####

#First name (Given Name)
$fName = "Test"

#Last name (Surname)
$lName = "User"

#Password
$password = Read-Host -Prompt "Enter the user's password" -AsSecureString

#Display Name
$dName = "Test User"

#Description
$description = "Test" 

#Office
$office = "None"

#Phone Number
$phone = "0000"

####Account####

#SamAccountName 
$samName = "tuser"

#Password Expire


####Profile####

#Home directory
$homeDirectory = ""

####Organization####

#Company
$company = "ViON"

#Manager
$manager = "" #need full path for manager


####Member Of####

#Groups
$memberOf = ""

########Creating the new User########

 New-ADUser `
            -GivenName $fName `
            -Surname $lName `
            -Name "$fName $lName" `
            -Description $description `
            -Office $office `
            -UserPrincipalName "$samName@vion.com" `
            -SamAccountName $samName `
            -HomeDirectory $homeDirectory `
            -Company $company `
            -Manager $manager `
            -AccountPassword $password `
            -WhatIf
           


