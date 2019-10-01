Write-Verbose "Enable CLR Integration."
$enableCLRsqlcmd = "C:\SSIS_SCRIPTS\enable_clr_integration.sql"
& sqlcmd -i $enableCLRsqlcmd

Write-Verbose "Create SSIS Catalog."
$create_SSIS_Catalog_Script= "C:\SSIS_SCRIPTS\create_ssis_catalog.ps1"
&$create_SSIS_Catalog_Script