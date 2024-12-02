#!/bin/bash

# Enable strict mode
set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Check if the number of arguments is sufficient
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <target> VAR1 VAR2 ..."
    exit 1
fi

# Variables
target="$1"                # The first argument is the target
shift                      # Remove the first argument, leaving only the variables
required_vars=("$@")       # Remaining arguments are required environment variables

# Function to check if required variables are set
check_vars() {
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            echo "** Error: Variable '$var' is not set!"
            exit 1
        else
            echo "** Variable '$var' is set."
        fi
    done
}

# Main execution
echo "** Starting setup for target: $target"

# Check all required variables
check_vars

echo "** All required variables are set."
echo "** Proceeding with setup for target: $target."
echo "**"
# Add your script's main logic here
