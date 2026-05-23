#!/usr/bin/env Rscript
# =============================================================================
# run_etl.R  –  OHDSI ETL-Synthea pipeline
#
# Reads configuration from environment variables, then executes:
#   1. CreateCDMTables       – create OMOP CDM v5.4 schema
#   2. CreateSyntheaTables   – create raw Synthea staging schema
#   3. LoadSyntheaTables     – COPY CSV files into staging schema
#   4. LoadVocabFromCsv      – load OMOP vocabulary into CDM schema
#   5. CreateVocabMapTables  – build mapping/rollup helper tables
#   6. CreateVisitRollupTables
#   7. LoadEventTables       – run the SQL ETL transformations
#   8. CreateIndices         – post-load index creation
# =============================================================================

library(ETLSyntheaBuilder)
library(DatabaseConnector)

# ── Helper: read env var, abort with message if missing ──────────────────────
env <- function(key, default = NULL) {
  val <- Sys.getenv(key, unset = NA)
  if (is.na(val)) {
    if (!is.null(default)) return(default)
    stop(sprintf("Required environment variable '%s' is not set.", key))
  }
  val
}

# Helper: call an ETLSyntheaBuilder function with only the args it actually accepts.
# Prevents "unused argument" errors when function signatures vary across versions.
safe_call <- function(fn, ...) {
  args      <- list(...)
  accepted  <- names(formals(fn))
  args      <- args[names(args) %in% accepted]
  do.call(fn, args)
}

cat("=====================================================\n")
cat("  OHDSI ETL-Synthea  –  Synthea CSV -> OMOP CDM\n")
cat("=====================================================\n")

# ── Configuration ─────────────────────────────────────────────────────────────
db_host         <- env("OMOP_DB_HOST",      "synthea_db")
db_port         <- as.integer(env("OMOP_DB_PORT", "5432"))
db_name         <- env("OMOP_DB_NAME",      "synthea")
db_user         <- env("OMOP_DB_USER",      "synthea")
db_password     <- env("OMOP_DB_PASSWORD",  "synthea")

cdm_schema      <- env("OMOP_CDM_SCHEMA",     "cdm_synthea")
synthea_schema  <- env("OMOP_NATIVE_SCHEMA",  "native")
cdm_version     <- env("OMOP_CDM_VERSION",    "5.4")
synthea_version <- env("OMOP_SYNTHEA_VERSION","3.3.0")

synthea_csv_loc <- env("OMOP_SYNTHEA_CSV",  "/csv")
vocab_loc       <- env("OMOP_VOCAB_DIR",    "/vocab")
jdbc_driver_dir <- env("OMOP_JDBC_DIR",     "/jdbc")

cat(sprintf("  DB           : %s@%s:%d/%s\n", db_user, db_host, db_port, db_name))
cat(sprintf("  CDM schema   : %s  (v%s)\n", cdm_schema, cdm_version))
cat(sprintf("  Native schema: %s  (Synthea v%s)\n", synthea_schema, synthea_version))
cat(sprintf("  CSV source   : %s\n", synthea_csv_loc))
cat(sprintf("  Vocab source : %s\n", vocab_loc))
cat("=====================================================\n\n")

# ── Validate paths ────────────────────────────────────────────────────────────
if (!dir.exists(synthea_csv_loc)) {
  stop(sprintf("Synthea CSV directory not found: %s", synthea_csv_loc))
}

vocab_files <- c("CONCEPT.csv", "VOCABULARY.csv", "CONCEPT_RELATIONSHIP.csv")
missing_vocab <- vocab_files[!file.exists(file.path(vocab_loc, vocab_files))]
if (length(missing_vocab) > 0) {
  stop(paste(
    "Vocabulary directory is missing required files:", paste(missing_vocab, collapse=", "),
    "\nPlease download the OMOP vocabulary from https://athena.ohdsi.org",
    "\nand mount it at:", vocab_loc
  ))
}

# ── Wait for PostgreSQL ───────────────────────────────────────────────────────
wait_for_db <- function(cd, max_tries = 30, delay = 5) {
  for (i in seq_len(max_tries)) {
    tryCatch({
      conn <- DatabaseConnector::connect(cd)
      DatabaseConnector::disconnect(conn)
      cat(sprintf("  [%d/%d] PostgreSQL is ready.\n", i, max_tries))
      return(invisible(TRUE))
    }, error = function(e) {
      cat(sprintf("  [%d/%d] DB not ready (%s). Waiting %ds...\n", i, max_tries, conditionMessage(e), delay))
      Sys.sleep(delay)
    })
  }
  stop("Could not connect to PostgreSQL after maximum retries.")
}

