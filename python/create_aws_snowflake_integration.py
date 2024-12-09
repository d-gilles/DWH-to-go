# Necessary imports
import boto3
import os
import snowflake.connector
from dotenv import load_dotenv
import pandas as pd
import json

# Load environment variables from .env file
load_dotenv()

# Set environment variables for AWS configuration
os.environ["AWS_CONFIG_FILE"] = "~/.aws/config_terraform"
os.environ["AWS_SHARED_CREDENTIALS_FILE"] = "~/.aws/cred_terraform"

# Retrieve environment variables for Snowflake and AWS
SNOWFLAKE_ORGANIZATION_NAME = os.getenv('SNOWFLAKE_ORGANIZATION_NAME')
SNOWFLAKE_ACCOUNT_NAME = os.getenv('SNOWFLAKE_ACCOUNT_NAME')
aws_region = os.getenv('AWS_REGION')
aws_profile = os.getenv('AWS_TERRAFORM_USER')
role_name = "snowflake_role"

# Initialize a Boto3 session with the specified AWS profile
aws_session = boto3.Session(profile_name=aws_profile)

# Create an IAM client from the AWS session
iam_client = aws_session.client('iam')

# Create a Snowflake session using credentials from environment variables
sf_session = snowflake.connector.connect(
    user=os.getenv('SNOWFLAKE_ADMIN'),
    password=os.getenv('SNOWSQL_PWD'),
    account=f"{SNOWFLAKE_ORGANIZATION_NAME}-{SNOWFLAKE_ACCOUNT_NAME}",
    role='ACCOUNTADMIN',
    warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
    database=os.getenv('SNOWFLAKE_DATABASE_NAME'),
    schema='ECOMMERCE'
)

# Helper function to execute SQL queries in Snowflake and return results as a DataFrame
def get_table(query): 
    """
    Executes a given SQL query on Snowflake and returns the result as a DataFrame.
    Each query is split into individual statements if multiple are provided.
    """
    cur = sf_session.cursor()
    # Split query into individual statements
    statements = [stmt.strip() for stmt in query.split(';') if stmt.strip()]
    
    # Execute each statement and print the result
    for stmt in statements:
        print(f"Executing statement:\n{stmt}")
        cur.execute(stmt)
        desc = cur.description
        content = cur.fetchall()
        columns = [i[0] for i in desc]
        print('\n')
        print(pd.DataFrame(content, columns=columns).set_index(columns[0]))
        print('\n')
    cur.close()
    # Return results as a DataFrame
    return pd.DataFrame(content, columns=columns).set_index(columns[0])

# Main script logic
if __name__ == "__main__":
    print("AWS session established, IAM client created")
    print("Snowflake session established")

    # Example: Create an S3 Storage Integration in Snowflake
    snowflake_role = iam_client.get_role(RoleName='Snowflake_Role')
    snowflake_role_arn = snowflake_role['Role']['Arn']
    s3_uri = f"s3://{os.getenv('PROJECT_NAME')}-i{os.getenv('ITERATION')}-data-lake/staging"

    create_s3_integration = f"""
        CREATE or replace STORAGE INTEGRATION s3_storage_integration
        TYPE = EXTERNAL_STAGE
        STORAGE_PROVIDER = 'S3'
        ENABLED = TRUE
        STORAGE_AWS_ROLE_ARN = '{snowflake_role_arn}'
        STORAGE_ALLOWED_LOCATIONS = ('{s3_uri}');
    """
    try:
        # Execute the query to create S3 storage integration
        get_table(create_s3_integration)
        print("S3 Storage Integration Created")
    except Exception as e:
        print(e)
        
    # Describe the integration to retrieve its properties
    q = "DESC INTEGRATION s3_storage_integration;"
    s3_integration_properties = get_table(q)

    # Extract the IAM user ARN and external ID for the integration
    STORAGE_AWS_IAM_USER_ARN = s3_integration_properties.loc['STORAGE_AWS_IAM_USER_ARN', 'property_value']
    STORAGE_AWS_EXTERNAL_ID = s3_integration_properties.loc['STORAGE_AWS_EXTERNAL_ID', 'property_value']
    print(f"STORAGE_AWS_IAM_USER_ARN: {STORAGE_AWS_IAM_USER_ARN}")
    print(f"STORAGE_AWS_EXTERNAL_ID: {STORAGE_AWS_EXTERNAL_ID}")

    # Update the AssumeRole policy for the Snowflake role
    new_assume_role_policy_document = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"AWS": STORAGE_AWS_IAM_USER_ARN},
                "Action": "sts:AssumeRole",
                "Condition": {"StringEquals": {"sts:ExternalId": STORAGE_AWS_EXTERNAL_ID}}
            }
        ]
    }

    try:
        # Update the role's AssumeRolePolicyDocument
        iam_client.update_assume_role_policy(
            RoleName=role_name,
            PolicyDocument=json.dumps(new_assume_role_policy_document)
        )
        print(f"Successfully updated AssumeRolePolicy for role {role_name}.")
    except Exception as e:
        print(f"Error updating the role: {e}")
