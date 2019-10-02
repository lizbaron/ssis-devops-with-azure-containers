Write-Verbose "Changing SA login credentials"
$sqlcmd = "ALTER LOGIN sa with password='Welcome1',CHECK_POLICY=OFF,CHECK_EXPIRATION=OFF" + ";ALTER LOGIN sa ENABLE;"
& sqlcmd -Q $sqlcmd