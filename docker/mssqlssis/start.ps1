# The script sets the sa password and start the SQL Service
# Also it attaches additional database from the disk
# The format for attach_dbs

param(
[Parameter(Mandatory=$false)]
[string]$sa_password,

[Parameter(Mandatory=$false)]
[string]$ACCEPT_EULA,

[Parameter(Mandatory=$false)]
[string]$attach_dbs,

[Parameter(Mandatory=$false)]
[string]$sqlsrvrlogin
)


if($ACCEPT_EULA -ne "Y" -And $ACCEPT_EULA -ne "y")
{
	Write-Verbose "ERROR: You must accept the End User License Agreement before this container can start."
	Write-Verbose "Set the environment variable ACCEPT_EULA to 'Y' if you accept the agreement."

    exit 1
}

# start the service
Write-Verbose "Starting SQL Server"
start-service MSSQLSERVER

$attach_dbs_cleaned = $attach_dbs.TrimStart('\\').TrimEnd('\\')

$dbs = $attach_dbs_cleaned | ConvertFrom-Json

if ($null -ne $dbs -And $dbs.Length -gt 0)
{
    Write-Verbose "Attaching $($dbs.Length) database(s)"
	    
    Foreach($db in $dbs) 
    {            
        $files = @();
        Foreach($file in $db.dbFiles)
        {
            $files += "(FILENAME = N'$($file)')";           
        }

        $files = $files -join ","
        $sqlcmd = "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '" + $($db.dbName) + "') BEGIN EXEC sp_detach_db [$($db.dbName)] END;CREATE DATABASE [$($db.dbName)] ON $($files) FOR ATTACH;"

        Write-Verbose "Invoke-Sqlcmd -Query $($sqlcmd)"
        & sqlcmd -Q $sqlcmd
	}
}

Write-Verbose "Started SQL Server."

Write-Verbose "Create login for sqlsrvrlogin account."

$createLogin="CREATE LOGIN  [" + $env:USERDOMAIN + "\"+ $sqlsrvrlogin +"] FROM WINDOWS"
Write-Verbose "Create login command: $createLogin" 
& sqlcmd -j -m-1 -Q $createLogin

Write-Verbose "Providing sysadmin permissions to sqlsrvrlogin account."

$enableSysAdminPermissions="sp_addsrvRolemember [" + $env:USERDOMAIN + "\"+ $sqlsrvrlogin +"], 'sysadmin'"
Write-Verbose "Enablee Sys admin permissions command: $enableSysAdminPermissions" 
& sqlcmd -j -m-1 -Q $enableSysAdminPermissions


$lastCheck = (Get-Date).AddSeconds(-2) 
while ($true) 
{ 
    Get-EventLog -LogName Application -Source "MSSQL*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message	 
    $lastCheck = Get-Date 
    Start-Sleep -Seconds 2 
}