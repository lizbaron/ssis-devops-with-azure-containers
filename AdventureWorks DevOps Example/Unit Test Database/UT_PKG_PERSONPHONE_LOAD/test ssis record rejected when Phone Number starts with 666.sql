CREATE PROCEDURE [UT_PKG_PERSONPHONE_LOAD].[test ssis record rejected when Phone Number starts with 666]
AS
BEGIN
-- Package Details
-- Package Details
DECLARE @package_name nvarchar(200) = N'PKG_PersonPhone_load.dtsx';
DECLARE @project_name nvarchar(200) = N'AdventureWorks_Example';
DECLARE @folder_name nvarchar(200) = N'TestProjectFolder';

-- SSIS Execution Parameters
DECLARE @execution_id bigint;
DECLARE @reference_id smallint = null;

-- SSIS Catalog Variables (object_type = 50)
DECLARE @logging_level smallint = 3;
DECLARE @is_synchronized smallint = 1;

-- Project Variables (object_type = 20)
DECLARE @AW_SRC_InitialCatalog nvarchar(100) = N'AdventureWorks2017_src';
DECLARE @AW_SRC_ServerName nvarchar(100) = N'.';
DECLARE @AW_SRC_ConnectionString nvarchar(500) = N'Data Source=.;Initial Catalog=AdventureWorks2017_src;Provider=SQLNCLI11.1;Persist Security Info=False;Auto Translate=True;Integrated Security=SSPI;';
DECLARE @AW_TGT_InitialCatalog nvarchar(100) = N'AdventureWorks2017_tgt';
DECLARE @AW_TGT_ServerName nvarchar(100) = N'.';
DECLARE @AW_TGT_ConnectionString nvarchar(500) = N'Data Source=.;Initial Catalog=AdventureWorks2017_tgt;Provider=SQLNCLI11.1;Persist Security Info=False;Auto Translate=True;Integrated Security=SSPI;';

-- Package Variables (object_type = 30)

-- Test Data Constants
DECLARE @record_count AS int = 0;

-- Test Data
/* Record 1 */
DECLARE @P_BusinessEntityID_1 int = 100;
DECLARE @P_PhoneNumber_1 nvarchar(25) = '888-111-2222';
DECLARE @P_PhoneNumberTypeID_1 int = 1;
DECLARE @P_ModifiedDate_1 datetime = '2018-12-20 00:00:00';

/* Record 2 */
DECLARE @P_BusinessEntityID_2 int = 200;
DECLARE @P_PhoneNumber_2 nvarchar(25) = '889-112-2223';
DECLARE @P_PhoneNumberTypeID_2 int = 2;
DECLARE @P_ModifiedDate_2 datetime = '2018-12-21 00:00:00';

/* Record 3 */
DECLARE @P_BusinessEntityID_3 int = 300;
DECLARE @P_PhoneNumber_3 nvarchar(25) = '989-212-3223';
DECLARE @P_PhoneNumberTypeID_3 int = 3;
DECLARE @P_ModifiedDate_3 datetime = '2018-12-22 00:00:00';

/* Record 4  - This one should be rejected for PhoneNumberTypeID in another test*/
DECLARE @P_BusinessEntityID_4 int = 400;
DECLARE @P_PhoneNumber_4 nvarchar(25) = '999-222-3333';
DECLARE @P_PhoneNumberTypeID_4 int = 4;
DECLARE @P_ModifiedDate_4 datetime = '2018-12-23 00:00:00';

/* Record 5  - This one should be rejected for PhoneNumber starting with 666*/
DECLARE @P_BusinessEntityID_5 int = 400;
DECLARE @P_PhoneNumber_5 nvarchar(25) = '666-222-3333';
DECLARE @P_PhoneNumberTypeID_5 int = 1;
DECLARE @P_ModifiedDate_5 datetime = '2018-12-23 00:00:00';

--- STEP 1: Setup fake source and targets

exec [AdventureWorks2017_src].tSQLt.faketable 'Person.PersonPhone', @Identity = 1;
exec [AdventureWorks2017_tgt].tSQLt.faketable 'Person.PersonPhone', @Identity = 1;

DECLARE @insert_stmt_src_personphone nvarchar(1000);
DECLARE @insert_params_src_personphone nvarchar(1000);

