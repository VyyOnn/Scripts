#######################################################################################################################
# This file will be removed when PowerCLI is uninstalled. To make your own scripts run when PowerCLI starts, create a
# file named "Initialize-PowerCLIEnvironment_Custom.ps1" in the same directory as this file, and place your scripts in
# it. The "Initialize-PowerCLIEnvironment_Custom.ps1" is not automatically deleted when PowerCLI is uninstalled.
#######################################################################################################################

$productName = "vSphere PowerCLI"
$productShortName = "PowerCLI"
$version = Get-PowerCLIVersion
$windowTitle = "VMware $productName {0}.{1}" -f $version.Major, $version.Minor
$host.ui.RawUI.WindowTitle = "$windowTitle"
$CustomInitScriptName = "Initialize-PowerCLIEnvironment_Custom.ps1"
$currentDir = Split-Path $MyInvocation.MyCommand.Path
$CustomInitScript = Join-Path $currentDir $CustomInitScriptName

#returns the version of Powershell
# Note: When using, make sure to surround Get-PSVersion with parentheses to force value comparison
function Get-PSVersion { 
    if (test-path variable:psversiontable) {
		$psversiontable.psversion
	} else {
		[version]"1.0.0.0"
	} 
}

# Returns the path (with trailing backslash) to the directory where PowerCLI is installed.
function Get-InstallPath {
   $regKeys = Get-ItemProperty "hklm:\software\VMware, Inc.\VMware vSphere PowerCLI" -ErrorAction SilentlyContinue
   
   #64bit os fix
   if($regKeys -eq $null){
      $regKeys = Get-ItemProperty "hklm:\software\wow6432node\VMware, Inc.\VMware vSphere PowerCLI"  -ErrorAction SilentlyContinue
   }

   return $regKeys.InstallPath
}

# Loads additional snapins and their init scripts
function LoadSnapins(){
   $snapinList = @( "VMware.VimAutomation.Core", "VMware.VimAutomation.Vds", "VMware.VimAutomation.License", "VMware.DeployAutomation", "VMware.ImageBuilder", "VMware.VimAutomation.Cloud")

   $loaded = Get-PSSnapin -Name $snapinList -ErrorAction SilentlyContinue | % {$_.Name}
   $registered = Get-PSSnapin -Name $snapinList -Registered -ErrorAction SilentlyContinue  | % {$_.Name}
   $notLoaded = $registered | ? {$loaded -notcontains $_}
   
   foreach ($snapin in $registered) {
      if ($loaded -notcontains $snapin) {
         Add-PSSnapin $snapin
      }

      # Load the Intitialize-<snapin_name_with_underscores>.ps1 file
      # File lookup is based on install path instead of script folder because the PowerCLI
      # shortuts load this script through dot-sourcing and script path is not available.
      $filePath = "{0}Scripts\Initialize-{1}.ps1" -f (Get-InstallPath), $snapin.ToString().Replace(".", "_")
      if (Test-Path $filePath) {
         & $filePath
      }
   }
}
LoadSnapins

# Update PowerCLI version after snap-in load
$version = Get-PowerCLIVersion
$windowTitle = "VMware $productName {0}.{1} Release 1" -f $version.Major, $version.Minor
$host.ui.RawUI.WindowTitle = "$windowTitle"

function global:Get-VICommand([string] $Name = "*") {
  get-command -pssnapin VMware.* -Name $Name
}

function global:Get-LicensingCommand([string] $Name = "*") {
  get-command -pssnapin VMware.VimAutomation.License -Name $Name
}

function global:Get-ImageBuilderCommand([string] $Name = "*") {
  get-command -pssnapin VMware.ImageBuilder -Name $Name
}

function global:Get-AutoDeployCommand([string] $Name = "*") {
  get-command -pssnapin VMware.DeployAutomation -Name $Name
}

