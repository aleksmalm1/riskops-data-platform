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

## Start (fresh clone)
```bash
cp .env.example .env
export $(cat .env | xargs)

docker compose up -d
bash scripts/run_all.sh
