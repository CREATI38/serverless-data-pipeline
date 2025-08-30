-- Create User for Lambda Function to execute statements
CREATE USER lambda_user WITH PASSWORD 'Password1';

-- Grant USAGE on the schema to the user
GRANT USAGE ON SCHEMA sm_covid_recovery TO lambda_user;

-- Grant permissions on the MOM table to the user
GRANT ALL PRIVILEGES ON sm_covid_recovery.bt_mom_workforce TO lambda_user;

-- Grant permissions on the MOE table to the user
GRANT ALL PRIVILEGES ON sm_covid_recovery.bt_moe_primary_school_students TO lambda_user;