# Launch text
write-host "          Welcome to the VMware $productName!"
write-host ""
write-host "Log in to a vCenter Server or ESX host:              " -NoNewLine
write-host "Connect-VIServer" -foregroundcolor yellow
write-host "To find out what commands are available, type:       " -NoNewLine
write-host "Get-VICommand" -foregroundcolor yellow
write-host "To show searchable help for all PowerCLI commands:   " -NoNewLine
write-host "Get-PowerCLIHelp" -foregroundcolor yellow  
write-host "Once you've connected, display all virtual machines: " -NoNewLine
write-host "Get-VM" -foregroundcolor yellow
write-host "If you need more help, visit the PowerCLI community: " -NoNewLine
write-host "Get-PowerCLICommunity" -foregroundcolor yellow
write-host ""
write-host "       Copyright (C) 1998-2013 VMware, Inc. All rights reserved."
write-host ""
write-host ""

# Error message to update to version 2.0 of PowerShell
# Note: Make sure to surround Get-PSVersion with parentheses to force value comparison
if((Get-PSVersion) -lt "2.0"){
    $psVersion = Get-PSVersion
    Write-Error "$productShortName requires Powershell 2.0! The version of Powershell installed on this computer is $psVersion." -Category NotInstalled
}

# Modify the prompt function to change the console prompt.
# Save the previous function, to allow restoring it back.
$originalPromptFunction = $function:prompt
function global:prompt{

    # change prompt text
    Write-Host "$productShortName " -NoNewLine -foregroundcolor Green
    Write-Host ((Get-location).Path + ">") -NoNewLine
    return " "
}

# Tab Expansion for parameters of enum types.
# This functionality requires powershell 2.0
# Note: Make sure to surround Get-PSVersion with parentheses to force value comparison
if((Get-PSVersion) -eq "2.0"){

    #modify the tab expansion function to support enum parameter expansion
    $global:originalTabExpansionFunction = $function:TabExpansion

    function global:TabExpansion {
       param($line, $lastWord)
       
       $originalResult = & $global:originalTabExpansionFunction $line $lastWord
       
       if ($originalResult) {
          return $originalResult
       }
       #ignore parsing errors. if there are errors in the syntax, try anyway
       $tokens = [System.Management.Automation.PSParser]::Tokenize($line, [ref] $null)
       
       if ($tokens)
       {
           $lastToken = $tokens[$tokens.count - 1]
           
           $startsWith = ""
           
           # locate the last parameter token, which value is to be expanded
           switch($lastToken.Type){
               'CommandParameter' {
                    #... -Parameter<space>
                    
                    $paramToken = $lastToken
               }
               'CommandArgument' {
                    #if the last token is argument, that can be a partially spelled value
                    if($lastWord){
                        #... -Parameter Argument  <<< partially spelled argument, $lastWord == Argument
                        #... -Parameter Argument Argument
                        
                        $startsWith = $lastWord
                        
                        $prevToken = $tokens[$tokens.count - 2]
                        #if the argument is not preceeded by a paramter, then it is a value for a positional parameter.
                        if ($prevToken.Type -eq 'CommandParameter') {
                            $paramToken = $prevToken
                        }
                    }
                    #else handles "... -Parameter Argument<space>" and "... -Parameter Argument Argument<space>" >>> which means the argument is entirely spelled
               }
           }
           
           # if a parameter is found for the argument that is tab-expanded
           if ($paramToken) {        
               #locates the 'command' token, that this parameter belongs to
               [int]$groupLevel = 0
               for($i=$tokens.Count-1; $i -ge 0; $i--) {
                   $currentToken = $tokens[$i]
                   if ( ($currentToken.Type -eq 'Command') -and ($groupLevel -eq 0) ) {
                      $cmdletToken = $currentToken
                      break;
                   }
                   
                   if ($currentToken.Type -eq 'GroupEnd') {
                      $groupLevel += 1
                   }
                   if ($currentToken.Type -eq 'GroupStart') {
                      $groupLevel -= 1
                   }
               }
               
               if ($cmdletToken) {
                   # getting command object
                   $cmdlet = Get-Command $cmdletToken.Content
                   # gettint parameter information
                   $parameter = $cmdlet.Parameters[$paramToken.Content.Replace('-','')]
                   
                   # getting the data type of the parameter
                   $parameterType = $parameter.ParameterType
                   
                   if ($parameterType.IsEnum) {
                      # if the type is Enum then the values are the enum values
                      $values = [System.Enum]::GetValues($parameterType)
                   } elseif($parameterType.IsArray) {
                      $elementType = $parameterType.GetElementType()
                      
                      if($elementType.IsEnum) { 
                        # if the type is an array of Enum then values are the enum values
                        $values = [System.Enum]::GetValues($elementType) 
                      }
                   }
                   
                   if($values) {
                      if ($startsWith) {
                          return ($values | where { $_ -like "${startsWith}*" })
                      } else {
                          return $values
                      }
                   }
               }
           }
       } 
    }
}

