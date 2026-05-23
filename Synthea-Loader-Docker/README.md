# Synthea CSV → PostgreSQL + OMOP CDM Docker Stack

Two independent pipelines, one database:

| Container | What it does | Schema |
|---|---|---|
| `loader` | Streams all 18 Synthea CSVs into PostgreSQL via `COPY` | `public` |
| `omop-etl` | Runs OHDSI ETL-Synthea: Synthea CSV → OMOP CDM v5.4 | `cdm_synthea` + `native` |

Both containers read from the same CSV directory and write to the same PostgreSQL instance in separate schemas, so they don't interfere with each other.

---

## Project layout

```
synthea-docker/
├── docker-compose.yml
├── postgres.conf            # Performance-tuned PG config
├── .env.example             # Copy to .env and edit
├── init/
│   └── 01_schema.sql        # Raw Synthea DDL (auto-runs on first start)
├── loader/
│   ├── Dockerfile
│   └── load.py              # Python COPY-based loader
└── omop-etl/
    ├── Dockerfile           # R + ETLSyntheaBuilder + JDBC
    └── run_etl.R            # Full OMOP ETL pipeline script
```

---

## Prerequisites

1. **Docker Desktop** (Windows/Mac) or Docker Engine + Compose (Linux)
2. **Synthea CSV output folder**, e.g. `C:\temp\synthea\output\csv`
3. **OMOP Vocabulary files** — required for the OMOP ETL:
   - Create a free account at https://athena.ohdsi.org
   - Click **Download** and select these vocabularies at minimum:
     - SNOMED (1), RxNorm (8), LOINC (6), CVX (53), ICD10CM (70), ICD9CM (69), NDC (9)
   - Download and unzip — you'll get a folder containing `CONCEPT.csv`, `VOCABULARY.csv`, etc.
   - Point `VOCAB_SOURCE_DIR` in `.env` at this folder

---

## Quick start

### 1. Configure

```bash
cp .env.example .env
```

Edit `.env` — at minimum set:

```env
POSTGRES_PASSWORD=your_strong_password
CSV_SOURCE_DIR=C:/temp/synthea/Synthea-Docker/output/csv
VOCAB_SOURCE_DIR=C:/temp/omop_vocab
OMOP_SYNTHEA_VERSION=3.3.0    # match your Synthea version
```

> **Windows paths:** use forward slashes in `.env` even on Windows.

### 2. Build images

```bash
docker compose build
```

> The `omop-etl` image takes a few minutes to build — it installs R, Java, and several OHDSI packages.

### 3. Run

Run both pipelines:
```bash
docker compose up
```

Or run just one:
```bash
docker compose up loader       # raw tables only
docker compose up omop-etl     # OMOP ETL only (reads CSV directly)
```

---

## What each pipeline produces

### `loader` — raw Synthea tables (schema: `public`)

All 18 Synthea CSV files loaded verbatim:

`patients`, `encounters`, `conditions`, `medications`, `observations`,
`procedures`, `immunizations`, `allergies`, `careplans`, `devices`,
`imaging_studies`, `claims`, `claims_transactions`, `payer_transitions`,
`payers`, `providers`, `organizations`, `supplies`

### `omop-etl` — OMOP CDM v5.4 (schemas: `cdm_synthea` + `native`)

- **`native` schema** — Synthea staging tables (created and populated by ETL-Synthea)
- **`cdm_synthea` schema** — Full OMOP CDM v5.4, including:
  - `person`, `visit_occurrence`, `condition_occurrence`
  - `drug_exposure`, `procedure_occurrence`
  - `observation`, `measurement`, `death`
  - All vocabulary tables (`concept`, `concept_relationship`, etc.)

---

## Connecting

| Field    | Value (default)   |
|----------|-------------------|
| Host     | `localhost`       |
| Port     | `5432`            |
| Database | `synthea`         |
| User     | `synthea`         |
| Password | *(from .env)*     |

```bash
# Raw tables
psql -h localhost -U synthea -d synthea -c "\dt public.*"

# OMOP CDM tables
psql -h localhost -U synthea -d synthea -c "\dt cdm_synthea.*"
```

---

## Expected load times

| Step | Approx. time |
|------|-------------|
| Raw loader (all 18 CSVs) | 45–90 min |
| OMOP ETL — CreateCDMTables | < 1 min |
| OMOP ETL — LoadSyntheaTables | 45–90 min |
| OMOP ETL — LoadVocabFromCsv | 10–30 min |
| OMOP ETL — LoadEventTables | 30–120 min |

The `omop-etl` container includes its own CSV loading step (via `ETLSyntheaBuilder::LoadSyntheaTables`) so it is fully self-contained — you do **not** need to run `loader` first.

---

## Troubleshooting

**`omop-etl` fails with "Vocabulary directory is missing required files"**
Download the vocabulary from https://athena.ohdsi.org and update `VOCAB_SOURCE_DIR` in `.env`.

**`OMOP_SYNTHEA_VERSION` mismatch**
ETL-Synthea supports `2.7.0`, `3.0.0`, `3.1.0`, `3.2.0`, and `3.3.0`. Check which version of Synthea generated your data and set `OMOP_SYNTHEA_VERSION` accordingly. The master branch is typically compatible with the latest supported version.

**Out of disk space**
Budget roughly 3× raw CSV size for PostgreSQL. With a ~12 GB CSV dataset, expect ~35–50 GB total including OMOP vocabulary tables.

**Re-running from scratch**
```bash
docker compose down -v    # wipe volumes
docker compose up --build
```
