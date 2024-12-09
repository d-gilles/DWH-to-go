# All variables must be defined in the .env file

# -----------------------------------------------------------------------------
# AWS Setup
# -----------------------------------------------------------------------------

## Fetch AWS Account ID and store it in the .env file
.PHONY: aws_get_account_id
aws_get_account_id:
	@echo "******************************************"
	@echo "** Fetching AWS Account ID...           **"
	@aws sts get-caller-identity --query "Account" --output text > AWS_ACCOUNT_ID.tmp
	@echo "** Writing AWS Account ID to .env...    **"
	@bash cli/scripts/write_var_to_env.sh AWS_ACCOUNT_ID
	@echo "******************************************"
	@echo ""

## Set up AWS for Terraform
.PHONY: aws_create_terraform_user
aws_create_terraform_user:
	@echo "******************************************"
	@echo "** Setting up AWS for Terraform...      **"
	@bash cli/scripts/setup_aws.sh
	@echo "** AWS setup complete - ready to go!    **"
	@echo "******************************************"
	@echo ""

## Deploy AWS infrastructure using Terraform
.PHONY: aws_terraform
aws_terraform:
	@echo "******************************************"
	@echo "** Deploying AWS infrastructure...      **"
	@cd terraform && terraform apply -auto-approve
	@echo "******************************************"
	@echo ""

## Clean up AWS resources
.PHONY: aws_clean_up
aws_clean_up:
	@echo "******************************************"
	@echo "** Cleaning up AWS resources...         **"
	@echo "** Deleting AWS access key...           **"
	@aws iam delete-access-key --user-name $(AWS_TERRAFORM_USER) --access-key-id $(ACCESS_KEY_ID)
	@echo "** Detaching policy from Terraform user... **"
	@aws iam detach-user-policy --user-name $(AWS_TERRAFORM_USER) --policy-arn $(AWS_TERRAFORM_POLICY_ARN)
	@echo "** Deleting Terraform user...           **"
	@aws iam delete-user --user-name $(AWS_TERRAFORM_USER)
	@echo "** Deleting policy...                   **"
	@aws iam delete-policy --policy-arn $(AWS_TERRAFORM_POLICY_ARN)
	@echo "** Cleaning up environment variables... **"
	@bash cli/scripts/clean_env.sh
	@echo "******************************************"
	@echo ""


# -----------------------------------------------------------------------------
# Snowflake Setup
# -----------------------------------------------------------------------------

## Test connection to Snowflake
.PHONY: snowflake_test
snowflake_test:
	@echo "******************************************"
	@echo "** Testing Snowflake connection...      **"
	@if [ -z "$(SNOWFLAKE_ORGANIZATION_NAME)" ] || [ -z "$(SNOWFLAKE_ACCOUNT_NAME)" ] || [ -z "$(SNOWFLAKE_ADMIN)" ] || [ -z "$(SNOWSQL_PWD)" ]; then \
		echo "** ERROR: Missing required environment variables."; \
		exit 1; \
	else \
		echo "** Environment variables are set."; \
	fi
	@snowsql -u $(SNOWFLAKE_ADMIN) -q "!exit" || { \
		echo "** ERROR: Could not connect to Snowflake."; \
		exit 1; \
	}
	@echo "** Snowflake connection successful!     **"
	@echo "******************************************"

## Create a Terraform user in Snowflake
.PHONY: snowflake_create_terraform_user
snowflake_create_terraform_user:
	@echo "******************************************"
	@echo "** Creating Snowflake Terraform user... **"
	@bash cli/scripts/setup_snowflake.sh
	@echo "** Snowflake Terraform user created.    **"
	@echo "******************************************"

## Set up Snowflake for Terraform
.PHONY: setup_snowflake
setup_snowflake: snowflake_test snowflake_create_terraform_user

## Clean up Snowflake resources
.PHONY: snowflake_clean_up
snowflake_clean_up:
	@echo "******************************************"
	@echo "** Cleaning up Snowflake resources...   **"
	@echo "** Dropping user $(SNOWSQL_USER)...     **"
	@snowsql -u $(SNOWFLAKE_ADMIN) -q "DROP USER IF EXISTS $(SNOWSQL_USER);"
	@echo "** Dropping warehouse $(SNOWFLAKE_WAREHOUSE)... **"
	@snowsql -u $(SNOWFLAKE_ADMIN) -q "DROP WAREHOUSE IF EXISTS $(SNOWFLAKE_WAREHOUSE);"make
	@echo "** Snowflake cleanup complete.          **"
	@echo "******************************************"
	@echo ""

# -----------------------------------------------------------------------------
# Test Data Setup
# -----------------------------------------------------------------------------

## Create a Snowflake warehouse
.PHONY: snowflake_create_dwh
snowflake_create_dwh:
	@snowsql -q \
		"CREATE OR REPLACE WAREHOUSE ${SNOWFLAKE_WAREHOUSE} \
		WAREHOUSE_SIZE = ${SNOWFLAKE_WAREHOUSE_SIZE};"

## Create AWS-Snowflake integration
.PHONY: snowflake_create_integration
snowflake_create_integration:
	@python python/create_aws_snowflake_integration.py

## Load test data into S3
.PHONY: aws_load_test_data
aws_load_test_data:
	@python python/load_test_dataset_to_s3.py

## Create a Snowflake database and test table
.PHONY: snowflake_create_db_and_test_data_table
snowflake_create_db_and_test_data_table:
	@envsubst < sql/import_test_data.sql | snowsql -q "$(cat)"

## Load test data into the platform
.PHONY: test_data
test_data: snowflake_create_dwh snowflake_create_integration aws_load_test_data snowflake_create_db_and_test_data_table

# -----------------------------------------------------------------------------
# Cleanup and Full Reset
# -----------------------------------------------------------------------------

.PHONY: terraform_destroy
terraform_destroy:
	@echo "******************************************"
	@echo "** Starting Terraform and S3 cleanup... **"
	@echo "** Removing all files from S3 bucket: $(TF_VAR_s3_data_lake_bucket_name) **"
	@if [ -z "$(TF_VAR_s3_data_lake_bucket_name)" ]; then \
		echo "Error: S3 bucket name (TF_VAR_s3_data_lake_bucket_name) is not set."; \
		exit 1; \
	fi
	@aws s3 rm s3://$(TF_VAR_s3_data_lake_bucket_name) --recursive || \
		{ echo "Error: Failed to remove files from S3 bucket."; exit 1; }
	@echo "** S3 bucket cleanup complete.          **"
	@echo "** Destroying Terraform-managed resources... **"
	@cd terraform && terraform destroy -auto-approve || \
		{ echo "Error: Terraform destroy failed."; exit 1; }
	@echo "** Terraform destroy complete.          **"
	@echo "******************************************"


## Remove all resources (AWS + Snowflake)
.PHONY: destroy_all
destroy_all: terraform_destroy snowflake_clean_up aws_clean_up 
	@echo "******************************************"
	@echo "** All resources have been removed.     **"
	@echo "******************************************"
