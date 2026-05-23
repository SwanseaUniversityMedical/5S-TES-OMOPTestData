-- ============================================================
-- Synthea CSV to PostgreSQL Schema
-- Based on: https://github.com/synthetichealth/synthea/wiki/CSV-File-Data-Dictionary
-- ============================================================

-- Enable timing
\timing on

-- ============================================================
-- PATIENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS patients (
    "Id"                UUID PRIMARY KEY,
    "BirthDate"         DATE,
    "DeathDate"         DATE,
    "SSN"               VARCHAR(11),
    "Drivers"           VARCHAR(50),
    "Passport"          VARCHAR(50),
    "Prefix"            VARCHAR(20),
    "First"             VARCHAR(100),
    "Middle"            VARCHAR(100),
    "Last"              VARCHAR(100),
    "Suffix"            VARCHAR(20),
    "Maiden"            VARCHAR(100),
    "Marital"           CHAR(1),
    "Race"              VARCHAR(50),
    "Ethnicity"         VARCHAR(50),
    "Gender"            CHAR(1),
    "BirthPlace"        TEXT,
    "Address"           TEXT,
    "City"              VARCHAR(100),
    "State"             VARCHAR(50),
    "County"            VARCHAR(100),
    "FIPS"              VARCHAR(20),
    "Zip"               VARCHAR(20),
    "Lat"               DOUBLE PRECISION,
    "Lon"               DOUBLE PRECISION,
    "Healthcare_Expenses"   NUMERIC(12,2),
    "Healthcare_Coverage"   NUMERIC(12,2),
    "Income"            NUMERIC(12,2)
);

-- ============================================================
-- ORGANIZATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS organizations (
    "Id"        UUID PRIMARY KEY,
    "Name"      TEXT,
    "Address"   TEXT,
    "City"      VARCHAR(100),
    "State"     VARCHAR(50),
    "Zip"       VARCHAR(20),
    "Lat"       DOUBLE PRECISION,
    "Lon"       DOUBLE PRECISION,
    "Phone"     VARCHAR(30),
    "Revenue"   NUMERIC(12,2),
    "Utilization" BIGINT
);

-- ============================================================
-- PAYERS
-- ============================================================
CREATE TABLE IF NOT EXISTS payers (
    "Id"                        UUID PRIMARY KEY,
    "Name"                      TEXT,
    "Ownership"                 VARCHAR(50),
    "Address"                   TEXT,
    "City"                      VARCHAR(100),
    "State_Headquartered"       VARCHAR(50),
    "Zip"                       VARCHAR(20),
    "Phone"                     VARCHAR(30),
    "Amount_Covered"            NUMERIC(14,2),
    "Amount_Uncovered"          NUMERIC(14,2),
    "Revenue"                   NUMERIC(14,2),
    "Covered_Encounters"        BIGINT,
    "Uncovered_Encounters"      BIGINT,
    "Covered_Medications"       BIGINT,
    "Uncovered_Medications"     BIGINT,
    "Covered_Procedures"        BIGINT,
    "Uncovered_Procedures"      BIGINT,
    "Covered_Immunizations"     BIGINT,
    "Uncovered_Immunizations"   BIGINT,
    "Unique_Customers"          BIGINT,
    "QOLS_Avg"                  NUMERIC(8,4),
    "Member_Months"             BIGINT
);

-- ============================================================
-- PROVIDERS
-- ============================================================
CREATE TABLE IF NOT EXISTS providers (
    "Id"            UUID PRIMARY KEY,
    "Organization"  UUID,
    "Name"          TEXT,
    "Gender"        CHAR(1),
    "Speciality"    VARCHAR(200),
    "Address"       TEXT,
    "City"          VARCHAR(100),
    "State"         VARCHAR(50),
    "Zip"           VARCHAR(20),
    "Lat"           DOUBLE PRECISION,
    "Lon"           DOUBLE PRECISION,
    "Utilization"   BIGINT,
    "ENCOUNTERS"    BIGINT
);

