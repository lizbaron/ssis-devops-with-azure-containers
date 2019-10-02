Function DeployDacpacs{
Param ($db, $DbName, $Vars)	
	&"c:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe" /Action:Publish /SourceFile:$db.dacpac $Vars /TargetDatabaseName:$DbName /TargetServerName:localhost 
        & sqlcmd -d $DbName -Q "EXEC sp_changedbowner 'sa'" 
}

gci env:

## deploy dacpacs
echo "Deploying TSQLT"
$dacPacList= @{ods_wdods = 'WDODS'; ods_jsods_csddl = 'JSODS'; oltp_digix = 'DIGIX'; oltp_redwood = 'REDWOOD'; ods_tfactods_csddl='TFACTODS'}
foreach ($db in $dacPacList.keys) { 
	DeployDacpacs $db $dacPacList.$db ""
	echo "Deploying TSQLT"
	DeployDacpacs TSQLT $dacPacList.$db ""
}

DeployDacpacs TSQLT EDW ""

&"c:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe" /Action:Publish /SourceFile:ods_integrations_hub.dacpac /Variables:REDWOOD=REDWOOD /Variables:TFACTODS=TFACTODS /Variables:WDODS=WDODS /Variables:JSODS=JSODS /Variables:DIGIX=DIGIX /Variables:EDW=EDW /TargetDatabaseName:INTEGRATIONS_HUB /TargetServerName:localhost 
& sqlcmd -d INTEGRATIONS_HUB -Q "EXEC sp_changedbowner 'sa'" 

echo "Deploying TSQLT"
DeployDacpacs TSQLT INTEGRATIONS_HUB ""