# Opens documentation file
function global:Get-PowerCLIHelp{
   $ChmFilePath = Join-Path (Get-InstallPath) "VICore Documentation\$productName Cmdlets Reference.chm"
   $docProcess = [System.Diagnostics.Process]::Start($ChmFilePath)
}

# Opens toolkit community url with default browser
function global:Get-PowerCLICommunity{
    $link = "http://communities.vmware.com/community/vmtn/vsphere/automationtools/windows_toolkit"
    $browserProcess = [System.Diagnostics.Process]::Start($link)
}

# Find and execute custom initialization file
$existsCustomInitScript = Test-Path $CustomInitScript
if($existsCustomInitScript) {
   & $CustomInitScript
}
# SIG # Begin signature block
# MIIcQwYJKoZIhvcNAQcCoIIcNDCCHDACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUs0fdNmjIy6mAuEGyHxpYLfzi
# bE2gghefMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggT7MIID46ADAgECAhAMTRdzyVF+4gDoQD9qBsXCMA0GCSqGSIb3DQEBBQUAMIG2
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsT
# FlZlcmlTaWduIFRydXN0IE5ldHdvcmsxOzA5BgNVBAsTMlRlcm1zIG9mIHVzZSBh
# dCBodHRwczovL3d3dy52ZXJpc2lnbi5jb20vcnBhIChjKTA5MTAwLgYDVQQDEydW
# ZXJpU2lnbiBDbGFzcyAzIENvZGUgU2lnbmluZyAyMDA5LTIgQ0EwHhcNMTAwOTEz
# MDAwMDAwWhcNMTMxMDI4MjM1OTU5WjCBuDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# CkNhbGlmb3JuaWExEjAQBgNVBAcTCVBhbG8gQWx0bzEVMBMGA1UEChQMVk13YXJl
# LCBJbmMuMT4wPAYDVQQLEzVEaWdpdGFsIElEIENsYXNzIDMgLSBNaWNyb3NvZnQg
# U29mdHdhcmUgVmFsaWRhdGlvbiB2MjESMBAGA1UECxQJTWFya2V0aW5nMRUwEwYD
# VQQDFAxWTXdhcmUsIEluYy4wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALkt
# bJoWPbA3xZBD7NxBpVPPcbQdd7bLuvsunf8obeP6ExRnXOj42uQhFqokCatqYDN4
# 6znFWWbPH/NbbrWs1LY6M0f89Zp5AfQQq7TY+8tUwT7JDAiNi/pjL8W7RXEcb1Ud
# L+ZigSiuNEdE5RR1YqdHB8GRiEyUMZ8O8z6b0GE7AgMBAAGjggGDMIIBfzAJBgNV
# HRMEAjAAMA4GA1UdDwEB/wQEAwIHgDBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8v
# Y3NjMy0yMDA5LTItY3JsLnZlcmlzaWduLmNvbS9DU0MzLTIwMDktMi5jcmwwRAYD
# VR0gBD0wOzA5BgtghkgBhvhFAQcXAzAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3
# dy52ZXJpc2lnbi5jb20vcnBhMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHUGCCsGAQUF
# BwEBBGkwZzAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AudmVyaXNpZ24uY29tMD8G
# CCsGAQUFBzAChjNodHRwOi8vY3NjMy0yMDA5LTItYWlhLnZlcmlzaWduLmNvbS9D
# U0MzLTIwMDktMi5jZXIwHwYDVR0jBBgwFoAUl9BrqCZwyKE/lB8ILcQ1m6ShHvIw
# EQYJYIZIAYb4QgEBBAQDAgQQMBYGCisGAQQBgjcCARsECDAGAQEAAQH/MA0GCSqG
# SIb3DQEBBQUAA4IBAQCZNRsfIkXsHqwRdmxd+cjTS/rb4ZLHpUzOPxY4Dfb98eyS
# ySg1OLwBZayLTPqNeyML8W+s/3XMSLPFMdnzA0ChQqpSCjr3dFQTMICnX8aR9kRH
# srJ+/Wnp20ayrvuDr1s3SId1yDeqdsG+r+6ie3HN8c8LRfmJ3wuE0lAfQJUYL099
# UHS8ilcj3F6V2Dn67PkYFqChK2HjTjMEfGRPOyEoef4Vi/kuoKCVpD6np1pzuX/B
# jjU+wDEviS79sjkA+F2kiXk1bEtpo5GRjidrBi7l60ZRJnDz8u9zqCbV2yUflQ/Z
# Dyu0Zem3HSq2q4yYG2MB/WTdqoRCSAGZCVrZAMJyMIIE/DCCBGWgAwIBAgIQZVIm
# 4bIuGOFZDymFrCLnXDANBgkqhkiG9w0BAQUFADBfMQswCQYDVQQGEwJVUzEXMBUG
# A1UEChMOVmVyaVNpZ24sIEluYy4xNzA1BgNVBAsTLkNsYXNzIDMgUHVibGljIFBy
# aW1hcnkgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMDkwNTIxMDAwMDAwWhcN
# MTkwNTIwMjM1OTU5WjCBtjELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWdu
# LCBJbmMuMR8wHQYDVQQLExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTswOQYDVQQL
# EzJUZXJtcyBvZiB1c2UgYXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYSAo
# YykwOTEwMC4GA1UEAxMnVmVyaVNpZ24gQ2xhc3MgMyBDb2RlIFNpZ25pbmcgMjAw
# OS0yIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvmcdtGCqEElv
# Vhd8Zslehg3V8ayncYOOi4n4iASJFQa6LYQhleTRnFBM+9IivdrysjU7Ho/DCfv8
# Ey5av4l8PTslHvbzWHuc9AG1xgq4gM6+J3RhZydNauXsgWFYeaPgFxASFSew4U00
# fytHIES53mYkZorNT7ofxTjIVJDhcvYZZnVquUlozzh5DaowqNssYEie16oUAamD
# 1ziRMDkTlgM6fEBUtq3gLxuD3KgRUj4Cs9cr/SG2p1yjDwupphBQDjQuTafOyV4l
# 1Iy88258KbwBXfwxh1rVjIVnWIgZoL818OoroyHnkPaD5ajtYHhee2CD/VcLXUEN
# Y1Rg1kMh7wIDAQABo4IB2zCCAdcwEgYDVR0TAQH/BAgwBgEB/wIBADBwBgNVHSAE
# aTBnMGUGC2CGSAGG+EUBBxcDMFYwKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LnZl
# cmlzaWduLmNvbS9jcHMwKgYIKwYBBQUHAgIwHhocaHR0cHM6Ly93d3cudmVyaXNp
# Z24uY29tL3JwYTAOBgNVHQ8BAf8EBAMCAQYwbQYIKwYBBQUHAQwEYTBfoV2gWzBZ
# MFcwVRYJaW1hZ2UvZ2lmMCEwHzAHBgUrDgMCGgQUj+XTGoasjY5rw8+AatRIGCx7
# GS4wJRYjaHR0cDovL2xvZ28udmVyaXNpZ24uY29tL3ZzbG9nby5naWYwHQYDVR0l
# BBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMDMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AudmVyaXNpZ24uY29tMDEGA1UdHwQqMCgwJqAkoCKG
# IGh0dHA6Ly9jcmwudmVyaXNpZ24uY29tL3BjYTMuY3JsMCkGA1UdEQQiMCCkHjAc
# MRowGAYDVQQDExFDbGFzczNDQTIwNDgtMS01NTAdBgNVHQ4EFgQUl9BrqCZwyKE/
# lB8ILcQ1m6ShHvIwDQYJKoZIhvcNAQEFBQADgYEAiwPA3ZTYQaJhabAVqHjHMMaQ
# PH5C9yS25INzFwR/BBCcoeL6gS/rwMpE53LgULZVECCDbpaS5JpRarQ3MdylLeuM
# AMcdT+dNMrqF+E6++mdVZfBqvnrKZDgaEBB4RXYx84Z6Aw9gwrNdnfaLZnaCG1nh
# g+W9SaU4VuXeQXcOWA8wggUDMIIC66ADAgECAgphDBIGAAAAAAAbMA0GCSqGSIb3
# DQEBBQUAMH8xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAn
# BgNVBAMTIE1pY3Jvc29mdCBDb2RlIFZlcmlmaWNhdGlvbiBSb290MB4XDTA2MDUy
# MzE3MDEyOVoXDTE2MDUyMzE3MTEyOVowXzELMAkGA1UEBhMCVVMxFzAVBgNVBAoT
# DlZlcmlTaWduLCBJbmMuMTcwNQYDVQQLEy5DbGFzcyAzIFB1YmxpYyBQcmltYXJ5
# IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCB
# iQKBgQDJXFme8huKARS0EN8EQNvjV69qRUCPhAwL0TPZ2RHP7gJYHyX3KqhEBars
# Ax94f56TuZoAqiN91qyFomNFx3InzPRMxnVx0jnvT0Lwdd8KkMaOIG+YD/isI19w
# KTakyYbnsZogy1Olhec9vn2a/iRFM9x2Fe0PonFkTGUugWhFpwIDAQABo4IBIzCC
# AR8wEQYDVR0gBAowCDAGBgRVHSAAMDYGCSsGAQQBgjcVBwQpMCcGHysGAQQBgjcV
# CI3g0YlOhNecwweGpob7HI/Tv6YVARkCAW4CAQAwCwYDVR0PBAQDAgGGMA8GA1Ud
# EwEB/wQFMAMBAf8wHQYDVR0OBBYEFOJ/e9h31d+eCj+etMsOLqnv22l3MB0GCSsG
# AQQBgjcUAgQQHg4AQwByAG8AcwBzAEMAQTAfBgNVHSMEGDAWgBRi+wohW39DbhHa
# CVRQa/XSlnHxnjBVBgNVHR8ETjBMMEqgSKBGhkRodHRwOi8vY3JsLm1pY3Jvc29m
# dC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNyb3NvZnRDb2RlVmVyaWZSb290LmNy
# bDANBgkqhkiG9w0BAQUFAAOCAgEAAeRGsztFf3UTh35fQ95GjsuKvbZHQbzMzHSR
# 2M45UZWkprVHwO/S2nuPVxH0Mox8zT/uQtoEIUr3yEOISm9cyhT8S9GfTL3UVW7M
# Ar4NpoiPhgm6pCW96LDw+otxTmewy4Ko145V9zfr8D6I7+Tgiv0cbi5hQUh1tLAs
# HSjYSQ/XFfAkcyU8zIgM3ihMZVT+Xq6M6hmtLFGymzpH9TyANQEX4kmH1lRK+0ur
# B7y/fXnPvzUAXLuez/yCiRs5oFGXtt7Aswf/RJZEwDQqGVyr7vA77ClOtRPFN4V+
# ddW01g0GbrXSbCNxZ+rxcY6vTnSqDPnsv0xY+l6Qm205y4aIP4scqBYy1f5tufH4
# s+rXkfY2R3jAJyoVx2jW9MX8T07IZz8QLUCf8R7JYUjnpwP8MXMM8EaI/lbaSSmV
# 7wnao+W+72Ds2VSgWZwovVTvZhV/h0yE26YOlWcuUXs0ObZBwoyEaCbcJAIJ54GO
# Cpct7+6nuZimD4GNxxC14e2YL0hvU4VJZHib7F2slwtVJsPvuo3I0aUvWn+Ta2Ea
# M5sYuKJiEN4k6nbhL0Pr7N18EjQkidooVa7ldU4xK2djtqjXq3MKA87F6lk/x+sq
# Ra6oYlsvAJk5q7Rfc8MI7IARj0cOjyoTQ+GRBmJVu/+6PampPSYPrsp9YosVVYnW
# lDRN1mUxggQOMIIECgIBATCByzCBtjELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZl
# cmlTaWduLCBJbmMuMR8wHQYDVQQLExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTsw
# OQYDVQQLEzJUZXJtcyBvZiB1c2UgYXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29t
# L3JwYSAoYykwOTEwMC4GA1UEAxMnVmVyaVNpZ24gQ2xhc3MgMyBDb2RlIFNpZ25p
# bmcgMjAwOS0yIENBAhAMTRdzyVF+4gDoQD9qBsXCMAkGBSsOAwIaBQCggYowGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFGbnTjMDeLARp4NJMbT5ICxbKC2gMCoGCisG
# AQQBgjcCAQwxHDAaoRiAFmh0dHA6Ly93d3cudm13YXJlLmNvbS8wDQYJKoZIhvcN
# AQEBBQAEgYAQszGjlxgiO/afPiJoraH7sINS1oJSndkQiL6Y1gMF7YLzJnfWFb9X
# LgwOPl0aWw06h+v5jJfDlfMytbtKqnUC9OiJWEFOroXgYdz7YRgLvombqMmOqcX6
# /Jt/Sf839lwRzUPQSDjBA8+XWcWuJaIkOqsaT6qQrqVCmtfMErDSWaGCAgswggIH
# BgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQK
# ExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBT
# dGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsO
# AwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0xMzA4MjcwNjI0NTdaMCMGCSqGSIb3DQEJBDEWBBRLQx+6hleEEmmTc7GOvkBQ
# X1lMjzANBgkqhkiG9w0BAQEFAASCAQBoFYqjGSUie79eKJewcpB/S6pyqzOWwH3O
# nBug8BOJkfifU+RgWOq5HOnzadnNCx/4U1jfbcDAaez8lgHQmMNHG7L7vT6T9s9T
# CzuLR8Z1UFv2fJAX5dyaQQ46k5tzo3G4TwXOvHCnt7fxtCKuBZ2o6441lyofwgPQ
# H5hfVnEEVRy+4rwXkOZsHwnLbgkpiuy2H/L0O6zkH8ujtIjvJC1pDFMnWtBJwmGj
# EvScLhXJ300OhIZ84mOI9uMrDgcLUuNvPAD035kD8mbjlq7DTzELVzSvwdltoHLy
# 6rOje5MvjJ7rhVRGuIRPliJwaUMa7DwsQ9SUHXHtvSGzMLiSL0KH
# SIG # End signature block
