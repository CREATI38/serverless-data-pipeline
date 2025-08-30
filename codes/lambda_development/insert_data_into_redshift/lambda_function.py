import boto3
import logging
from utility_function import *

# Set up logging
logging.basicConfig(level=logging.INFO)

# Initialize the Redshift Data API client
client = boto3.client('redshift-data', region_name='ap-southeast-1')  # Ensure correct region

# Redshift Serverless configuration
redshift_workgroup_name = os.environ['redshift_workgroup_name']
database_name = 'dev'
iam_role_arn = os.environ['iam_role_arn']

def lambda_handler(event, context):
    try:
        # Extract the file name from the event (from S3)
        bucket_name, key = extract_bucket_and_key(event)

        # Determine the table name based on the file name
        schema_name = "sm_covid_recovery"
        table_name = get_table_name_from_file(key)
        if table_name is None:
            print(f"No table name set for current dataset '{bucket_name}/{key}'.")

        # Copy data from S3 to Redshift
        copy_query = f"""
            -- Truncate the table before loading new data
            TRUNCATE TABLE {schema_name}.{table_name};
            -- Copy data from S3 to Redshift
            COPY {schema_name}.{table_name}
            FROM 's3://{bucket_name}/{key}'
            IAM_ROLE '{iam_role_arn}'
            CSV IGNOREHEADER 1;
        """

        print(f"Executing SQL copy query: {copy_query}")

        secret_arn = os.environ['secret_arn']
        execute_redshift_query(copy_query, client, redshift_workgroup_name, database_name, secret_arn)

        return {
            "statusCode": 200,
            "body": f"File content from {bucket_name}/{key} copied to Redshift processed successfully."
        }

    except Exception as e:
        print(f"Load data to Redshift failed. An unexpected error occurred: {e}.")
        return {
            'statusCode': 500,
            'body': f"Load data to Redshift failed. An unexpected error occurred: {e}."
        }
