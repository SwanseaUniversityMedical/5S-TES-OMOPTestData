#!/usr/bin/env python3
"""
Synthea CSV to PostgreSQL Loader
Reads actual CSV headers from each file and maps them to DB column names
dynamically (case-insensitive, ignoring spaces/underscores), so it works
regardless of Synthea version or minor header variations.
"""

import os
import sys
import csv
import io
import time
import logging
import psycopg2
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
log = logging.getLogger(__name__)

DB_CONFIG = {
    "host":     os.environ.get("POSTGRES_HOST", "synthea_db"),
    "port":     int(os.environ.get("POSTGRES_PORT", 5432)),
    "dbname":   os.environ.get("POSTGRES_DB",   "synthea"),
    "user":     os.environ.get("POSTGRES_USER",  "synthea"),
    "password": os.environ.get("POSTGRES_PASSWORD", "synthea"),
}

CSV_DIR = Path(os.environ.get("CSV_DIR", "/csv"))

LOAD_ORDER = [
    "patients",
    "organizations",
    "payers",
    "providers",
    "encounters",
    "allergies",
    "careplans",
    "conditions",
    "devices",
    "imaging_studies",
    "immunizations",
    "medications",
    "observations",
    "procedures",
    "supplies",
    "claims",
    "claims_transactions",
    "payer_transitions",
]


def wait_for_db(max_retries=30, delay=5):
    for attempt in range(1, max_retries + 1):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            log.info("Connected to PostgreSQL")
            return conn
        except psycopg2.OperationalError as e:
            log.warning("Attempt %d/%d: DB not ready (%s). Waiting %ds...",
                        attempt, max_retries, e, delay)
            time.sleep(delay)
    log.error("Could not connect to PostgreSQL. Exiting.")
    sys.exit(1)


def get_db_columns(conn, table):
    """Return dict of {normalised_name: original_name} for all columns in the table."""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = %s
        """, (table,))
        rows = cur.fetchall()
    def norm(s):
        return s.lower().replace(" ", "").replace("_", "").replace("-", "")
    return {norm(r[0]): r[0] for r in rows}


def read_header(path):
    """Return (headers_list, delimiter) from first line."""
    with open(path, newline="", encoding="utf-8-sig") as f:
        sample = f.read(8192)
    try:
        dialect = csv.Sniffer().sniff(sample, delimiters=",\t|")
        delim = dialect.delimiter
    except csv.Error:
        delim = ","
    with open(path, newline="", encoding="utf-8-sig") as f:
        reader = csv.reader(f, delimiter=delim)
        headers = [h.strip() for h in next(reader)]
    return headers, delim


def load_table(conn, table, csv_path):
    if not csv_path.exists():
        log.warning("  File not found, skipping: %s", csv_path.name)
        return

    size_mb = csv_path.stat().st_size / 1_048_576
    log.info("  Loading %s from %s (%.1f MB)...", table, csv_path.name, size_mb)
    t0 = time.time()

    db_cols = get_db_columns(conn, table)
    if not db_cols:
        log.error("  Table '%s' not found in database.", table)
        return

    csv_headers, delim = read_header(csv_path)

    def norm(s):
        return s.lower().replace(" ", "").replace("_", "").replace("-", "")

    # Map each CSV header index to a DB column name (or None to skip)
    col_map = []
    for h in csv_headers:
        col_map.append(db_cols.get(norm(h)))

    skipped = [h for h, m in zip(csv_headers, col_map) if m is None]
    if skipped:
        log.warning("  Skipping unmatched CSV columns: %s", skipped)

    used_indices = [i for i, m in enumerate(col_map) if m is not None]
    used_db_cols = [col_map[i] for i in used_indices]

    if not used_db_cols:
        log.error("  No columns matched for %s — skipping.", table)
        return

    col_list = ", ".join('"%s"' % c for c in used_db_cols)
    copy_sql = 'COPY %s (%s) FROM STDIN WITH (FORMAT CSV, NULL \'\', DELIMITER \',\')' % (table, col_list)

    CHUNK = 100_000
    with conn.cursor() as cur:
        with open(csv_path, newline="", encoding="utf-8-sig") as f:
            reader = csv.reader(f, delimiter=delim)
            next(reader)  # skip header
            rows = []
            for row in reader:
                rows.append([row[i] if i < len(row) else "" for i in used_indices])
                if len(rows) >= CHUNK:
                    buf = io.StringIO()
                    csv.writer(buf).writerows(rows)
                    buf.seek(0)
                    cur.copy_expert(copy_sql, buf)
                    rows = []
            if rows:
                buf = io.StringIO()
                csv.writer(buf).writerows(rows)
                buf.seek(0)
                cur.copy_expert(copy_sql, buf)

    conn.commit()
    log.info("  Done: %s in %.1fs", table, time.time() - t0)


def main():
    log.info("=" * 60)
    log.info("Synthea CSV -> PostgreSQL Loader")
    log.info("=" * 60)
    log.info("CSV directory : %s", CSV_DIR)
    log.info("Target DB     : %s @ %s:%s", DB_CONFIG["dbname"], DB_CONFIG["host"], DB_CONFIG["port"])

    conn = wait_for_db()
    conn.autocommit = False

    errors = []
    for table in LOAD_ORDER:
        try:
            load_table(conn, table, CSV_DIR / (table + ".csv"))
        except Exception as e:
            log.error("  FAILED %s: %s", table, e)
            conn.rollback()
            errors.append((table, str(e)))

    conn.close()
    log.info("=" * 60)
    if errors:
        log.error("Completed with %d error(s):", len(errors))
        for t, e in errors:
            log.error("  %s: %s", t, e)
        sys.exit(1)
    else:
        log.info("All tables loaded successfully!")


if __name__ == "__main__":
    main()
