# script to deploy ssis ispac file and run the file

param(
	[string]$ProjectFilePath,
	[string]$ProjectName,
	[String[]]$PackageNames
)

# Load the IntegrationServices Assembly  
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices")  

# Store the IntegrationServices Assembly namespace to avoid typing it every time  
$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"  

Write-Host "Connecting to server ..."  

# Create a connection to the server  
$sqlConnectionString = "Data Source=localhost;Initial Catalog=master;Integrated Security=SSPI;"  
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

Write-Host "connection string: "+$sqlConnectionString 
Write-Host "connection: "+$sqlConnection 

# Create the Integration Services object  
$integrationServices = New-Object $ISNamespace".IntegrationServices" $sqlConnection

Write-Host "IntegrationServices object: "+$integrationServices 

# Get the Integration Services catalog
$catalog = $integrationServices.Catalogs["SSISDB"]
Write-Host "Catalog: " +$catalog


# wait till catalog is available

while ($true){
    # Get the Integration Services catalog
    $catalog = $integrationServices.Catalogs["SSISDB"]
    if(!$catalog){
        Write-Verbose "Waiting for create SSISDB Catalog to complete."
        Start-Sleep -Seconds 5        
    }
    else {
        break
        Write-Verbose "SSIS Catalog is available."
    }
}

$TargetFolderName = "ProjectFolder"

# Create the target folder
$folder = New-Object $ISNamespace".CatalogFolder" ($catalog, $TargetFolderName, "Folder description")
$folder.Create()

Write-Host "Folder: " + $folder
Write-Host "PackageNames " $PackageNames "  ..."

# Read the project file and deploy it
[byte[]] $projectFile = [System.IO.File]::ReadAllBytes($ProjectFilePath)

# Get the project
$project = $folder.Projects[$ProjectName]

Write-Host "Project object " $project "..."

$packageArr=[System.Collections.ArrayList]@()

if($PackageNames){

    $packageArr = $PackageNames -split ','

}

else{

    Write-Host "Running all packages in project ..."
    ## Get the package names in the array
    Foreach ($pkg in $project.Packages){
        $packageArr.Add($pkg.Name);
    }   

}

Foreach ($p in $packageArr)
{
	# Get the package
    $package = $project.Packages[$p]
    Write-Host "Running " $p "..."
    Write-Host "Skipping Running " $p "..."
    $result = $package.Execute("false", $null)
    
	Write-Host "SSIS package run result ... " $result
    Write-Host "SSIS package run result type ... " $result.GetType().fullname
    Write-Host "SSIS package type ... " $package.GetType().fullname  
}

Write-Host "Print any errors encountered in running packages "

while($true){
    $catalogExecutionCount = $catalog.Executions.Count
    Write-Verbose "Catalog Execution count ... $catalogExecutionCount" 
    
    if($catalogExecutionCount > 0){
        Write-Verbose "Catalog packages execution is complete " 
        break;
    }
    else{
        Write-Verbose "Wait until catalog packages execution is complete"
        Start-Sleep -Seconds 5 
    }

}

$catalog.Operations.Refresh();
$catalog.Executions.Refresh();

Foreach ($op in $catalog.Operations)
{
    $op.Refresh();
    foreach ($msg in $op.Messages)
    {
        Write-Host "SSIS package execution result ... " $msg.Message;
    }
}

$printPackagesExecuted="SELECT count(*) FROM [SSISDB].[internal].[execution_info]"

& sqlcmd -j -m-1 -Q $printPackagesExecuted -o packageExecLogs.txt
Get-Content packageExecLogs.txt

$printPackageRunErrors="select * from [SSISDB].[catalog].[operation_messages]"
$printEventMessages = "select * FROM [SSISDB].[catalog].[event_messages]"

& sqlcmd -j -m-1 -Q $printPackageRunErrors -o packageRunErr.txt
& sqlcmd -j -m-1 -Q $printEventMessages -o eventMessages.txt

Get-Content packageRunErr.txt
Get-Content eventMessages.txt

Write-Host "Done."