#!/bin/bash

# Function to generate a random password
generate_password() {
    # Generate a 10-character random alphanumeric password
    pw=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 10)
    echo "$pw"
}

# Log file path
log_file="/var/log/user_management.log"
# Secure password file path
password_file="/var/secure/user_passwords.txt"

# Check if log file exists, create if not
touch "$log_file"

# Check if password file exists, create if not
touch "$password_file"
chmod 600 "$password_file"  # Ensure only file owner can read

# Main script logic
if [ $# -ne 1 ]; then
    echo "Usage: $0 <text-file>"
    exit 1
fi

input_file="$1"

# Read each line in the input file
while IFS=';' read -r username groups; do
    # Trim leading/trailing whitespace
    username=$(echo "$username" | tr -d '[:space:]')
    groups=$(echo "$groups" | tr -d '[:space:]')

    # Check if username or groups are empty
    if [ -z "$username" ] || [ -z "$groups" ]; then
        echo "Error: Invalid format in input file."
        continue
    fi

    # Create user and group
    sudo groupadd "$username"  # Create a group with username
    sudo useradd -m -s /bin/bash -g "$username" -G "$groups" "$username"

    # Generate a password
    password=$(generate_password)

    # Set password for the user
    echo "$username:$password" | sudo chpasswd

    # Log actions
    log_message="Created user '$username' with groups '$groups'"
    echo "$(date +"%Y-%m-%d %T") $log_message" >> "$log_file"

    # Store password securelyclear
    
    echo "$username,$password" >> "$password_file"

done < "$input_file"

echo "User creation process complete."
