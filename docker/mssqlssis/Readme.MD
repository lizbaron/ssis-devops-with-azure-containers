Build instructions

* Extract to directory with the docker file
* Build using
    docker build [-t <desired_tag>] . 
	
Run instructions
* Provide a password for the SQL server admin ("sa") user

* Sample run command:
* docker run -d --name=<container_name> -P --expose=1433 -e sa_password=<password> -e ACCEPT_EULA=Y mssqlssis
