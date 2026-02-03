#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# RiskOps Data Platform - One-Click Demo Setup
# Run: bash scripts/run_all.sh
# ─────────────────────────────────────────────────────────────────────────────

# Go to repo root
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# ── Load password from .env ──────────────────────────────────────────────────
if [ ! -f .env ]; then
  echo "⚠️  .env not found. Creating from .env.example..."
  cp .env.example .env
  echo "✏️  Edit .env and set MSSQL_SA_PASSWORD to a strong password."
  exit 1
fi

PASS="$(grep -m1 '^MSSQL_SA_PASSWORD=' .env | cut -d= -f2-)"
if [ -z "${PASS}" ]; then
  echo "❌ MSSQL_SA_PASSWORD not set in .env"
  exit 1
fi
export MSSQL_SA_PASSWORD="$PASS"

echo "Starting RiskOps Data Platform..."

# ── Start Docker containers ──────────────────────────────────────────────────
echo "Starting Docker containers..."
docker compose up -d

# ── Detect container name (prefer riskops-sql, fallback to compose) ──────────
CONTAINER="riskops-sql"
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  CID="$(docker compose ps -q | head -n1 || true)"
  if [ -z "$CID" ]; then
    echo "❌ Could not detect container from docker compose."
    docker compose ps || true
    exit 1
  fi
  CONTAINER="$(docker inspect --format '{{.Name}}' "$CID" | sed 's#^/##')"
fi

echo "==> Using container: $CONTAINER"

# ── Wait for SQL Server to be ready ──────────────────────────────────────────
echo "Waiting for SQL Server to be ready..."
MAX_ATTEMPTS=60
ATTEMPT=1
until docker exec "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U sa -P "$PASS" -C -Q "SELECT 1" &>/dev/null; do
  if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
    echo "❌ SQL Server failed to start after $MAX_ATTEMPTS attempts"
    docker logs "$CONTAINER" --tail 120 || true
    exit 1
  fi
  echo "   Attempt $ATTEMPT/$MAX_ATTEMPTS - waiting..."
  sleep 2
  ((ATTEMPT++))
done
echo "✅ SQL Server is ready!"

# ── Verify CSVs exist in mounted folder (compose mount is read-only) ─────────
echo "Checking mounted CSV files..."
docker exec -it "$CONTAINER" bash -lc "ls -lah /var/opt/mssql/import || true"
for f in customers.csv accounts.csv transactions.csv loans.csv repayments.csv; do
  docker exec "$CONTAINER" bash -lc "test -f /var/opt/mssql/import/$f" \
    || { echo "❌ Missing: /var/opt/mssql/import/$f (check docker-compose mount ./data:/var/opt/mssql/import:ro)"; exit 1; }
done
echo "✅ CSV files found."

# ── Run SQL scripts ──────────────────────────────────────────────────────────
run_sql () {
  local file="$1"
  echo "==> Running $file"
  docker exec -i "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$PASS" -C -i "/sql/$file"
}

run_sql "00_create_db.sql"
run_sql "01_raw_tables.sql"
run_sql "02_load_raw.sql"
run_sql "03_staging.sql"
run_sql "04_core.sql"
run_sql "05_marts.sql"
run_sql "99_demo_queries.sql"

# ── Show demo output ─────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "🎉 Setup complete! Here's a sample of the data:"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""

docker exec -it "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$PASS" -C -d riskops \
  -Q "SELECT TOP 10 * FROM marts.risk_daily_report ORDER BY report_date DESC, segment;
      SELECT TOP 10 loan_id, outstanding, is_delinquent FROM marts.loan_risk_snapshot ORDER BY outstanding DESC;"

echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "✅ Done! SQL Server is running on localhost:1433"
echo "   To stop: docker compose down -v"
echo "   To query:"
echo "     docker exec -it $CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P \"<password>\" -C -d riskops"
echo "═══════════════════════════════════════════════════════════════════════════"
