#!/bin/bash

# Enable strict mode
set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Check for required arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <KEY>"
    exit 1
fi

# Variables
key="$1"
tmp_file="${key}.tmp"
env_file=".env"
backup_file="${env_file}.bak"

# Function to check if direnv is installed and reload if available
reload_direnv() {
    if command -v direnv &>/dev/null; then
        echo "Reloading direnv..."
        direnv reload
    else
        echo "Warning: direnv is not installed or not in PATH!"
    fi
}

# Ensure the temporary file exists
if [ ! -f "$tmp_file" ]; then
    echo "Error: File $tmp_file not found!"
    exit 1
fi

# Read the value from the temporary file
value=$(<"$tmp_file")
echo "** Key: $key Value: $value"


# Update or add the key-value pair in the .env file
if grep -q "^${key}=" "$env_file"; then
    echo "** Updating $key in $env_file..."
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$env_file"
else
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

echo "** Operation completed successfully."
export "${key}=${value}"
