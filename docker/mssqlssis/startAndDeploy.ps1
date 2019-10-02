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

if($sa_password -eq "_") {
    if (Test-Path $env:sa_password_path) {
        $sa_password = Get-Content -Raw $secretPath
    }
    else {
        Write-Verbose "WARN: Using default SA password, secret file not found at: $secretPath"
    }
}

if($sa_password -ne "_")
{
    Write-Verbose "Changing SA login credentials"
    $sqlcmd = "ALTER LOGIN sa with password=" +"'" + $sa_password + "' ,CHECK_POLICY=OFF,CHECK_EXPIRATION=OFF" + ";ALTER LOGIN sa ENABLE;"
    & sqlcmd -Q $sqlcmd
}

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

Write-Verbose "Enable CLR Integration."
$enableCLRsqlcmd = "C:\SSIS_SCRIPTS\enable_clr_integration.sql"
& sqlcmd -i $enableCLRsqlcmd

Write-Verbose "Create SSIS Catalog."
$create_SSIS_Catalog_Script= "C:\SSIS_SCRIPTS\create_ssis_catalog.ps1"
&$create_SSIS_Catalog_Script

$targetDir="C:\SSIS_ISPACS"

if( -Not (Test-Path -Path $targetDir ) )
{
    New-Item -ItemType directory -Path $targetDir
    Write-Host "Folder created: " + $targetDir
}
else{
    Write-Host "$targetDir Folder exists: "
}

Function DeployDacpacs{
Param ($db, $DbName, $Vars)	
	&"c:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe" /Action:Publish /SourceFile:$db.dacpac $Vars /TargetDatabaseName:$DbName /TargetServerName:localhost  
}

## deploy dacpacs
$dacPacList= @{ods_wdods = 'WDODS'; ods_jsods_csddl = 'JSODS'; oltp_digix = 'DIGIX'; oltp_redwood = 'REDWOOD'; ods_tfactods_csddl='TFACTODS'}
foreach ($db in $dacPacList.keys) { 
	DeployDacpacs $db $dacPacList.$db ""
	echo "Deploying TSQLT"
	DeployDacpacs TSQLT $dacPacList.$db ""
}

echo "Deploying EDW"

&"c:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe" /Action:Publish /SourceFile:ods_edw.dacpac /Variables:TFACTODS=TFACTODS /TargetDatabaseName:EDW /TargetServerName:localhost  

echo "Deploying TSQLT"
DeployDacpacs TSQLT EDW ""

# $integrationsHubVars = " /Variables:REDWOOD=REDWOOD /Variables:TFACTODS=TFACTODS /Variables:WDODS=WDODS /Variables:JSODS=JSODS /Variables:DIGIX=DIGIX /Variables:EDW=EDW"
&"c:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe" /Action:Publish /SourceFile:ods_integrations_hub.dacpac /Variables:REDWOOD=REDWOOD /Variables:TFACTODS=TFACTODS /Variables:WDODS=WDODS /Variables:JSODS=JSODS /Variables:DIGIX=DIGIX /Variables:EDW=EDW /TargetDatabaseName:INTEGRATIONS_HUB /TargetServerName:localhost  

echo "Deploying TSQLT"
DeployDacpacs TSQLT INTEGRATIONS_HUB ""