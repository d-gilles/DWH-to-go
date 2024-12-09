#!/bin/bash

# Enable strict mode for error handling
set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Check for the correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <KEY>"
    exit 1
fi

# Variables
key="$1"                  # The key to be added/updated in the .env file
tmp_file="${key}.tmp"     # Temporary file containing the value for the key
env_file=".env"           # The .env file to update
backup_file="${env_file}.bak"  # Backup file for .env

# Function to check if direnv is installed and reload it if available
reload_direnv() {
    if command -v direnv &>/dev/null; then
        echo "Reloading direnv..."
        direnv reload
    else
        echo "Warning: direnv is not installed or not found in PATH!"
    fi
}

# Ensure the temporary file exists
if [ ! -f "$tmp_file" ]; then
    echo "Error: File $tmp_file not found!"
    exit 1
fi

# Read the value from the temporary file
value=$(<"$tmp_file")
echo "** Key: $key, Value: $value"

# Update or add the key-value pair in the .env file
if grep -q "^${key}=" "$env_file"; then
    # If key exists, update it
    echo "** Updating $key in $env_file..."
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$env_file"
else
    # If key does not exist, add it
    echo "** Adding $key to $env_file..."
    echo "${key}=${value}" >>"$env_file"
fi

# Remove the temporary file
echo "** Cleaning up temporary file..."
rm -f "$tmp_file"

# Reload direnv if installed and check for the environment variable
echo "** Ensuring environment variable $key is available..."
until printenv "$key" &>/dev/null; do
    echo "** Environment variable $key is not yet set. Reloading direnv..."
    reload_direnv
    sleep 1  # Optional: Pause to avoid overwhelming the system
done

echo "** Environment variable $key is now available."

# Mark the key-value pair as available in the current environment
export "${key}=${value}"

echo "** Operation completed successfully."