SET @insert_stmt_src_personphone =
  N'INSERT INTO [AdventureWorks2017_src].[Person].[PersonPhone]
           ([BusinessEntityID]
           ,[PhoneNumber]
           ,[PhoneNumberTypeID]
           ,[ModifiedDate])
     VALUES
           (@P_BusinessEntityID
           ,@P_PhoneNumber
           ,@P_PhoneNumberTypeID
           ,@P_ModifiedDate)';

SET @insert_params_src_personphone = 
	N'@P_BusinessEntityID int,
      @P_PhoneNumber nvarchar(25),
      @P_PhoneNumberTypeID int,
      @P_ModifiedDate datetime';

EXECUTE sp_executesql @insert_stmt_src_personphone, @insert_params_src_personphone, -- Original record
    @P_BusinessEntityID = @P_BusinessEntityID_1, @P_PhoneNumber = @P_PhoneNumber_1, @P_PhoneNumberTypeID = @P_PhoneNumberTypeID_1, @P_ModifiedDate = @P_ModifiedDate_1;
EXECUTE sp_executesql @insert_stmt_src_personphone, @insert_params_src_personphone, -- Original record
    @P_BusinessEntityID = @P_BusinessEntityID_2, @P_PhoneNumber = @P_PhoneNumber_2, @P_PhoneNumberTypeID = @P_PhoneNumberTypeID_2, @P_ModifiedDate = @P_ModifiedDate_2;
EXECUTE sp_executesql @insert_stmt_src_personphone, @insert_params_src_personphone, -- Original record
    @P_BusinessEntityID = @P_BusinessEntityID_3, @P_PhoneNumber = @P_PhoneNumber_3, @P_PhoneNumberTypeID = @P_PhoneNumberTypeID_3, @P_ModifiedDate = @P_ModifiedDate_3;
EXECUTE sp_executesql @insert_stmt_src_personphone, @insert_params_src_personphone, -- Original record
    @P_BusinessEntityID = @P_BusinessEntityID_4, @P_PhoneNumber = @P_PhoneNumber_4, @P_PhoneNumberTypeID = @P_PhoneNumberTypeID_4, @P_ModifiedDate = @P_ModifiedDate_4;
EXECUTE sp_executesql @insert_stmt_src_personphone, @insert_params_src_personphone, -- Original record
    @P_BusinessEntityID = @P_BusinessEntityID_5, @P_PhoneNumber = @P_PhoneNumber_5, @P_PhoneNumberTypeID = @P_PhoneNumberTypeID_5, @P_ModifiedDate = @P_ModifiedDate_5;


---- STEP 2: Run the SSIS package

EXEC [SSISDB].[catalog].[create_execution] @package_name=@package_name, @execution_id=@execution_id OUTPUT, @folder_name=@folder_name, @project_name=@project_name, @use32bitruntime=False, @reference_id=@reference_id;

EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id, @object_type = 50, @parameter_name=N'LOGGING_LEVEL', @parameter_value=@logging_level;
EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id, @object_type = 50, @parameter_name=N'SYNCHRONIZED', @parameter_value=@is_synchronized;
EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id, @object_type = 20, @parameter_name=N'AW_SRC_InitialCatalog', @parameter_value=@AW_SRC_InitialCatalog;
EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id, @object_type = 20, @parameter_name=N'AW_SRC_ServerName', @parameter_value=@AW_SRC_ServerName;
EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id, @object_type = 20, @parameter_name=N'AW_SRC_ConnectionString', @parameter_value=@AW_SRC_ConnectionString;
EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id, @object_type = 20, @parameter_name=N'AW_TGT_InitialCatalog', @parameter_value=@AW_TGT_InitialCatalog;
EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id, @object_type = 20, @parameter_name=N'AW_TGT_ServerName', @parameter_value=@AW_TGT_ServerName;
EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id, @object_type = 20, @parameter_name=N'AW_TGT_ConnectionString', @parameter_value=@AW_TGT_ConnectionString;

EXEC [SSISDB].[catalog].[start_execution] @execution_id;

---- STEP 3 Assert the test results
SELECT @record_count = count(*)
  FROM [AdventureWorks2017_tgt].[Person].[PersonPhone]
  WHERE PhoneNumber LIKE '666%'

exec tSQLt.AssertEquals 0, @record_count, 'The number of records with PhoneNumber starting with 666 is non-zero.';

end