#!/bin/bash

# Path to the .env file
ENV_FILE=".env"

# Check if the .env file exists
if [[ ! -f "$ENV_FILE" ]]; then
  echo "The file $ENV_FILE was not found!"
  exit 1
fi

# Reset specific environment variable rows in the .env file
sed -i.bak \
    -e 's/^AWS_ACCOUNT_ID=.*/AWS_ACCOUNT_ID=/' \
    -e 's/^AWS_TERRAFORM_USER_ARN=.*/AWS_TERRAFORM_USER_ARN=/' \
    -e 's/^AWS_TERRAFORM_POLICY_ARN=.*/AWS_TERRAFORM_POLICY_ARN=/' \
    -e 's/^ACCESS_KEY_ID=.*/ACCESS_KEY_ID=/' \
    "$ENV_FILE"

# Success message
echo "The values in $ENV_FILE have been successfully cleared."
echo "A backup of the original file has been saved as $ENV_FILE.bak."
