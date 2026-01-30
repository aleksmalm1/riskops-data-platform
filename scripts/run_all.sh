#!/usr/bin/env bash
set -euo pipefail

PASS="${MSSQL_SA_PASSWORD:-}"
if [ -z "$PASS" ]; then
  echo "Set MSSQL_SA_PASSWORD (use .env + export, or set it manually)"
  exit 1
fi

run_sql () {
  local file="$1"
  echo "==> Running $file"
  docker exec -i riskops-sql /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$PASS" -C -i "/sql/$file"
}

run_sql "00_create_db.sql"
run_sql "01_raw_tables.sql"
run_sql "02_load_raw.sql"
run_sql "03_staging.sql"
run_sql "04_core.sql"
run_sql "05_marts.sql"
run_sql "99_demo_queries.sql"

echo "Done."