# ── Connection details ────────────────────────────────────────────────────────
cd <- DatabaseConnector::createConnectionDetails(
  dbms       = "postgresql",
  server     = sprintf("%s/%s", db_host, db_name),
  user       = db_user,
  password   = db_password,
  port       = db_port,
  pathToDriver = jdbc_driver_dir
)

cat("Waiting for PostgreSQL...\n")
wait_for_db(cd)

# ── Ensure schemas exist ──────────────────────────────────────────────────────
cat("\nCreating schemas if they don't exist...\n")
conn <- DatabaseConnector::connect(cd)
DatabaseConnector::executeSql(conn, sprintf("CREATE SCHEMA IF NOT EXISTS %s;", cdm_schema))
DatabaseConnector::executeSql(conn, sprintf("CREATE SCHEMA IF NOT EXISTS %s;", synthea_schema))
DatabaseConnector::disconnect(conn)

# ── Step 1: Create OMOP CDM tables ───────────────────────────────────────────
cat("\n[1/7] Creating OMOP CDM tables...\n")
ETLSyntheaBuilder::CreateCDMTables(
  connectionDetails = cd,
  cdmSchema         = cdm_schema,
  cdmVersion        = cdm_version
)
cat("  Done.\n")

# ── Step 2: Create Synthea staging tables ─────────────────────────────────────
cat("\n[2/7] Creating Synthea staging tables...\n")
ETLSyntheaBuilder::CreateSyntheaTables(
  connectionDetails = cd,
  syntheaSchema     = synthea_schema,
  syntheaVersion    = synthea_version
)
cat("  Done.\n")

# ── Step 3: Load Synthea CSVs into staging ────────────────────────────────────
cat("\n[3/7] Loading Synthea CSV files...\n")
ETLSyntheaBuilder::LoadSyntheaTables(
  connectionDetails = cd,
  syntheaSchema     = synthea_schema,
  syntheaFileLoc    = synthea_csv_loc
)
cat("  Done.\n")

# ── Step 4: Load OMOP vocabulary ──────────────────────────────────────────────
cat("\n[4/7] Loading OMOP vocabulary...\n")
cat("  Note: This may take a long time for large vocabulary sets.\n")
ETLSyntheaBuilder::LoadVocabFromCsv(
  connectionDetails = cd,
  cdmSchema         = cdm_schema,
  vocabFileLoc      = vocab_loc
)
cat("  Done.\n")

# ── Step 5: Create vocab mapping tables ───────────────────────────────────────
cat("\n[5/7] Creating vocabulary mapping tables...\n")
safe_call(ETLSyntheaBuilder::CreateVocabMapTables,
  connectionDetails = cd,
  cdmSchema         = cdm_schema,
  cdmVersion        = cdm_version,
  syntheaVersion    = synthea_version)
cat("  Done.\n")

# ── Step 6: Create visit rollup tables ────────────────────────────────────────
cat("\n[6/7] Creating visit rollup tables...\n")
safe_call(ETLSyntheaBuilder::CreateVisitRollupTables,
  connectionDetails = cd,
  cdmSchema         = cdm_schema,
  syntheaSchema     = synthea_schema,
  cdmVersion        = cdm_version,
  syntheaVersion    = synthea_version)
cat("  Done.\n")

# ── Step 7: Run ETL – load OMOP event tables ──────────────────────────────────
cat("\n[7/7] Running ETL transformations (loading OMOP event tables)...\n")
cat("  Note: This is the longest step. Please be patient.\n")
ETLSyntheaBuilder::LoadEventTables(
  connectionDetails = cd,
  cdmSchema         = cdm_schema,
  syntheaSchema     = synthea_schema,
  cdmVersion        = cdm_version,
  syntheaVersion    = synthea_version
)
cat("  Done.\n")

# ── Summary ───────────────────────────────────────────────────────────────────
cat("\n=====================================================\n")
cat("  ETL complete!\n")
cat(sprintf("  OMOP CDM tables are in schema: %s\n", cdm_schema))
cat(sprintf("  Synthea staging tables are in: %s\n", synthea_schema))
cat("=====================================================\n")

# Print row counts for key OMOP tables
cat("\nRow counts for key OMOP CDM tables:\n")
conn <- DatabaseConnector::connect(cd)
omop_tables <- c("person", "visit_occurrence", "condition_occurrence",
                 "drug_exposure", "procedure_occurrence", "observation",
                 "measurement", "death")
for (tbl in omop_tables) {
  tryCatch({
    n <- DatabaseConnector::querySql(
      conn,
      sprintf("SELECT COUNT(*) AS n FROM %s.%s", cdm_schema, tbl)
    )$N
    cat(sprintf("  %-30s %d\n", tbl, n))
  }, error = function(e) {
    cat(sprintf("  %-30s (error: %s)\n", tbl, conditionMessage(e)))
  })
}
DatabaseConnector::disconnect(conn)
