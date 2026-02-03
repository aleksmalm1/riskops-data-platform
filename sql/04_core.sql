USE riskops;
GO

IF OBJECT_ID('core.fact_transactions','U') IS NOT NULL DROP TABLE core.fact_transactions;
IF OBJECT_ID('core.fact_repayments','U')   IS NOT NULL DROP TABLE core.fact_repayments;

IF OBJECT_ID('core.dim_account','U')  IS NOT NULL DROP TABLE core.dim_account;
IF OBJECT_ID('core.dim_loan','U')     IS NOT NULL DROP TABLE core.dim_loan;
IF OBJECT_ID('core.dim_customer','U') IS NOT NULL DROP TABLE core.dim_customer;

-- DIM CUSTOMER
CREATE TABLE core.dim_customer (
  customer_sk INT IDENTITY(1,1) PRIMARY KEY,
  customer_id NVARCHAR(50) NOT NULL UNIQUE,
  name NVARCHAR(200) NULL,
  segment NVARCHAR(50) NULL,
  birthdate DATE NULL,
  updated_at DATETIME2 NULL
);

INSERT INTO core.dim_customer (customer_id, name, segment, birthdate, updated_at)
SELECT customer_id, name, segment, birthdate, updated_at
FROM staging.customers_dedup;

-- DIM ACCOUNT
CREATE TABLE core.dim_account (
  account_sk INT IDENTITY(1,1) PRIMARY KEY,
  account_id NVARCHAR(50) NOT NULL UNIQUE,
  customer_sk INT NOT NULL,
  account_type NVARCHAR(200) NULL,
  opened_at DATETIME2 NULL,
  status NVARCHAR(50) NULL
);

INSERT INTO core.dim_account (account_id, customer_sk, account_type, opened_at, status)
SELECT a.account_id, c.customer_sk, a.account_type, a.opened_at, a.status
FROM staging.accounts_valid a
JOIN core.dim_customer c ON c.customer_id=a.customer_id;

-- DIM LOAN
CREATE TABLE core.dim_loan (
  loan_sk INT IDENTITY(1,1) PRIMARY KEY,
  loan_id NVARCHAR(50) NOT NULL UNIQUE,
  customer_sk INT NOT NULL,
  product_type NVARCHAR(200) NULL,
  principal DECIMAL(18,2) NULL,
  issued_at DATE NULL,
  due_date DATE NULL
);

INSERT INTO core.dim_loan (loan_id, customer_sk, product_type, principal, issued_at, due_date)
SELECT l.loan_id, c.customer_sk, l.product_type, l.principal, l.issued_at, l.due_date
FROM staging.loans_valid l
JOIN core.dim_customer c ON c.customer_id=l.customer_id;

-- FACT TRANSACTIONS
CREATE TABLE core.fact_transactions (
  txn_id NVARCHAR(50) NOT NULL PRIMARY KEY,
  account_sk INT NOT NULL,
  txn_time DATETIME2 NULL,
  amount DECIMAL(18,2) NULL,
  merchant_category NVARCHAR(200) NULL,
  channel NVARCHAR(200) NULL
);

INSERT INTO core.fact_transactions (txn_id, account_sk, txn_time, amount, merchant_category, channel)
SELECT t.txn_id, a.account_sk, t.txn_time, t.amount, t.merchant_category, t.channel
FROM staging.transactions_valid t
JOIN core.dim_account a ON a.account_id=t.account_id;

-- FACT REPAYMENTS
CREATE TABLE core.fact_repayments (
  repayment_id NVARCHAR(50) NOT NULL PRIMARY KEY,
  loan_sk INT NOT NULL,
  payment_date DATE NULL,
  amount DECIMAL(18,2) NULL
);

INSERT INTO core.fact_repayments (repayment_id, loan_sk, payment_date, amount)
SELECT r.repayment_id, l.loan_sk, r.payment_date, r.amount
FROM staging.repayments_valid r
JOIN core.dim_loan l ON l.loan_id=r.loan_id;


CREATE INDEX ix_fact_txn_account ON core.fact_transactions(account_sk);
CREATE INDEX ix_fact_rep_loan    ON core.fact_repayments(loan_sk);
