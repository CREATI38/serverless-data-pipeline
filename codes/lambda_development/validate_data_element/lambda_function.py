# Import functions from utility_function.py and validation_function.py
from utility_function import *
from validation_function import *

# Import other necessary python libraries
import boto3
from io import StringIO
import pandas as pd

# Initialize S3 client and global configuration
s3 = boto3.client('s3')
global_config = None

# Function to set global variables
def set_globals():
    # Set global configuration variables
    global global_config
    if global_config is None:
        global_config = {
            # 'full' only accepts the entire dataset if all rows passes validation. 'partial' accepts validated rows even if others are fails validation.
            "full_or_partial": "full",
            "data_configuration_file_name_suffix": "data_configuration_file.json",
            "data_configuration_folder_name": "data-configuration-files",
            "rejected_folder_name": "rejected-files/",
            "log_folder_name": "error-reports/",
            "file_validation_folder_name": "2-file-validated-zone/",
            "data_element_validation_folder_name": "3-data-element-validated-zone/"
        }
        print("Info - Global configuration initialized.")

# ========================================================
# Main Data Element Validation Function
# ========================================================

def lambda_handler(event, context):
    try:
        print("Info - Starting Data Element Validation..")
        # Initialize and set global variables
        error_log = StringIO()
        set_globals()

        # Extract bucket name and file key and fetch data
        bucket_name, key = extract_bucket_and_key(event)
        file_content = fetch_file_from_s3(s3, bucket_name, key)
        # Return error if file is not found
        if file_content is None:
            return {
                "statusCode": 400,
                "body": (f"File not found or unable to load file content.")
            }
        print(f"Info - Sucessfully retrieved file content from '{bucket_name}/{key}'.")

        # Fetch validation rule json configuration file
        dataset_name_prefix = key.split('/')[-1].split('_')[0]
        json_file_key = (
            f"{global_config['data_configuration_folder_name']}/"
            f"{dataset_name_prefix}_{global_config['data_configuration_file_name_suffix']}"
        )
        validation_rules = fetch_data_config_from_s3(s3, bucket_name, json_file_key)
        # Return error if data configuration file is not found
        if validation_rules is None:
            return {
                "statusCode": 400,
                "body": f"Unable to retrieve data configuration file '{bucket_name}/{json_file_key}'."
            }
        print(f"Info - Sucessfully retrieved data configuration file '{bucket_name}/{json_file_key}'.")

        # Load defined data type dictionary and set as DataFrame schema
        dtype_dict = {col: rule["validate_data_type"] for col, rule in validation_rules["data_validation"].items()}
        df = pd.read_csv(StringIO(file_content), dtype=dtype_dict)

        # Validate the data
        validated_data, error_log = validate_dataset(df, validation_rules, error_log)

        # Set keys to move datasets to
        validated_key = key.replace(global_config['file_validation_folder_name'], global_config['data_element_validation_folder_name'])
        rejected_key = key.replace(global_config['file_validation_folder_name'], global_config['rejected_folder_name'])

        # If there are errors, log it into error-reports folder
        if bool(error_log.getvalue()):
            log_key = log_error_to_s3(s3, bucket_name, key, error_log, global_config['log_folder_name'])
            # If we allow partial dataset to flow through the pipeline, save only succesful rows to data element validated zone.
            # Original dataset will still be moved to rejected - because our error report goes by rows of the original dataset.
            if global_config['full_or_partial'] == "partial":
                move_file_in_s3(s3, bucket_name, key, rejected_key)
                save_file_in_s3(s3, bucket_name, validated_key, validated_data.to_csv(index=False))
                print(f"Data Element Validation passed partially. Error report available at '{bucket_name}/{log_key}'. Partial file moved to '{bucket_name}/{validated_key}'")
                return {
                    "statusCode": 201,
                    "body": f"Data Element Validation passed partially. Error report available at '{bucket_name}/{log_key}'. Partial file moved to '{bucket_name}/{validated_key}'."
                }
            # Else, we move the entire dataset to rejected folder
            else:
                move_file_in_s3(s3, bucket_name, key, rejected_key)
                print(f"Data Element Validation failed. Error report available at '{bucket_name}/{log_key}'. File moved to '{bucket_name}/{rejected_key}'.")
                return {
                    "statusCode": 400,
                    "body": f"Data Element Validation failed. Error report available at '{bucket_name}/{log_key}'. File moved to '{bucket_name}/{rejected_key}'. "
                }
            
        # If file success then move file to data element validated zone
        move_file_in_s3(s3, bucket_name, key, validated_key)
        print(f"Data Element Validation passed. File moved to {global_config['data_element_validation_folder_name']}.")
        return {
            "statusCode": 200,
            "body": f"Data Element Validation passed. File moved to {global_config['data_element_validation_folder_name']}."
        }

    except Exception as e:
        # Log the errors as a txt file in S3 and move dataset to rejected folder
        rejected_key = key.replace(global_config['file_validation_folder_name'], global_config['rejected_folder_name'])
        rejected_key = move_file_in_s3(s3, bucket_name, key, rejected_key)
        
        print(f"File Validation failed. An unexpected error occurred: {e}.")
        return {
            'statusCode': 500,
            'body': f"File Validation failed. An unexpected error occurred: {e}."
        }