-- ============================================================
-- ENCOUNTERS
-- ============================================================
CREATE TABLE IF NOT EXISTS encounters (
    "Id"                    UUID PRIMARY KEY,
    "Start"                 TIMESTAMPTZ,
    "Stop"                  TIMESTAMPTZ,
    "Patient"               UUID,
    "Organization"          UUID,
    "Provider"              UUID,
    "Payer"                 UUID,
    "EncounterClass"        VARCHAR(50),
    "Code"                  VARCHAR(50),
    "Description"           TEXT,
    "Base_Encounter_Cost"   NUMERIC(12,2),
    "Total_Claim_Cost"      NUMERIC(12,2),
    "Payer_Coverage"        NUMERIC(12,2),
    "ReasonCode"            VARCHAR(50),
    "ReasonDescription"     TEXT
);

-- ============================================================
-- ALLERGIES
-- ============================================================
CREATE TABLE IF NOT EXISTS allergies (
    "Start"         DATE,
    "Stop"          DATE,
    "Patient"       UUID,
    "Encounter"     UUID,
    "Code"          VARCHAR(50),
    "System"        VARCHAR(50),
    "Description"   TEXT,
    "Type"          VARCHAR(20),
    "Category"      VARCHAR(30),
    "Reaction1"     VARCHAR(50),
    "Description1"  TEXT,
    "Severity1"     VARCHAR(20),
    "Reaction2"     VARCHAR(50),
    "Description2"  TEXT,
    "Severity2"     VARCHAR(20)
);

-- ============================================================
-- CAREPLANS
-- ============================================================
CREATE TABLE IF NOT EXISTS careplans (
    "Id"                UUID PRIMARY KEY,
    "Start"             DATE,
    "Stop"              DATE,
    "Patient"           UUID,
    "Encounter"         UUID,
    "Code"              VARCHAR(50),
    "Description"       TEXT,
    "ReasonCode"        VARCHAR(50),
    "ReasonDescription" TEXT
);

-- ============================================================
-- CONDITIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS conditions (
    "Start"         DATE,
    "Stop"          DATE,
    "Patient"       UUID,
    "Encounter"     UUID,
    "System"        VARCHAR(50),
    "Code"          VARCHAR(50),
    "Description"   TEXT
);

-- ============================================================
-- DEVICES
-- ============================================================
CREATE TABLE IF NOT EXISTS devices (
    "Start"         TIMESTAMPTZ,
    "Stop"          TIMESTAMPTZ,
    "Patient"       UUID,
    "Encounter"     UUID,
    "Code"          VARCHAR(50),
    "Description"   TEXT,
    "UDI"           TEXT
);

-- ============================================================
-- IMAGING STUDIES
-- ============================================================
CREATE TABLE IF NOT EXISTS imaging_studies (
    "Id"                    UUID,
    "Date"                  TIMESTAMPTZ,
    "Patient"               UUID,
    "Encounter"             UUID,
    "Series_UID"            VARCHAR(100),
    "Body_Site_Code"        VARCHAR(50),
    "Body_Site_Description" TEXT,
    "Modality_Code"         VARCHAR(20),
    "Modality_Description"  TEXT,
    "Instance_UID"          VARCHAR(100),
    "SOP_Code"              VARCHAR(100),
    "SOP_Description"       TEXT,
    "Procedure_Code"        VARCHAR(50)
);

-- ============================================================
-- IMMUNIZATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS immunizations (
    "Date"          TIMESTAMPTZ,
    "Patient"       UUID,
    "Encounter"     UUID,
    "Code"          VARCHAR(50),
    "Description"   TEXT,
    "Cost"          NUMERIC(12,2),
    "Base_Cost"     NUMERIC(12,2)
);

