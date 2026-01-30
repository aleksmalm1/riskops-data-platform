IF OBJECT_ID('raw.customers_raw','U') IS NOT NULL DROP TABLE raw.customers_raw;
CREATE TABLE raw.customers_raw (
  customer_id nvarchar(50) NULL,
  name nvarchar(50) NULL,
  segment nvarchar(200) NULL,
  birthdate nvarchar(50) NULL,
  updated_at nvarchar(200) NULL
);

IF OBJECT_ID('raw.accounts_raw','U') IS NOT NULL DROP TABLE raw.accounts_raw;
CREATE TABLE raw.accounts_raw (
  account_id nvarchar(50) NULL,
  customer_id nvarchar(50) NULL,
  account_type nvarchar(200) NULL,
  opened_at nvarchar(50) NULL,
  status nvarchar(200) NULL
);

IF OBJECT_ID('raw.transactions_raw','U') IS NOT NULL DROP TABLE raw.transactions_raw;
CREATE TABLE raw.transactions_raw (
  txn_id nvarchar(50) NULL,
  account_id nvarchar(50) NULL,
  txn_time nvarchar(50) NULL,
  amount nvarchar(50) NULL,
  merchant_category nvarchar(200) NULL,
  channel nvarchar(200) NULL
);

IF OBJECT_ID('raw.loans_raw','U') IS NOT NULL DROP TABLE raw.loans_raw;
CREATE TABLE raw.loans_raw (
  loan_id nvarchar(50) NULL,
  customer_id nvarchar(50) NULL,
  product_type nvarchar(200) NULL,
  principal nvarchar(50) NULL,
  issued_at nvarchar(50) NULL,
  due_date nvarchar(50) NULL
);

IF OBJECT_ID('raw.repayments_raw','U') IS NOT NULL DROP TABLE raw.repayments_raw;
CREATE TABLE raw.repayments_raw (
  repayment_id nvarchar(50) NULL,
  loan_id nvarchar(50) NULL,
  payment_date nvarchar(50) NULL,
  amount nvarchar(50) NULL
);
