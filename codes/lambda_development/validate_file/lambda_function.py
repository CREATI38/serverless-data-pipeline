# Import functions from utility_function.py
from utility_function import *

# Import other necessary python libraries
import boto3
import pandas as pd
from io import StringIO

# Initialize S3 client
s3 = boto3.client('s3')
global_config = None

# Function to set global variables
def set_globals():
    # Set global configuration variables
    global global_config
    if global_config is None:
        global_config = {
            "data_configuration_file_name_suffix": "data_configuration_file.json",
            "data_configuration_folder_name": "data-configuration-files",
            "rejected_folder_name": "rejected-files/",
            "error_report_folder_name": "error-reports/",
            "landing_folder_name": "1-landing-zone/",
            "file_validated_folder_name": "2-file-validated-zone/",
            "archived_folder_name": "archived-files/"
        }
        print("Info - Global configuration initialized.")

# ========================================================
# Main File Validation Function
# ========================================================

def lambda_handler(event, context):
    try:
        print("Info - Starting File Validation..")
        error_log = StringIO()
        set_globals()

        # --- Extract bucket/key from event ---
        bucket_name, key = extract_bucket_and_key(event)

        # Extract filename only (after the last "/")
        filename = key.split('/')[-1]

        # Dataset prefix (before first "_") for config lookup
        dataset_name_prefix = filename.split('_')[0]

        data_config_key = (
            f"{global_config['data_configuration_folder_name']}/"
            f"{dataset_name_prefix}_{global_config['data_configuration_file_name_suffix']}"
        )
        validation_rules = fetch_data_config_from_s3(s3, bucket_name, data_config_key)

        # --- Fetch the uploaded file ---
        file_content = fetch_file_from_s3(s3, bucket_name, key)
        if file_content is None:
            return {
                "statusCode": 400,
                "body": f"File not found or unable to load file content."
            }
        print(f"Info - Successfully retrieved file content from '{bucket_name}/{key}'.")

        # --- Validate file format ---
        if not filename.endswith(validation_rules["file_type"]):
            print(f"Invalid file type - Expected {validation_rules['file_type']}.")
            error_log.write(f"Invalid file type - Expected {validation_rules['file_type']}.\n")

        # ✅ Validate filename by prefix
        expected_prefix = validation_rules["file_name"]

        if not filename.startswith(expected_prefix):
            print(f"Invalid file name - Expected prefix '{expected_prefix}', got '{filename}'.")
            error_log.write(f"Invalid file name - Expected prefix '{expected_prefix}', got '{filename}'.\n")


        # --- Load file into DataFrame ---
        df = pd.read_csv(StringIO(file_content))

        # --- Validate headers ---
        required_columns = validation_rules["column_names"]
        missing_headers = [header for header in required_columns if header not in df.columns]
        if missing_headers:
            print(f"Missing required headers - {missing_headers}.")
            error_log.write(f"Missing required headers - {missing_headers}.\n")

        extra_columns = [col for col in df.columns if col not in required_columns]
        if extra_columns:
            print(f"Extra headers detected - {extra_columns}.")
            error_log.write(f"Extra headers detected - {extra_columns}.\n")

        # --- If there are validation errors ---
        if bool(error_log.getvalue()):
            log_key = log_error_to_s3(s3, bucket_name, key, error_log, global_config['error_report_folder_name'])

            # Move file to rejected folder (preserves subfolders like agency2/)
            rejected_key = key.replace(global_config['landing_folder_name'], global_config['rejected_folder_name'])
            move_file_in_s3(s3, bucket_name, key, rejected_key)

            return {
                "statusCode": 400,
                "body": f"File Validation failed. Error report available at '{bucket_name}/{log_key}'. File moved to '{bucket_name}/{rejected_key}'."
            }

        # --- If validation passed, move to validated folder ---
        validated_key = key.replace(global_config['landing_folder_name'], global_config['file_validated_folder_name'])
        move_file_in_s3(s3, bucket_name, key, validated_key)

        return {
            "statusCode": 200,
            "body": f"File Validation passed. File moved to '{bucket_name}/{validated_key}'."
        }

    except Exception as e:
        # --- On unexpected error, move file to rejected folder ---
        try:
            rejected_key = key.replace(global_config['landing_folder_name'], global_config['rejected_folder_name'])
            move_file_in_s3(s3, bucket_name, key, rejected_key)
            print(f"File moved to rejected due to unexpected error: {e}")
        except Exception as move_err:
            print(f"Failed to move file to rejected: {move_err}")

        return {
            "statusCode": 500,
            "body": f"File Validation failed. Unexpected error: {e}."
        }
