-- 1. Create Schema (if not exists)
CREATE SCHEMA IF NOT EXISTS sm_covid_recovery;

-- 2. Create MOM Workforce Table (if not exists) in the created schema
CREATE TABLE IF NOT EXISTS sm_covid_recovery.bt_mom_workforce (
    "NRIC" CHAR(9) NOT NULL,
    "Race" VARCHAR(100) NOT NULL,
    "Employment_Status" VARCHAR(100) NOT NULL,
    "Sector" VARCHAR(100) NOT NULL,
    "Salary" DECIMAL(10,2),
    PRIMARY KEY ("NRIC")
);
