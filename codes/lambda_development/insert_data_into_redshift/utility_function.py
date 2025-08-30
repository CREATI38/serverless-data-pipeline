import os

def extract_bucket_and_key(event):
    """
    Extracts the S3 bucket name and object key json event.

    Args:
        event (dict): The event object, typically passed from AWS Lambda for S3 triggers.
        
    Returns:
        tuple: A tuple containing the S3 bucket name and object key.
    """
    try:
        record = event["Records"][0]
        return record["s3"]["bucket"]["name"], record["s3"]["object"]["key"]
    except Exception as e:
        raise ValueError(f"Unable to retrieve file in S3: {e}")
    
def get_table_name_from_file(key):
    """
    If the file contains 'mom', use the 'crispr_mom_mock' table.
    If the file contains 'moe', use the 'crispr_moe_mock' table.
    """
    file_name = os.path.splitext(os.path.basename(key))[0]
    if 'mom' in file_name.lower():
        return 'bt_mom_workforce'
    elif 'moe' in file_name.lower():
        return 'bt_moe_primary_school_students'
    else:
        return None
    
def execute_redshift_query(query, client, redshift_workgroup_name, database_name, secret_arn):
    """
    Executes a SQL query using the Redshift Data API.
    """
    response = client.execute_statement(
        WorkgroupName=redshift_workgroup_name,
        Database=database_name,
        Sql=query,
        SecretArn=secret_arn
    )
    # Wait for the query to complete
    statement_id = response['Id']
    print(f"Query started. Statement ID: {statement_id}")
    while True:
        status = client.describe_statement(Id=statement_id)['Status']
        if status == 'FINISHED':
            print(f"Success - Query executed successfully.")
            break
        if status == 'FAILED':
            error_message = client.describe_statement(Id=statement_id)['Error']
            print(f"Error - Query failed with message: {error_message}")
            raise Exception(f"Query failed: {status}")
        