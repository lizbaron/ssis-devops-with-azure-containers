# ssis-devops-with-azure-containers
Sample project to develop unit tests on Azure Container Instances for use in SSIS continuous delivery pipelines

## Build instructions

* Extract to directory with the Dockerfile
* Change to docker/mssqlssis folder
* Build using
    docker build [-t <desired_tag>] . 
## Run instructions
### Local
Provide a password for the SQL server admin ("sa") user

Sample run command:
* docker run -d --name=<container_name> -P --expose=1433 -e sa_password=<password> -e ACCEPT_EULA=Y mssqlssis
### On Azure
1. Save the docker image to an Azure Container Registry
1. Use Azure Container Instances to start a new Container
	1. Must choose a Windows Container Type
	1. Minimum 1 cpu
	1. Minimum 4 memoryInGB
1. Restore AdventureWorks database to AdventureWorks_src and AdventureWorks_tgt
1. Deploy your SSIS project and unit test database
1. Apply tsqlt dacpac to AdventureWorks_src, AdventureWorks_tgt, and the unit test database

## References:
* Original mssql Dockerfile and scripts as supported by Microsoft - https://github.com/Microsoft/mssql-docker/tree/master/windows/mssql-server-windows
* Enable CLR integration - https://docs.microsoft.com/en-us/sql/relational-databases/clr-integration/clr-integration-enabling?view=sql-server-2017
* Disable CLR Strict Security on SQL Server 2017 - https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/clr-strict-security?view=sql-server-2017
* Deploy SSIS project with PowerShell - https://docs.microsoft.com/en-us/sql/integration-services/ssis-quickstart-deploy-powershell?view=sql-server-2017
* PowerShell command line help - https://docs.microsoft.com/en-us/powershell/scripting/core-powershell/console/powershell.exe-command-line-help?view=powershell-6
* Running SSIS packages - https://docs.microsoft.com/en-us/sql/integration-services/ssis-quickstart-run-powershell?view=sql-server-2017
* Monitoring SSIS package run - https://docs.microsoft.com/en-us/sql/integration-services/performance/monitor-running-packages-and-other-operations?view=sql-server-2017