-- ============================================================
-- MEDICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS medications (
    "Start"             TIMESTAMPTZ,
    "Stop"              TIMESTAMPTZ,
    "Patient"           UUID,
    "Payer"             UUID,
    "Encounter"         UUID,
    "Code"              VARCHAR(50),
    "Description"       TEXT,
    "Base_Cost"         NUMERIC(12,2),
    "Payer_Coverage"    NUMERIC(12,2),
    "Dispenses"         INT,
    "TotalCost"         NUMERIC(12,2),
    "ReasonCode"        VARCHAR(50),
    "ReasonDescription" TEXT
);

-- ============================================================
-- OBSERVATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS observations (
    "Date"          TIMESTAMPTZ,
    "Patient"       UUID,
    "Encounter"     UUID,
    "Category"      VARCHAR(50),
    "Code"          VARCHAR(50),
    "Description"   TEXT,
    "Value"         TEXT,
    "Units"         VARCHAR(50),
    "Type"          VARCHAR(50)
);

-- ============================================================
-- PROCEDURES
-- ============================================================
CREATE TABLE IF NOT EXISTS procedures (
    "Start"             TIMESTAMPTZ,
    "Stop"              TIMESTAMPTZ,
    "Patient"           UUID,
    "Encounter"         UUID,
    "System"            VARCHAR(50),
    "Code"              VARCHAR(50),
    "Description"       TEXT,
    "Base_Cost"         NUMERIC(12,2),
    "ReasonCode"        VARCHAR(50),
    "ReasonDescription" TEXT
);

-- ============================================================
-- SUPPLIES
-- ============================================================
CREATE TABLE IF NOT EXISTS supplies (
    "Date"          DATE,
    "Patient"       UUID,
    "Encounter"     UUID,
    "Code"          VARCHAR(50),
    "Description"   TEXT,
    "Quantity"      INT
);

-- ============================================================
-- CLAIMS
-- ============================================================
CREATE TABLE IF NOT EXISTS claims (
    "Id"                            UUID PRIMARY KEY,
    "Patient_Id"                    UUID,
    "Provider_Id"                   UUID,
    "Primary_Patient_Insurance_Id"  UUID,
    "Secondary_Patient_Insurance_Id" UUID,
    "Department_Id"                 BIGINT,
    "Patient_Department_Id"         BIGINT,
    "Diagnosis1"                    VARCHAR(50),
    "Diagnosis2"                    VARCHAR(50),
    "Diagnosis3"                    VARCHAR(50),
    "Diagnosis4"                    VARCHAR(50),
    "Diagnosis5"                    VARCHAR(50),
    "Diagnosis6"                    VARCHAR(50),
    "Diagnosis7"                    VARCHAR(50),
    "Diagnosis8"                    VARCHAR(50),
    "Referring_Provider_Id"         UUID,
    "Appointment_Id"                UUID,
    "Current_Illness_Date"          TIMESTAMPTZ,
    "Service_Date"                  TIMESTAMPTZ,
    "Supervising_Provider_Id"       UUID,
    "Status1"                       VARCHAR(20),
    "Status2"                       VARCHAR(20),
    "StatusP"                       VARCHAR(20),
    "Outstanding1"                  NUMERIC(12,2),
    "Outstanding2"                  NUMERIC(12,2),
    "OutstandingP"                  NUMERIC(12,2),
    "LastBilledDate1"               TIMESTAMPTZ,
    "LastBilledDate2"               TIMESTAMPTZ,
    "LastBilledDateP"               TIMESTAMPTZ,
    "HealthcareClaimTypeID1"        SMALLINT,
    "HealthcareClaimTypeID2"        SMALLINT
);

