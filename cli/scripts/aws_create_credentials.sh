#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Ensure the environment variable AWS_TERRAFORM_USER is set
if [ -z "${AWS_TERRAFORM_USER}" ]; then
    echo "** Error: The environment variable 'AWS_TERRAFORM_USER' is not set."
    exit 1
fi

# Variables
credentials_file=$CREDENTIAL_FILE

# Function to check if the Access Key exists in AWS
get_access_key_from_aws() {
    aws iam list-access-keys \
        --user-name "$AWS_TERRAFORM_USER" \
        --query 'AccessKeyMetadata[0].AccessKeyId' \
        --output text
}

# Function to retrieve the Access Key ID from the local credentials file
get_access_key_from_json() {
    if [ -f "$credentials_file" ]; then
        jq -r '.AccessKey.AccessKeyId' "$credentials_file"
    else
        echo "None"
    fi
}

# Function to retrieve the Secret Access Key from the local credentials file
get_secret_access_key_from_json() {
    if [ -f "$credentials_file" ]; then
        jq -r '.AccessKey.SecretAccessKey' "$credentials_file"
    else
        echo "None"
    fi
}

# Main Execution
echo "** Checking if access key exists for Terraform user..."

# Retrieve Access Key IDs from AWS and local file
access_key_id_from_aws=$(get_access_key_from_aws)
access_key_id_from_json=$(get_access_key_from_json)

# Function to update or add the ACCESS_KEY_ID in the .env file
update_env_file() {
    local access_key_id=$1
    local env_file=".env"

    # Check if ACCESS_KEY_ID already exists in the .env file
    if grep -q "^ACCESS_KEY_ID=" "$env_file"; then
        echo "** Updating ACCESS_KEY_ID in .env..."
        # Replace the existing ACCESS_KEY_ID value with the new one
        sed -i.bak "s|^ACCESS_KEY_ID=.*|ACCESS_KEY_ID=$access_key_id|" "$env_file"
    else
        echo "** Adding ACCESS_KEY_ID to .env..."
        # If it doesn't exist, append it to the end of the file
        echo "ACCESS_KEY_ID=$access_key_id" >> "$env_file"
    fi
}

echo "** AWS Key ID: $access_key_id_from_aws"
echo "** JSON Key ID: $access_key_id_from_json"

# Compare and handle discrepancies between AWS and local keys
if [[ "$access_key_id_from_aws" == "$access_key_id_from_json" && "$access_key_id_from_aws" != "None" ]]; then
    echo "** Access key is already set and matches the credentials file."
elif [[ "$access_key_id_from_aws" != "None" ]]; then
    echo "** Access key in AWS does not match the credentials file. Recreating the key..."
    # Delete the existing key and remove the local credentials file
    aws iam delete-access-key --user-name "$AWS_TERRAFORM_USER" --access-key-id "$access_key_id_from_aws"
    rm -f "$credentials_file"
    echo "** Deleted existing access key and credentials file. Creating a new key..."
    # Create a new key and save it to the credentials file
    aws iam create-access-key --user-name "$AWS_TERRAFORM_USER" --output json > "$credentials_file"
    echo "** New access key created and saved to $credentials_file."
    update_env_file "$access_key_id_from_aws"
else
    echo "** No existing access key found in AWS. Creating a new key..."
    # Create a new access key
    aws iam create-access-key --user-name "$AWS_TERRAFORM_USER" --output json > "$credentials_file"
    echo "** New access key created and saved to $credentials_file."
fi

# Update the .env file with the new Access Key ID
access_key_id_from_aws=$(get_access_key_from_aws)
update_env_file "$access_key_id_from_aws"

# Write credentials and configuration to the AWS credentials and config files
echo "** Writing credentials to ~/.aws/credentials..."

cat <<EOF > ~/.aws/cred_terraform
[terraform_user]
aws_access_key_id = $(get_access_key_from_json)
aws_secret_access_key = $(get_secret_access_key_from_json)
EOF

cat <<EOF > ~/.aws/config_terraform
[profile $AWS_TERRAFORM_USER]
region = $AWS_REGION
output = json
EOF

echo "** Done."
