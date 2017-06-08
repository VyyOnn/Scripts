$computer = $env:COMPUTERNAME
$myPath = "C:\Powershell\Scripts\" #where to save the file

    if((Test-Path $myPath ) -eq $false)
        {
            New-Item -ItemType Directory -Path $myPath}

Function Get-HostUptime {
    $computer = $env:COMPUTERNAME
    $Uptime = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer
    $LastBootUpTime = $Uptime.ConvertToDateTime($Uptime.LastBootUpTime)
    $Time = (Get-Date) - $LastBootUpTime
    Return '{0:00} Days, {1:00} Hours, {2:00} Minutes, {3:00} Seconds' -f $Time.Days, $Time.Hours, $Time.Minutes, $Time.Seconds
}

$uptime = Get-HostUptime

            
New-HTMLReportOptions -SaveOptionsPath $myPath

$ourLogo = Get-HTMLLogos -LogoPath 'C:\Powershell\Pictures\vion logo.png' #if you wanted to store the logo as a variable
$process = Get-Process | select -First 5

$os = Get-WmiObject -Class Win32_OperatingSystem -computername $computer | Select-Object Name #doesn't work very well, bc the output will be in the form @{....}


$product = Get-WmiObject win32_operatingSystem -ComputerName $computer 
if ($product.producttype -eq 1) #will have to shorten this to one if statement
{ 
    $product = "Workstation"
} elseif ($product.producttype -eq 2)
{
    $product = "Domain Controller" 
    }
    elseif ($product.producttype -eq 3)
    {
    $product = "Server"
    }


$report = @()
$reportBody = @()
$DiskInfo = @()

$report += Get-HTMLOpenPage -TitleText "System Report for $computer" -LeftLogoString 'C:\Powershell\Pictures\vion logo.png'

$reportBody += Get-HTMLColumn1of2
    $reportBody += Get-HTMLContentOpen -HeaderText "General Information" 
        $reportBody += Get-HTMLContentText -Heading "OS" -Detail (Get-WmiObject win32_operatingsystem -ComputerName $computer).caption
        $reportBody += Get-HTMLContentText -Heading "Serial Number" -Detail (Get-WmiObject win32_bios -ComputerName $computer ).serialnumber
        $reportBody += Get-HTMLContentText -Heading "Workstation Type" -Detail $product
        $reportBody += Get-HTMLContentText -Heading "Uptime" -Detail $uptime #not very neat
        $reportBody += Get-HTMLContentText -Heading "IP Address" -Detail ((ipconfig | findstr [0-9].\.)[0]).Split()[-1]
    $reportBody += Get-HTMLContentClose
$reportBody += Get-HTMLColumnClose


$reportBody += Get-HTMLColumn2of2
    $reportBody += Get-HTMLContentOpen -HeaderText "Event Logs"
        $reportBody += Get-HTMLContentTable
		    $ReportBody += Get-HtmlContentOpen -HeaderText "System Event Log" -IsHidden
				$ReportBody += Get-HtmlContentTable (Get-EventLog -LogName System | select eventid, message, source -Last 5) 
			$ReportBody += Get-HTMLContentClose
            $ReportBody += Get-HtmlContentOpen -HeaderText "Application Event Log" -IsHidden
				$ReportBody += Get-HtmlContentTable (Get-EventLog -LogName Application | select eventid, message, source -Last 5) 
			$ReportBody += Get-HtmlContentClose
$reportBody += Get-HTMLColumnClose

$DiskInfo= Get-WMIObject -ComputerName $computer Win32_LogicalDisk | Where-Object{$_.DriveType -eq 3} | Select-Object SystemName, DriveType, VolumeName, Name, @{n='Size (GB)';e={"{0:n2}" -f ($_.size/1gb)}}, @{n='FreeSpace (GB)';e={"{0:n2}" -f ($_.freespace/1gb)}}, @{n='PercentFree';e={"{0:n2}" -f ($_.freespace/$_.size*100)}} #| ConvertTo-HTML -fragment
$SystemInfo = (Get-WmiObject -Class Win32_OperatingSystem -computername $computer | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory)
$TotalRAM = ($SystemInfo.TotalVisibleMemorySize/1MB)
$FreeRAM =($SystemInfo.FreePhysicalMemory/1MB)
$UsedRAM =($TotalRAM - $FreeRAM)
$RAMPercentFree = ($FreeRAM / $TotalRAM) * 100


$reportBody += Get-HTMLContentOpen -HeaderText "Disk Space" -BackgroundShade 3
    $reportBody += Get-HTMLColumn1of2 
			$PieChartObject = Get-HTMLPieChartObject      
			$PieChartObject.Title = "Disk Space"
			$PieChartObject.Size.Width = 300
			$PieChartObject.Size.Height = 300
			$DiskSpace = @();$DiskSpaceRecord = '' | select Name, Count
			$DiskSpaceRecord.Count = $DiskInfo.'FreeSpace (GB)';$DiskSpaceRecord.Name = "Free (GB)"
			$DiskSpace += $DiskSpaceRecord;$DiskSpaceRecord = '' | select Name, Count
			$DiskSpaceRecord.Count = $DiskInfo.'Size (GB)' -  $DiskInfo.'FreeSpace (GB)';$DiskSpaceRecord.Name = "Used (GB)"
			$DiskSpace += $DiskSpaceRecord
			$reportBody += Get-HTMLPieChart -ChartObject $PieChartObject -DataSet ($DiskSpace)
            $reportBody += Get-HTMLColumnClose		
	$reportBody += Get-HtmlContentClose
$reportBody += Get-HTMLClosePage



$report += $reportBody
$report += Get-HTMLClosePage


Save-HTMLReport -ReportContent $report -ShowReport