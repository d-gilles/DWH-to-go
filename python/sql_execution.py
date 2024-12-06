# imports
import snowflake.connector
from dotenv import load_dotenv
import os
import argparse
import pandas as pd
from create_aws_snoflake_integration import get_table
import sys

# load .env
load_dotenv()

SNOWFLAKE_ORGANIZATION_NAME = os.getenv('SNOWFLAKE_ORGANIZATION_NAME')
SNOWFLAKE_ACCOUNT_NAME = os.getenv('SNOWFLAKE_ACCOUNT_NAME')

parser = argparse.ArgumentParser(
description=("""
This python code executes a SQL statement against a Snowflake database.\n
You need to pass a statement. You can do this by passing a string:\n
    -s "SELECT * FROM table;"\n
Or you can pass a file (*.sql):\n
    -f path/to/file.sql
    """),
formatter_class=argparse.RawTextHelpFormatter
)
# add arguments
parser.add_argument("-s", "--string", type=str, help="pass a string")
parser.add_argument("-f", "--file", type=str, help="pass a path")


# parse arguments
args = parser.parse_args()

# check if no arguments are passed
if not args.string and not args.file:
    parser.error('You need to pass a query by: -s "string" or -f path/to/file.sql')


# use arguments
if args.string:
    print(f"Got a sting")
    query = args.string
if args.file:
    print(f"Got a file: {args.file}")
    query = open(args.file).read()


print(get_table(query))
    

