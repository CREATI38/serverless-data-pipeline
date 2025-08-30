import json
from botocore.exceptions import ClientError
from datetime import datetime
import pytz
import os

# ========================================================
# Utility Functions
# ========================================================

def extract_bucket_and_key(event: dict):
    """
    Extracts the S3 bucket name and object key json event.

    Args:
        event (dict): The event object, typically passed from AWS Lambda for S3 triggers.
        
    Returns:
        tuple: A tuple containing the S3 bucket name and object key.
    """
    record = event["Records"][0]
    return record["s3"]["bucket"]["name"], record["s3"]["object"]["key"]

def fetch_file_from_s3(s3, bucket_name: str, key: str):
    """
    Fetches the file content from an S3 bucket.

    Args:
        s3 (boto3.client): A Boto3 S3 client.
        bucket_name (str): The name of the S3 bucket.
        key (str): The key (path) of the S3 object.

    Returns:
        str: The file content as a string if successful; None if an error occurs.
    
    Raises:
        ClientError: If an error occurs while fetching the file.
    """
    try:
        response = s3.get_object(Bucket=bucket_name, Key=key)
        return response["Body"].read().decode("utf-8")
    except ClientError as e:
        # Check if it's a 'NoSuchKey' error indicating the file does not exist
        # If data configuration file does not exist, print + log error message
        if e.response['Error']['Code'] == 'NoSuchKey':
            print(f"Error - The file '{key}' does not exist in the bucket '{bucket_name}'.")
        else:
            # Handle other exceptions
            print(f"Error - An unexpected error occurred: {e}")
        return None

# Fetch data configuration file from S3 folder
def fetch_data_config_from_s3(s3, bucket_name: str, key: str):
    """
    Fetches a JSON data configuration file from an S3 bucket and parses it.

    Args:
        s3 (boto3.client): A Boto3 S3 client.
        bucket_name (str): The name of the S3 bucket.
        key (str): The key (path) of the S3 object.

    Returns:
        dict: The parsed JSON configuration if successful; None if an error occurs.
    
    Raises:
        ClientError: If an error occurs while fetching the data configuration file.
    """
    try:
        response = s3.get_object(Bucket=bucket_name, Key=key)
        return json.loads(response["Body"].read().decode("utf-8"))
    except ClientError as e:
        # Check if it's a 'NoSuchKey' error indicating the file does not exist
        # If data configuration file does not exist, print + log error message
        if e.response['Error']['Code'] == 'NoSuchKey':
            print(f"Error - The data configuration '{key}' does not exist in the bucket '{bucket_name}'.")
        else:
            # Handle other exceptions
            print(f"Error - An unexpected error occurred: {e}\n")
        return None

# Save files in S3 using put and then deleting the previous file - Used when new file content is different
def save_file_in_s3(s3, bucket_name: str, new_key: str, content):
    """
    Saves content to an S3 bucket under the specified key.

    Args:
        s3 (boto3.client): A Boto3 S3 client.
        bucket_name (str): The name of the S3 bucket.
        new_key (str): The key (path) under which the file should be saved.
        content (str): The content to be saved to the S3 object.
    """
    s3.put_object(Bucket=bucket_name, Key=new_key, Body=content)

# Move files in S3 using S3 copy and delete - Used when new file content is the same
def move_file_in_s3(s3, bucket_name: str, old_key: str, new_key: str):
    """
    Moves a file within an S3 bucket by copying it to a new location and deleting the old file.

    Args:
        s3 (boto3.client): A Boto3 S3 client.
        bucket_name (str): The name of the S3 bucket.
        old_key (str): The key (path) of the existing S3 object.
        new_key (str): The key (path) for the new location of the S3 object.
    """
    s3.copy_object(Bucket=bucket_name, CopySource={'Bucket': bucket_name, 'Key': old_key}, Key=new_key)
    s3.delete_object(Bucket=bucket_name, Key=old_key)

# Upload error logs as a .txt file to log folder - timestamp of pipeline run will be appended at the back
def log_error_to_s3(s3, bucket_name: str, key: str, error_log, log_folder: str = "error-reports/"):
    """
    Uploads an error log as a .txt file to an S3 bucket with a timestamp.

    Args:
        s3 (boto3.client): A Boto3 S3 client.
        bucket_name (str): The name of the S3 bucket.
        key (str): The key (path) of the original file related to the error.
        error_log (StringIO): The error log as an in-memory file-like object.
        log_folder (str, optional): The folder within the bucket where the log should be saved. Defaults to "error-reports/".

    Returns:
        str: The key (path) of the uploaded error log file in S3.
    """
    timestamp = datetime.now(pytz.timezone('Asia/Singapore')).strftime("%Y%m%d_%H%M%S")
    base_name = os.path.splitext(os.path.basename(key))[0]
    log_key = f'{log_folder}{base_name}_error_log_{timestamp}.txt'
    # Reset the pointer to the beginning of the buffer
    error_log.seek(0)
    error_log = error_log.getvalue().encode('utf-8')
    s3.put_object(Bucket=bucket_name, Key=log_key, Body=error_log, ContentType='text/plain')
    return log_key

# Not currently in use (For when data type in data configuration file does not match Pandas DataFrame data types)
def map_data_types_to_dtype(data_types: dict):
    """
    Maps data types from a configuration dictionary to pandas' dtype equivalents.

    Args:
        data_types (dict): A dictionary where the key is the column name and the value is the data type as a string.

    Returns:
        dict: A dictionary where the key is the column name and the value is the corresponding pandas dtype.
    
    Raises:
        ValueError: If an unsupported data type is encountered.
    """
    dtype_dict = {}
    for column, column_type in data_types.items():  # key - value pairs 
        if column_type == "string":
            dtype_dict[column] = "string"
        elif column_type == "integer":
            dtype_dict[column] = "int64"
        elif column_type == "float":
            dtype_dict[column] = "float64"
        else:
            raise ValueError(f"Unsupported data type {column_type} for column {column}")
    return dtype_dict
