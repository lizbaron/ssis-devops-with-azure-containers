param(
[Parameter(Mandatory=$True)]
[string]$sa_password
)

if($null -ne $sa_password -And $sa_password -ne "") {
	Write-Verbose "Changing SA login credentials"
	$sqlcmd = "ALTER LOGIN sa with password=$sa_password,CHECK_POLICY=OFF,CHECK_EXPIRATION=OFF" + ";ALTER LOGIN sa ENABLE;"
	& sqlcmd -Q $sqlcmd
}