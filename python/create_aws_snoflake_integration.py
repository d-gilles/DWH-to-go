# imports
import boto3
import os
import snowflake.connector
from dotenv import load_dotenv
import pandas as pd
import json

# load .env
load_dotenv()

# set variables
os.environ["AWS_CONFIG_FILE"] = "~/.aws/config_terraform"
os.environ["AWS_SHARED_CREDENTIALS_FILE"] = "~/.aws/cred_terraform"
SNOWFLAKE_ORGANIZATION_NAME = os.getenv('SNOWFLAKE_ORGANIZATION_NAME')
SNOWFLAKE_ACCOUNT_NAME = os.getenv('SNOWFLAKE_ACCOUNT_NAME')
aws_region = os.getenv('AWS_REGION')
aws_profile = os.getenv('AWS_TERRAFORM_USER')
role_name= "snowflake_role"

# create boto3 session
aws_session = boto3.Session(profile_name=aws_profile)

# create iam client
iam_client = aws_session.client('iam')
print("AWS session established, IAM client created")

# create snowflake session
sf_session = snowflake.connector.connect(
    user= os.getenv('SNOWFLAKE_ADMIN'),              
    password= os.getenv('SNOWSQL_PWD'),           
    account= f"{SNOWFLAKE_ORGANIZATION_NAME}-{SNOWFLAKE_ACCOUNT_NAME}",
    role='ACCOUNTADMIN'                   
)
print("Snowflake session established")

# would be nice to get the results of snowflake as a pandas df
def get_table(q): 
    # executes a given query and gives back the result as a DataFrame
    cur = sf_session.cursor()
    cur.execute(q)
    desc = cur.description
    content = cur.fetchall()
    columns = []
    for i in desc:
        columns.append(i[0])
    cur.close()
    return pd.DataFrame(content, columns=columns).set_index(columns[0])

snowflake_role = iam_client.get_role(RoleName='Snowflake_Role')
snowflake_role_arn = snowflake_role['Role']['Arn']
s3_uri = f"s3://{os.getenv('PROJECT_NAME')}-i{os.getenv('ITERATION')}-data-lake/staging"

# create s3 storage integration
create_s3_integration = f"""
    CREATE STORAGE INTEGRATION s3_storage_integration
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = '{snowflake_role_arn}'
    STORAGE_ALLOWED_LOCATIONS = ('{s3_uri}');"""
try:
    get_table(create_s3_integration)
    print("S3 Storage Integration Created")
except Exception as e:
    print(e)
    
q ="DESC INTEGRATION s3_storage_integration;"
s3_integration_properties = get_table(q)

STORAGE_AWS_IAM_USER_ARN = s3_integration_properties.loc['STORAGE_AWS_IAM_USER_ARN','property_value']
STORAGE_AWS_EXTERNAL_ID	= s3_integration_properties.loc['STORAGE_AWS_EXTERNAL_ID','property_value']

# change the Trusted entities in the AssumeRolePolity
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


# Update the AssumeRolePolicy of the Snowflake_Role
try:
    iam_client.update_assume_role_policy(
        RoleName=role_name,
        PolicyDocument=json.dumps(new_assume_role_policy_document)
    )
    print(f"AssumeRolePolicy der Rolle {role_name} erfolgreich aktualisiert.")
except Exception as e:
    print(f"Fehler beim Aktualisieren der Rolle: {e}")

