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

-- 3. Create MOE Primary School Students Table (if not exists) in the created schema
CREATE TABLE IF NOT EXISTS sm_covid_recovery.bt_moe_primary_school_students (
    "NRIC" CHAR(9) NOT NULL,
    "Primary School" VARCHAR(100),
    "Level" INT,
    "Absences" INT,
    "CCA" VARCHAR(100),
    "English_Grade" INT,
    "Mathematics_Grade" INT,
    "Science_Grade" INT,
    "MTL_Grade" INT,
    PRIMARY KEY ("NRIC")
);
