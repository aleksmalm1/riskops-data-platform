USE riskops;
GO

SELECT TOP 10 * FROM marts.risk_daily_report ORDER BY report_date DESC, segment;

SELECT TOP 10 loan_id, principal, repaid, outstanding, due_date, is_delinquent
FROM marts.loan_risk_snapshot
ORDER BY outstanding DESC;

SELECT 'accounts_orphans' t, COUNT(*) c FROM staging.accounts_orphans
UNION ALL SELECT 'txns_orphans', COUNT(*) FROM staging.transactions_orphans
UNION ALL SELECT 'loans_orphans', COUNT(*) FROM staging.loans_orphans
UNION ALL SELECT 'repayments_orphans', COUNT(*) FROM staging.repayments_orphans;
