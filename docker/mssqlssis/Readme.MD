Build instructions

* Extract to directory with the docker file
* Build using
    docker build [-t <desired_tag>] . 
	
Run instructions
* Provide a password for the SQL server admin ("sa") user

* Sample run command:
* docker run -d --name=<container_name> -P --expose=1433 -e sa_password=<password> -e ACCEPT_EULA=Y mssqlssis


References:
Enable CLR integration - https://docs.microsoft.com/en-us/sql/relational-databases/clr-integration/clr-integration-enabling?view=sql-server-2017
Deploy SSIS project with PowerShell - https://docs.microsoft.com/en-us/sql/integration-services/ssis-quickstart-deploy-powershell?view=sql-server-2017
PowerShell command line help - https://docs.microsoft.com/en-us/powershell/scripting/core-powershell/console/powershell.exe-command-line-help?view=powershell-6
Running SSIS packages - https://docs.microsoft.com/en-us/sql/integration-services/ssis-quickstart-run-powershell?view=sql-server-2017
Monitoring SSIS package run - https://docs.microsoft.com/en-us/sql/integration-services/performance/monitor-running-packages-and-other-operations?view=sql-server-2017
