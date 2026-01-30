TRUNCATE TABLE raw.customers_raw;
TRUNCATE TABLE raw.accounts_raw;
TRUNCATE TABLE raw.transactions_raw;
TRUNCATE TABLE raw.loans_raw;
TRUNCATE TABLE raw.repayments_raw;

BULK INSERT raw.customers_raw
FROM '/var/opt/mssql/import/customers.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', FIELDQUOTE='\"', TABLOCK);

BULK INSERT raw.accounts_raw
FROM '/var/opt/mssql/import/accounts.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', FIELDQUOTE='\"', TABLOCK);

BULK INSERT raw.transactions_raw
FROM '/var/opt/mssql/import/transactions.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', FIELDQUOTE='\"', TABLOCK);

BULK INSERT raw.loans_raw
FROM '/var/opt/mssql/import/loans.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', FIELDQUOTE='\"', TABLOCK);

BULK INSERT raw.repayments_raw
FROM '/var/opt/mssql/import/repayments.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', FIELDQUOTE='\"', TABLOCK);
