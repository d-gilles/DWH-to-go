# All variables need to be declared in the .env file

# Setup AWS

# get aws account id this needs to be executed separately at the beginning
.PHONY: aws_get_account_id
aws_get_account_id:
	@echo "******************************************"
	@echo "**  Fetching AWS Account ID...  "
	@aws sts get-caller-identity --query "Account" --output text > AWS_ACCOUNT_ID.tmp
	@echo "** Writing AWS Account ID to .env..."
	@bash cli/scripts/write_var_to_env.sh AWS_ACCOUNT_ID
	@echo "******************************************"
	@echo " " 
	
# This command contains all it needs to setup aws from terraform
.PHONY: setup_aws 
setup_aws: 
	@echo "******************************************"
	@echo "**  Setting up AWS cloud for Terraform "
	@bash cli/scripts/setup_aws.sh 
	@echo "**" 
	@echo "**  all set - good to go!"
	@echo "******************************************"
	@echo " " 
	

# if all components need to be removed
aws_clean_up:
	aws iam delete-access-key --user-name $(AWS_TERRAFORM_USER) --access-key-id $(ACCESS_KEY_ID)
	aws iam detach-user-policy --user-name $(AWS_TERRAFORM_USER) --policy-arn $(AWS_TERRAFORM_POLICY_ARN)
	aws iam delete-user --user-name $(AWS_TERRAFORM_USER)
	aws iam delete-policy --policy-arn $(AWS_TERRAFORM_POLICY_ARN)
	bash cli/scripts/clean_env.sh

# # SNOWFLAKE
# ## test snowflake 
# .PHONY: test_snowflake
# test_snowflake: 
# 	@echo "Testing Snowflake connection"
# 	@echo "Check if all variables are set..."
# 	@if [ -z "$(SNOWFLAKE_ACCOUNT_IDENTIFIER)" ] || [ -z "$(SNOWFLAKE_ADMIN)" ] || [ -z "$(SNOWSQL_PWD)" ]; then \
# 		echo "Fehler: Eine oder mehrere erforderliche Variablen sind nicht gesetzt (SNOWFLAKE_ACCOUNT_IDENTIFIER, SNOWFLAKE_ADMIN, SNOWSQL_PWD)."; \
# 		exit 1; \
# 	else \
# 		echo "OK"; \
# 	fi
# 	@echo "Initialize connection to Snowflake"
# 	@echo ""
# 	@snowsql -a $(SNOWFLAKE_ACCOUNT_IDENTIFIER) -u $(SNOWFLAKE_ADMIN) -q "!exit"; \
# 	if [ $$? -ne 0 ]; then \
# 		echo "Fehler: Verbindung zu Snowflake konnte nicht hergestellt werden."; \
# 		echo "Überprüfe folgende Punkte:"; \
# 		echo "  1. Ist der Snowflake Account-Identifier korrekt? ($(SNOWFLAKE_ACCOUNT_IDENTIFIER))"; \
# 		echo "  2. Existiert der Benutzer? ($(SNOWFLAKE_ADMIN))"; \
# 		echo "  3. Ist das Passwort korrekt (falls erforderlich)?"; \
# 		exit 1; \
# 	fi
# 	@echo "OK"
# 	@echo "Connection test pass!"

# ## Create terraform user in Snowfalke
# .PHONY: create_user_snowflake
# create_user_snowflake:
# 	@echo "Erstelle Terraform-Benutzer in Snowflake..."
# 	snowsql -a $(SNOWFLAKE_ACCOUNT_IDENTIFIER) -u $(SNOWFLAKE_ADMIN) -q \
# 		"CREATE OR REPLACE USER $(SNOWFLAKE_TERRAFORM_USER) PASSWORD = '$(SNOWFLAKE_TERRAFORM_PASSWORD)' \
# 		DEFAULT_ROLE = PUBLIC \
# 		MUST_CHANGE_PASSWORD = FALSE \
# 		COMMENT = 'User for Terraform integration'; \
# 		GRANT ROLE ACCOUNTADMIN TO USER $(SNOWFLAKE_TERRAFORM_USER);"

# # setup snowflake
# .PHONY: setup_snowflake
# setup_snowflake: test_snowflake create_user


# .PHONY: clean
# clean: clean_snowflake

# .PHONY: clean_snowflake
# clean_snowflake:
# 	@echo "drop terraform user from snowflake"
# 	snowsql -a $(SNOWFLAKE_ACCOUNT_IDENTIFIER) -u $(SNOWFLAKE_ADMIN) -q \
# 		"DROP USER $(SNOWFLAKE_TERRAFORM_USER);"