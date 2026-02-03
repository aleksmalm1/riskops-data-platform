IF DB_ID('riskops') IS NULL
  CREATE DATABASE riskops;
GO

USE riskops;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='raw')     EXEC('CREATE SCHEMA raw');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='staging') EXEC('CREATE SCHEMA staging');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='core')    EXEC('CREATE SCHEMA core');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='marts')   EXEC('CREATE SCHEMA marts');
GO
