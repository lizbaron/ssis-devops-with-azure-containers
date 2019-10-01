Function DeployDacpacs{
Param ($db, $DbName, $Vars)	
	&"c:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe" /Action:Publish /SourceFile:$db.dacpac $Vars /TargetDatabaseName:$DbName /TargetServerName:localhost 
       #/TargetUser:sa /TargetPassword:Welcome1
        & sqlcmd -d $DbName -Q "EXEC sp_changedbowner 'sa'" 
}

gci env:

## deploy dacpacs
$dacPacList= @{ods_wdods = 'WDODS'; ods_jsods_csddl = 'JSODS'; oltp_digix = 'DIGIX'; oltp_redwood = 'REDWOOD'; ods_tfactods_csddl='TFACTODS'}
foreach ($db in $dacPacList.keys) { 
	DeployDacpacs $db $dacPacList.$db ""
	echo "Deploying TSQLT"
	DeployDacpacs TSQLT $dacPacList.$db ""
}

echo "Deploying EDW"

&"c:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe" /Action:Publish /SourceFile:ods_edw.dacpac /Variables:TFACTODS=TFACTODS /TargetDatabaseName:EDW /TargetServerName:localhost 
#/TargetUser:sa /TargetPassword:Welcome1
& sqlcmd -d EDW -Q "EXEC sp_changedbowner 'sa'" 

echo "Deploying TSQLT"
DeployDacpacs TSQLT EDW ""

# $integrationsHubVars = " /Variables:REDWOOD=REDWOOD /Variables:TFACTODS=TFACTODS /Variables:WDODS=WDODS /Variables:JSODS=JSODS /Variables:DIGIX=DIGIX /Variables:EDW=EDW"
&"c:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe" /Action:Publish /SourceFile:ods_integrations_hub.dacpac /Variables:REDWOOD=REDWOOD /Variables:TFACTODS=TFACTODS /Variables:WDODS=WDODS /Variables:JSODS=JSODS /Variables:DIGIX=DIGIX /Variables:EDW=EDW /TargetDatabaseName:INTEGRATIONS_HUB /TargetServerName:localhost 
#/TargetUser:sa /TargetPassword:Welcome1  
& sqlcmd -d INTEGRATIONS_HUB -Q "EXEC sp_changedbowner 'sa'" 

echo "Deploying TSQLT"
DeployDacpacs TSQLT INTEGRATIONS_HUB ""