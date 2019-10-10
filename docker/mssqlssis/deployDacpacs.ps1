param(
[Parameter(Mandatory=$True)]
[string]$sa_password
)


Function DeployDacpacs{
Param ($db, $DbName, $Vars)	
	&"c:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe" /Action:Publish /SourceFile:$db.dacpac $Vars /TargetDatabaseName:$DbName /TargetServerName:localhost 
        & sqlcmd -d $DbName -Q "EXEC sp_changedbowner 'sa'" 
}

gci env:

echo "password: " +$sa_password

## deploy adventure works
# & sqlcmd -d master -Q "RESTORE DATABASE AdventureworksSrc FROM DISK = 'C:\ADVENTURE_WORKS.bak'"
# & sqlcmd -d master -Q "RESTORE DATABASE AdventureworksTgt FROM DISK = 'C:\ADVENTURE_WORKS.bak'"

& sqlcmd -d master -q "USE [master]; RESTORE DATABASE AdventureWorksSrc FROM disk='C:\ADVENTURE_WORKS.bak' WITH MOVE 'AdventureWorks_data' TO 'C:\AdventureWorks.mdf', MOVE 'AdventureWorks_Log' TO 'C:\AdventureWorks.ldf',REPLACE"

echo "Deploying TSQLT"

DeployDacpacs TSQLT AdventureworksSrc ""
DeployDacpacs TSQLT AdventureworksTgt ""

& sqlcmd -d AdventureworksSrc -Q "EXEC sp_changedbowner 'sa'" 
& sqlcmd -d AdventureworksTgt -Q "EXEC sp_changedbowner 'sa'" 
