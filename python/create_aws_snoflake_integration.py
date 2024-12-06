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
role_name = "snowflake_role"

# create boto3 session
aws_session = boto3.Session(profile_name=aws_profile)

# create iam client
iam_client = aws_session.client('iam')

# create snowflake session
sf_session = snowflake.connector.connect(
    user=os.getenv('SNOWFLAKE_ADMIN'),
    password=os.getenv('SNOWSQL_PWD'),
    account=f"{SNOWFLAKE_ORGANIZATION_NAME}-{SNOWFLAKE_ACCOUNT_NAME}",
    role='ACCOUNTADMIN'
)

# Methode, um SQL-Abfragen auszuführen und Ergebnisse als DataFrame zurückzugeben
def get_table(query): 
    # Executes a given query and returns the result as a DataFrame
    cur = sf_session.cursor()
    statements = [stmt.strip() for stmt in query.split(';') if stmt.strip()]
    
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
    return #pd.DataFrame(content, columns=columns).set_index(columns[0])

# Code, der nur ausgeführt wird, wenn dieses Skript direkt gestartet wird
if __name__ == "__main__":
    print("AWS session established, IAM client created")
    print("Snowflake session established")

    # Beispiel-Code für die Erstellung einer S3 Storage Integration
    snowflake_role = iam_client.get_role(RoleName='Snowflake_Role')
    snowflake_role_arn = snowflake_role['Role']['Arn']
    s3_uri = f"s3://{os.getenv('PROJECT_NAME')}-i{os.getenv('ITERATION')}-data-lake/staging"

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
        
    q = "DESC INTEGRATION s3_storage_integration;"
    s3_integration_properties = get_table(q)
    print(s3_integration_properties)

    STORAGE_AWS_IAM_USER_ARN = s3_integration_properties.loc['STORAGE_AWS_IAM_USER_ARN', 'property_value']
    STORAGE_AWS_EXTERNAL_ID = s3_integration_properties.loc['STORAGE_AWS_EXTERNAL_ID', 'property_value']

    # Update AssumeRolePolicy
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
        iam_client.update_assume_role_policy(
            RoleName=role_name,
            PolicyDocument=json.dumps(new_assume_role_policy_document)
        )
        print(f"AssumeRolePolicy der Rolle {role_name} erfolgreich aktualisiert.")
    except Exception as e:
        print(f"Fehler beim Aktualisieren der Rolle: {e}")
