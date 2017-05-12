#Loads glpi csv and creates export with specific filters
Set-Location c:\users\%username%\downloads
Import-Csv glpi.csv -delimiter ";" | select 'Last update', Requester, Title 
Import-Csv glpi.csv -delimiter ";" | select 'Last update', Requester, Title | Export-csv glpi1.csv -notypeinformation
