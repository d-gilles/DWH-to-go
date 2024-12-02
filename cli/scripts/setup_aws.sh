#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Function: Check dependencies
aws_check_dependencies() {
    echo "** "
    echo "** Checking if all required AWS variables are set..."
    bash cli/scripts/check_vars.sh AWS AWS_ACCOUNT_ID AWS_TERRAFORM_USER AWS_TERRAFORM_POLICY CREDENTIAL_FILE
}

# Function: Create or fetch the Terraform user
aws_create_terraform_user() {
    echo "** Checking if Terraform user exists..."
    if aws iam get-user --user-name "${AWS_TERRAFORM_USER}" > /dev/null 2>&1; then
        echo "** Terraform user ${AWS_TERRAFORM_USER} already exists."
        aws iam get-user --user-name "${AWS_TERRAFORM_USER}" --query 'User.Arn' --output text > AWS_TERRAFORM_USER_ARN.tmp
    else
        echo "** Creating Terraform user..."
        aws iam create-user --user-name "${AWS_TERRAFORM_USER}" --query 'User.Arn' --output text > AWS_TERRAFORM_USER_ARN.tmp
    fi
    bash cli/scripts/write_var_to_env.sh AWS_TERRAFORM_USER_ARN
}

# Function: Create or fetch the Terraform policy
aws_create_terraform_policy() {
    echo "**"
    echo "** Checking if Terraform policy exists..."
    policy_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${AWS_TERRAFORM_POLICY}"
    if aws iam get-policy --policy-arn "${policy_arn}" > /dev/null 2>&1; then
        echo "** Terraform policy ${AWS_TERRAFORM_POLICY} already exists."
        aws iam get-policy --policy-arn "${policy_arn}" --query 'Policy.Arn' --output text > AWS_TERRAFORM_POLICY_ARN.tmp
    else
        echo "** Creating Terraform policy..."
        aws iam create-policy \
            --policy-name "${AWS_TERRAFORM_POLICY}" \
            --policy-document file://cli/scripts/terraform-policy.json \
            --query 'Policy.Arn' --output text > AWS_TERRAFORM_POLICY_ARN.tmp
    fi
    bash cli/scripts/write_var_to_env.sh AWS_TERRAFORM_POLICY_ARN
}

# Function: Attach the Terraform policy to the user
aws_attach_terraform_policy_to_user() {
    echo "**"
    echo "** Checking if policy is already attached to the Terraform user..."
    policy_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${AWS_TERRAFORM_POLICY}"
    if aws iam list-attached-user-policies --user-name "${AWS_TERRAFORM_USER}" \
        --query "AttachedPolicies[?PolicyArn=='${policy_arn}'].PolicyArn" --output text | grep -q "${policy_arn}"; then
        echo "** Policy ${AWS_TERRAFORM_POLICY} is already attached to the Terraform user."
    else
        echo "** Attaching policy ${AWS_TERRAFORM_POLICY} to the Terraform user..."
        aws iam attach-user-policy --user-name "${AWS_TERRAFORM_USER}" --policy-arn "${policy_arn}"
    fi
}

# Function: Create AWS credentials for the Terraform user
aws_create_credentials() {
    echo "**"
    echo "** Creating AWS credentials for Terraform user..."
    bash ./cli/scripts/aws_create_credentials.sh
}

# Call the functions in order
aws_check_dependencies
aws_create_terraform_user
aws_create_terraform_policy
aws_attach_terraform_policy_to_user
aws_create_credentials
