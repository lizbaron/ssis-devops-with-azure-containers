sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
EXEC sp_configure 'clr strict security',0;
GO
RECONFIGURE;
GO
sp_configure 'clr enabled', 1;  
GO  
RECONFIGURE;  
GO