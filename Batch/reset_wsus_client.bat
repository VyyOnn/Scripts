REG Delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate /v SusClientId  /f
REG Delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate /v SusClientIdValidation  /f
REG Add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v WUServer /t REG_SZ /d http://prod-wsus /F
REG Add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v WUStatusServer /t REG_SZ /d http://prod-wsus /F

gpupdate
net stop wuauserv /y
net stop BITS /y
rd C:\WINDOWS\SoftwareDistribution /s /Q
del "c:\windows\windowsupdate.log"
net start wuauserv /y
wuauclt.exe /resetauthorization /detectnow