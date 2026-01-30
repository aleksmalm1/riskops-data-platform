
IF OBJECT_ID('staging.customers_clean','U') IS NOT NULL DROP TABLE staging.customers_clean;
SELECT
  LTRIM(RTRIM(REPLACE(customer_id,'"',''))) AS customer_id,
  LTRIM(RTRIM(REPLACE(name,'"',''))) AS name,
  UPPER(LTRIM(RTRIM(REPLACE(segment,'"','')))) AS segment,
  TRY_CONVERT(date, NULLIF(LTRIM(RTRIM(REPLACE(birthdate,'"',''))), '')) AS birthdate,
  TRY_CONVERT(datetime2, NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(updated_at,'"',''),'T',' '),'Z',''))), '')) AS updated_at
INTO staging.customers_clean
FROM raw.customers_raw;

IF OBJECT_ID('staging.customers_dedup','U') IS NOT NULL DROP TABLE staging.customers_dedup;
WITH ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY CASE WHEN updated_at IS NULL THEN 0 ELSE 1 END DESC, updated_at DESC
    ) rn
  FROM staging.customers_clean
)
SELECT customer_id, name, segment, birthdate, updated_at
INTO staging.customers_dedup
FROM ranked
WHERE rn=1;

-- Accounts
IF OBJECT_ID('staging.accounts_clean','U') IS NOT NULL DROP TABLE staging.accounts_clean;
SELECT
  LTRIM(RTRIM(REPLACE(account_id,'"',''))) AS account_id,
  LTRIM(RTRIM(REPLACE(customer_id,'"',''))) AS customer_id,
  UPPER(LTRIM(RTRIM(REPLACE(account_type,'"','')))) AS account_type,
  TRY_CONVERT(datetime2, NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(opened_at,'"',''),'T',' '),'Z',''))), '')) AS opened_at,
  UPPER(LTRIM(RTRIM(REPLACE(status,'"','')))) AS status
INTO staging.accounts_clean
FROM raw.accounts_raw;

IF OBJECT_ID('staging.accounts','U') IS NOT NULL DROP TABLE staging.accounts;
WITH ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY account_id
      ORDER BY CASE WHEN opened_at IS NULL THEN 0 ELSE 1 END DESC, opened_at DESC
    ) rn
  FROM staging.accounts_clean
)
SELECT account_id, customer_id, account_type, opened_at, status
INTO staging.accounts
FROM ranked
WHERE rn=1;

IF OBJECT_ID('staging.accounts_valid','U') IS NOT NULL DROP TABLE staging.accounts_valid;
IF OBJECT_ID('staging.accounts_orphans','U') IS NOT NULL DROP TABLE staging.accounts_orphans;

SELECT a.*
INTO staging.accounts_valid
FROM staging.accounts a
JOIN staging.customers_dedup c ON c.customer_id=a.customer_id;

SELECT a.*
INTO staging.accounts_orphans
FROM staging.accounts a
LEFT JOIN staging.customers_dedup c ON c.customer_id=a.customer_id
WHERE c.customer_id IS NULL;

-- Loans
IF OBJECT_ID('staging.loans_clean','U') IS NOT NULL DROP TABLE staging.loans_clean;
SELECT
  LTRIM(RTRIM(REPLACE(loan_id,'"',''))) AS loan_id,
  LTRIM(RTRIM(REPLACE(customer_id,'"',''))) AS customer_id,
  UPPER(LTRIM(RTRIM(REPLACE(product_type,'"','')))) AS product_type,
  TRY_CONVERT(decimal(18,2), NULLIF(LTRIM(RTRIM(REPLACE(principal,'"',''))), '')) AS principal,
  TRY_CONVERT(date, NULLIF(LEFT(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(issued_at,'"',''),'T',' '),'Z',''))),10), '')) AS issued_at,
  TRY_CONVERT(date, NULLIF(LEFT(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(due_date,'"',''),'T',' '),'Z',''))),10), '')) AS due_date
INTO staging.loans_clean
FROM raw.loans_raw;

IF OBJECT_ID('staging.loans_valid','U') IS NOT NULL DROP TABLE staging.loans_valid;
IF OBJECT_ID('staging.loans_orphans','U') IS NOT NULL DROP TABLE staging.loans_orphans;

SELECT l.*
INTO staging.loans_valid
FROM staging.loans_clean l
JOIN staging.customers_dedup c ON c.customer_id=l.customer_id;

SELECT l.*
INTO staging.loans_orphans
FROM staging.loans_clean l
LEFT JOIN staging.customers_dedup c ON c.customer_id=l.customer_id
WHERE c.customer_id IS NULL;

-- Transactions
IF OBJECT_ID('staging.transactions_clean','U') IS NOT NULL DROP TABLE staging.transactions_clean;
SELECT
  LTRIM(RTRIM(REPLACE(txn_id,'"',''))) AS txn_id,
  LTRIM(RTRIM(REPLACE(account_id,'"',''))) AS account_id,
  TRY_CONVERT(datetime2, NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(txn_time,'"',''),'T',' '),'Z',''))), '')) AS txn_time,
  TRY_CONVERT(decimal(18,2), NULLIF(LTRIM(RTRIM(REPLACE(amount,'"',''))), '')) AS amount,
  UPPER(LTRIM(RTRIM(REPLACE(merchant_category,'"','')))) AS merchant_category,
  UPPER(LTRIM(RTRIM(REPLACE(channel,'"','')))) AS channel
INTO staging.transactions_clean
FROM raw.transactions_raw;

IF OBJECT_ID('staging.transactions_valid','U') IS NOT NULL DROP TABLE staging.transactions_valid;
IF OBJECT_ID('staging.transactions_orphans','U') IS NOT NULL DROP TABLE staging.transactions_orphans;

SELECT t.*
INTO staging.transactions_valid
FROM staging.transactions_clean t
JOIN staging.accounts_valid a ON a.account_id=t.account_id;

SELECT t.*
INTO staging.transactions_orphans
FROM staging.transactions_clean t
LEFT JOIN staging.accounts_valid a ON a.account_id=t.account_id
WHERE a.account_id IS NULL;

-- Repayments
IF OBJECT_ID('staging.repayments_clean','U') IS NOT NULL DROP TABLE staging.repayments_clean;
SELECT
  LTRIM(RTRIM(REPLACE(repayment_id,'"',''))) AS repayment_id,
  LTRIM(RTRIM(REPLACE(loan_id,'"',''))) AS loan_id,
  TRY_CONVERT(date, NULLIF(LEFT(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(payment_date,'"',''),'T',' '),'Z',''))),10), '')) AS payment_date,
  TRY_CONVERT(decimal(18,2), NULLIF(LTRIM(RTRIM(REPLACE(amount,'"',''))), '')) AS amount
INTO staging.repayments_clean
FROM raw.repayments_raw;

IF OBJECT_ID('staging.repayments_valid','U') IS NOT NULL DROP TABLE staging.repayments_valid;
IF OBJECT_ID('staging.repayments_orphans','U') IS NOT NULL DROP TABLE staging.repayments_orphans;

SELECT r.*
INTO staging.repayments_valid
FROM staging.repayments_clean r
JOIN staging.loans_valid l ON l.loan_id=r.loan_id;

SELECT r.*
INTO staging.repayments_orphans
FROM staging.repayments_clean r
LEFT JOIN staging.loans_valid l ON l.loan_id=r.loan_id
WHERE l.loan_id IS NULL;
