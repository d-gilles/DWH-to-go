#!/bin/bash

# Define the SQL query
SQL_QUERY=" 
        create or replace USER \"$SNOWFLAKE_USER\" 
                PASSWORD='$SNOWSQL_PWD' 
                DEFAULT_ROLE=PUBLIC 
                MUST_CHANGE_PASSWORD=FALSE;
        GRANT ROLE SYSADMIN TO USER \"$SNOWFLAKE_USER\";
        GRANT ROLE ACCOUNTADMIN TO USER \"$SNOWFLAKE_USER\";
        GRANT ROLE SECURITYADMIN TO USER \"$SNOWFLAKE_USER\";"
# Execute the SQL command using SnowSQL
snowsql -u "$SNOWFLAKE_ADMIN" -q "$SQL_QUERY"
