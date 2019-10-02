Function DeployDacpacs{
Param ($db, $DbName, $Vars)	
	&"c:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe" /Action:Publish /SourceFile:$db.dacpac $Vars /TargetDatabaseName:$DbName /TargetServerName:localhost 
        & sqlcmd -d $DbName -Q "EXEC sp_changedbowner 'sa'" 
}

gci env:

## deploy adventure works
& sqlcmd RESTORE DATABASE AdventureworksSrc FROM DISK = 'ADVENTURE_WORKS.bak'
& sqlcmd RESTORE DATABASE AdventureworksTgt FROM DISK = 'ADVENTURE_WORKS.bak'

echo "Deploying TSQLT"

DeployDacpacs TSQLT AdventureworksSrc ""
DeployDacpacs TSQLT AdventureworksTgt ""

& sqlcmd -d AdventureworksSrc -Q "EXEC sp_changedbowner 'sa'" 
& sqlcmd -d AdventureworksTgt -Q "EXEC sp_changedbowner 'sa'" 