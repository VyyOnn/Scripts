'*****************************************
'* Script Usage: Get Windows Product Key *
'* http://www.intelliadmin.com           *
'* Revision 8/15/2012                    *
'*****************************************

'Constants for our registry query
const HKEY_LOCAL_MACHINE = &H80000002 
sRegistryKeyName = "SOFTWARE\Microsoft\Windows NT\CurrentVersion"
sRegistryValueName = "DigitalProductId"

function GetProductKey
	'Get the raw product key data 
	dim pValues()
	Set poRegistry=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
	poRegistry.GetBinaryValue HKEY_LOCAL_MACHINE,sRegistryKeyName,sRegistryValueName,pValues

	Dim sArrayPID
	sArrayPID = Array()

	'In that data, positions 52-66 contain our product id info
	'We copy to an array so we can decrypt

	For i = 52 to 66
		'Increase our array size by one
		ReDim Preserve sArrayPID( UBound(sArrayPID) + 1 )
		'Insert our value into the end if the array
		sArrayPID(UBound(sArrayPID)) = pValues(i)
	Next

	'Consants for our product key
	Dim sProductKeyChars
	sProductKeyChars = Array("B","C","D","F","G","H","J","K","M","P","Q","R","T","V","W","X","Y","2","3","4","6","7","8","9")

	For i = 24 To 0 Step -1
		k = 0
		For j = 14 To 0 Step -1
			k = k * 256 Xor sArrayPID(j)
			sArrayPID(j) = Int(k / 24)
			k = k Mod 24
		Next
		sProductKey = sProductKeyChars(k) & sProductKey
		'Adds the - between the key sections
		if i Mod 5 = 0 And i <> 0 Then sProductKey = "-" & sProductKey
	Next
	GetProductKey = sProductKey
end function

function GetOSVersion
	Set SystemSet = GetObject("winmgmts:").InstancesOf ("Win32_OperatingSystem") 
	for each System in SystemSet 
		GetOSVersion = Trim(System.Caption) & " (" & System.Version & ")"
	next 
end function 

wscript.echo GetOSVersion & ", " & GetProductKey
