#!/bin/bash

# Path to .env
ENV_FILE=".env"

# Check if the file exists
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Die Datei $ENV_FILE wurde nicht gefunden!"
  exit 1
fi

# Reset rows
sed -i.bak \
    -e 's/^AWS_ACCOUNT_ID=.*/AWS_ACCOUNT_ID=/' \
    -e 's/^AWS_TERRAFORM_USER_ARN=.*/AWS_TERRAFORM_USER_ARN=/' \
    -e 's/^AWS_TERRAFORM_POLICY_ARN=.*/AWS_TERRAFORM_POLICY_ARN=/' \
    -e 's/^ACCESS_KEY_ID=.*/ACCESS_KEY_ID=/' \
    "$ENV_FILE"

# succes message
echo "Die Werte in $ENV_FILE wurden erfolgreich geleert."
echo "Eine Sicherung der ursprünglichen Datei wurde unter $ENV_FILE.bak gespeichert."
