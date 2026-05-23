FROM rocker/r-ver:4.4.0

LABEL description="OHDSI ETL-Synthea: Converts Synthea CSVs to OMOP CDM v5.4"

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # libuv1-dev required by fs >= 2.1.0 when building from source
    libuv1-dev \
    # Java runtime + dev headers (for rJava/JDBC)
    default-jdk \
    # Missing linker targets for rJava JRI build
    libpcre2-dev \
    libdeflate-dev \
    liblzma-dev \
    libbz2-dev \
    libz-dev \
    zlib1g-dev \
    libicu-dev \
    # Other R package build deps
    libpq-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libsodium-dev \
    libgit2-dev \
    cmake \
    build-essential \
    pkg-config \
    git \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Java setup ────────────────────────────────────────────────────────────────
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${JAVA_HOME}/lib/server"
RUN R CMD javareconf

# ── PostgreSQL JDBC driver ────────────────────────────────────────────────────
RUN mkdir -p /jdbc && \
    curl -fsSL "https://jdbc.postgresql.org/download/postgresql-42.7.3.jar" \
    -o /jdbc/postgresql-42.7.3.jar

# ── Stage 1: remotes ─────────────────────────────────────────────────────────
RUN Rscript -e "\
  options(repos = c(CRAN = 'https://cloud.r-project.org')); \
  install.packages('remotes'); \
  stopifnot(requireNamespace('remotes', quietly=TRUE)); \
  cat('remotes OK\n'); \
"

# ── Stage 2: rJava ───────────────────────────────────────────────────────────
RUN Rscript -e "\
  options(repos = c(CRAN = 'https://cloud.r-project.org')); \
  install.packages('rJava'); \
  stopifnot(requireNamespace('rJava', quietly=TRUE)); \
  cat('rJava OK\n'); \
"

# ── Stage 3: Core data packages ──────────────────────────────────────────────
RUN Rscript -e "\
  options(repos = c(CRAN = 'https://cloud.r-project.org')); \
  install.packages(c('DBI', 'data.table', 'stringr', 'readr')); \
  for (p in c('DBI','data.table','stringr','readr')) \
    stopifnot(requireNamespace(p, quietly=TRUE)); \
  cat('Core data packages OK\n'); \
"

# ── Stage 4: SqlRender + DatabaseConnector ────────────────────────────────────
RUN Rscript -e "\
  options(repos = c(CRAN = 'https://cloud.r-project.org')); \
  install.packages(c('SqlRender', 'DatabaseConnector')); \
  for (p in c('SqlRender','DatabaseConnector')) \
    stopifnot(requireNamespace(p, quietly=TRUE)); \
  cat('SqlRender + DatabaseConnector OK\n'); \
"

# ── Stage 5: CommonDataModel ──────────────────────────────────────────────────
RUN Rscript -e "\
  options(repos = c(CRAN = 'https://cloud.r-project.org')); \
  install.packages('CommonDataModel'); \
  stopifnot(requireNamespace('CommonDataModel', quietly=TRUE)); \
  cat('CommonDataModel OK\n'); \
"

# ── Stage 6: ETLSyntheaBuilder from GitHub ────────────────────────────────────
RUN Rscript -e "\
  options(repos = c(CRAN = 'https://cloud.r-project.org')); \
  remotes::install_github('OHDSI/ETL-Synthea', upgrade = 'never', force = TRUE); \
  stopifnot(requireNamespace('ETLSyntheaBuilder', quietly=TRUE)); \
  cat('ETLSyntheaBuilder', \
      as.character(packageVersion('ETLSyntheaBuilder')), 'OK\n'); \
"

WORKDIR /etl
COPY run_etl.R .

CMD ["Rscript", "/etl/run_etl.R"]
