#Uses psexec to enable powwrshell remoting on a list of computers
psexec.exe "@C:\scripts\serverlist.txt" -u vion\administrator -p "" -h -d powershell.exe "enable-psremoting -force
