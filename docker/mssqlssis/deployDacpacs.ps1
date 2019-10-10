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

## deploy adventure works

# & sqlcmd -d master -q "RESTORE FILELISTONLY FROM DISK = 'C:\ADVENTURE_WORKS.bak' WITH FILE = 1"
# AdventureWorks2017
# AdventureWorks2017_log

& sqlcmd -d master -q "USE [master]; RESTORE DATABASE AdventureWorksSrc FROM disk='C:\ADVENTURE_WORKS.bak' WITH MOVE 'AdventureWorks2017' TO 'C:\AdventureWorks2017Src.mdf', MOVE 'AdventureWorks2017_log' TO 'C:\AdventureWorks2017Src_log.ldf',REPLACE"
& sqlcmd -d master -q "USE [master]; RESTORE DATABASE AdventureWorksTgt FROM disk='C:\ADVENTURE_WORKS.bak' WITH MOVE 'AdventureWorks2017' TO 'C:\AdventureWorks2017Tgt.mdf', MOVE 'AdventureWorks2017_log' TO 'C:\AdventureWorks2017Tgt_log.ldf',REPLACE"

echo "Deploying TSQLT"

DeployDacpacs TSQLT AdventureworksSrc ""
DeployDacpacs TSQLT AdventureworksTgt ""

& sqlcmd -d AdventureworksSrc -Q "EXEC sp_changedbowner 'sa'" 
& sqlcmd -d AdventureworksTgt -Q "EXEC sp_changedbowner 'sa'" 
