#!/bin/bash

# Check if the file ~/.ssh/snowflake_tf_snow_key.pub exists
if [ ! -f ~/.ssh/snowflake_tf_snow_key.pub ]; then
    echo "Public key not found. Generating new Snowflake keys..."
    cd ~/.ssh || exit 1  # Ensure the directory change is successful, exit if not
    openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_tf_snow_key.p8 -nocrypt
    openssl rsa -in snowflake_tf_snow_key.p8 -pubout -out snowflake_tf_snow_key.pub
else
    echo "Public key already exists. Skipping key generation."
fi

# Extract the public key, removing the header and footer, and remove newline characters
RSA_PUBLIC_KEY=$(sed '1d;$d' ~/.ssh/snowflake_tf_snow_key.pub | tr -d '\n')

# Define the SQL query
SQL_QUERY=" 
        create or replace USER \"$SNOWFLAKE_USER\" 
                RSA_PUBLIC_KEY='$RSA_PUBLIC_KEY' 
                DEFAULT_ROLE=PUBLIC 
                MUST_CHANGE_PASSWORD=FALSE;
        GRANT ROLE SYSADMIN TO USER \"$SNOWFLAKE_USER\";
        GRANT ROLE SECURITYADMIN TO USER \"$SNOWFLAKE_USER\";"
# Execute the SQL command using SnowSQL
snowsql -a "$SNOWFLAKE_ACCOUNT_IDENTIFIER" -u "$SNOWFLAKE_ADMIN" -q "$SQL_QUERY"
