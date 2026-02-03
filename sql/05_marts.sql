USE riskops;
GO

IF OBJECT_ID('marts.risk_daily_report','V') IS NOT NULL DROP VIEW marts.risk_daily_report;
EXEC('CREATE VIEW marts.risk_daily_report AS
  SELECT
    CAST(ft.txn_time AS date) AS report_date,
    dc.segment,
    COUNT(*) AS txn_count,
    SUM(ft.amount) AS total_amount,
    AVG(ft.amount) AS avg_amount,
    MAX(ft.amount) AS max_amount,
    COUNT(DISTINCT da.account_id) AS unique_accounts,
    COUNT(DISTINCT dc.customer_id) AS unique_customers,
    SUM(CASE WHEN ft.amount >= 1000 THEN 1 ELSE 0 END) AS spike_txn_count
  FROM core.fact_transactions ft
  JOIN core.dim_account da ON da.account_sk = ft.account_sk
  JOIN core.dim_customer dc ON dc.customer_sk = da.customer_sk
  GROUP BY CAST(ft.txn_time AS date), dc.segment;
');

IF OBJECT_ID('marts.loan_risk_snapshot','V') IS NOT NULL DROP VIEW marts.loan_risk_snapshot;
EXEC('CREATE VIEW marts.loan_risk_snapshot AS
  WITH rep AS (
    SELECT loan_sk, SUM(amount) AS repaid
    FROM core.fact_repayments
    GROUP BY loan_sk
  )
  SELECT
    dl.loan_id,
    dc.customer_id,
    dc.segment,
    dl.product_type,
    dl.principal,
    ISNULL(rep.repaid, 0) AS repaid,
    (ISNULL(dl.principal,0) - ISNULL(rep.repaid,0)) AS outstanding,
    dl.due_date,
    CASE
      WHEN dl.due_date IS NOT NULL
       AND dl.due_date < CAST(SYSUTCDATETIME() AS date)
       AND (ISNULL(dl.principal,0) - ISNULL(rep.repaid,0)) > 0
      THEN 1 ELSE 0
    END AS is_delinquent
  FROM core.dim_loan dl
  JOIN core.dim_customer dc ON dc.customer_sk = dl.customer_sk
  LEFT JOIN rep ON rep.loan_sk = dl.loan_sk;
');
