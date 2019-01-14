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

$TargetFolderName = "TestProjectFolder"

# Create the target folder
$folder = New-Object $ISNamespace".CatalogFolder" ($catalog, $TargetFolderName, "Folder description")
$folder.Create()

Write-Host "Folder: " + $folder
Write-Host "Deploying " $ProjectName " project ..."
Write-Host "From " $ProjectFilePath " project file path..."

# Read the project file and deploy it
[byte[]] $projectFile = [System.IO.File]::ReadAllBytes($ProjectFilePath)
$folder.DeployProject($ProjectName, $projectFile)

# Get the project
$project = $folder.Projects[$ProjectName]

Write-Host "Project deployment complete... " $project "..."

Write-Host "Done."