-- ============================================================
-- CLAIMS TRANSACTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS claims_transactions (
    "Id"                    UUID PRIMARY KEY,
    "Claim_Id"              UUID,
    "Charge_Id"             BIGINT,
    "Patient_Id"            UUID,
    "Type"                  VARCHAR(20),
    "Amount"                NUMERIC(12,2),
    "Method"                VARCHAR(20),
    "From_Date"             TIMESTAMPTZ,
    "To_Date"               TIMESTAMPTZ,
    "Place_of_Service"      UUID,
    "Procedure_Code"        VARCHAR(50),
    "Modifier1"             VARCHAR(20),
    "Modifier2"             VARCHAR(20),
    "DiagnosisRef1"         SMALLINT,
    "DiagnosisRef2"         SMALLINT,
    "DiagnosisRef3"         SMALLINT,
    "DiagnosisRef4"         SMALLINT,
    "Units"                 NUMERIC(10,2),
    "Department_Id"         BIGINT,
    "Notes"                 TEXT,
    "Unit_Amount"           NUMERIC(12,2),
    "Transfer_Out_Id"       BIGINT,
    "Transfer_Type"         VARCHAR(5),
    "Payments"              NUMERIC(12,2),
    "Adjustments"           NUMERIC(12,2),
    "Transfers"             NUMERIC(12,2),
    "Outstanding"           NUMERIC(12,2),
    "Appointment_Id"        UUID,
    "Line_Note"             TEXT,
    "Patient_Insurance_Id"  UUID,
    "Fee_Schedule_Id"       BIGINT,
    "Provider_Id"           UUID,
    "Supervising_Provider_Id" UUID
);

-- ============================================================
-- PAYER TRANSITIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS payer_transitions (
    "Patient"               UUID,
    "MemberId"              UUID,
    "Member_Id"             UUID,
    "StartYear"             INT,
    "Start_Year"            INT,
    "StartDate"             DATE,
    "Start_Date"            DATE,
    "EndYear"               INT,
    "End_Year"              INT,
    "EndDate"               DATE,
    "End_Date"              DATE,
    "Payer"                 UUID,
    "Secondary_Payer"       UUID,
    "SecondaryPayer"        UUID,
    "PlanOwnership"         VARCHAR(50),
    "Plan_Ownership"        VARCHAR(50),
    "OwnerName"             TEXT,
    "Owner_Name"            TEXT
);

-- ============================================================
-- INDEXES for common join/filter columns
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_encounters_patient    ON encounters("Patient");
CREATE INDEX IF NOT EXISTS idx_encounters_org        ON encounters("Organization");
CREATE INDEX IF NOT EXISTS idx_allergies_patient     ON allergies("Patient");
CREATE INDEX IF NOT EXISTS idx_allergies_encounter   ON allergies("Encounter");
CREATE INDEX IF NOT EXISTS idx_careplans_patient     ON careplans("Patient");
CREATE INDEX IF NOT EXISTS idx_conditions_patient    ON conditions("Patient");
CREATE INDEX IF NOT EXISTS idx_devices_patient       ON devices("Patient");
CREATE INDEX IF NOT EXISTS idx_imaging_patient       ON imaging_studies("Patient");
CREATE INDEX IF NOT EXISTS idx_immunizations_patient ON immunizations("Patient");
CREATE INDEX IF NOT EXISTS idx_medications_patient   ON medications("Patient");
CREATE INDEX IF NOT EXISTS idx_observations_patient  ON observations("Patient");
CREATE INDEX IF NOT EXISTS idx_procedures_patient    ON procedures("Patient");
CREATE INDEX IF NOT EXISTS idx_supplies_patient      ON supplies("Patient");
CREATE INDEX IF NOT EXISTS idx_claims_patient        ON claims("Patient_Id");
CREATE INDEX IF NOT EXISTS idx_claims_provider       ON claims("Provider_Id");
CREATE INDEX IF NOT EXISTS idx_claims_tx_claim       ON claims_transactions("Claim_Id");
CREATE INDEX IF NOT EXISTS idx_claims_tx_patient     ON claims_transactions("Patient_Id");
CREATE INDEX IF NOT EXISTS idx_payer_trans_patient   ON payer_transitions("Patient");
CREATE INDEX IF NOT EXISTS idx_payer_trans_payer     ON payer_transitions("Payer");
