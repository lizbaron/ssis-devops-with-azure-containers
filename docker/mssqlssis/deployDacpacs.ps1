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

& sqlcmd -i 'C:\instawdbSrc.sql'
& sqlcmd -i 'C:\instawdbTgt.sql'

# & sqlcmd -d master -Q "RESTORE DATABASE AdventureworksSrc FROM DISK = 'C:\ADVENTURE_WORKS.bak' WITH FILE = 6"
# & sqlcmd -d master -Q "RESTORE DATABASE AdventureworksTgt FROM DISK = 'C:\ADVENTURE_WORKS.bak' WITH FILE = 6"

echo "Deploying TSQLT"

DeployDacpacs TSQLT AdventureWorksSrc ""
DeployDacpacs TSQLT AdventureWorksTgt ""

& sqlcmd -d AdventureworksSrc -Q "EXEC sp_changedbowner 'sa'" 
& sqlcmd -d AdventureworksTgt -Q "EXEC sp_changedbowner 'sa'" 