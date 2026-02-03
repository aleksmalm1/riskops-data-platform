# RiskOps Mini Data Platform (SQL Server)

Small data-platform style project: load messy CSVs → clean/validate → model dim/fact → build reporting views.

## What’s inside
- `data/` CSV input files
- `sql/` pipeline scripts
  - `00_create_db.sql` create DB + schemas
  - `01_raw_tables.sql` create RAW tables
  - `02_load_raw.sql` load CSV → RAW (BULK INSERT)
  - `03_staging.sql` clean/parse/dedupe + split valid vs orphans
  - `04_core.sql` dims/facts (surrogate keys) + indexes
  - `05_marts.sql` reporting views
  - `99_demo_queries.sql` example queries
- `scripts/run_all.sh` runs all scripts in order

## Quick Start
```bash
git clone <repo-url> && cd riskops-data-platform
bash scripts/run_all.sh
```

The script will:
1. Create `.env` from `.env.example` (if missing)
2. Start SQL Server in Docker
3. Run the full ETL pipeline
4. Display sample query results

**Requirements:** Docker

## Stop / Clean up
```bash
docker compose down -v
```
