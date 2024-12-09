#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Ensure the correct number of arguments is provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <target> VAR1 VAR2 ..."
    exit 1
fi

# Variables
target="$1"                # The first argument is the target
shift                      # Remove the first argument, leaving only the environment variable names
required_vars=("$@")       # Remaining arguments are the required environment variables

# Function to check if all required environment variables are set
check_vars() {
    for var in "${required_vars[@]}"; do
        # Check if the variable is set and non-empty
        if [ -z "${!var:-}" ]; then
            echo "** Error: Variable '$var' is not set!"
            exit 1
        else
            echo "** Variable '$var' is set."
        fi
    done
}

# Main execution block
echo "** Starting setup for target: $target"

# Validate all required environment variables
check_vars

echo "** All required variables are set."
echo "** Proceeding with setup for target: $target."
echo "**"
