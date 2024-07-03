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
if [ ! -f "$log_file" ]; then
    sudo touch "$log_file"
fi

# Check if password file exists, create if not
if [ ! -f "$password_file" ]; then
    sudo touch "$password_file"
    sudo chmod 600 "$password_file"  # Ensure only file owner can read
fi

# Main script logic
if [ $# -ne 1 ]; then
    echo "Usage: $0 <text-file>"
    exit 1
fi

input_file="$1"

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file not found!"
    exit 1
fi

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

    # Create group if it does not exist
    if ! getent group "$username" > /dev/null 2>&1; then
        sudo groupadd "$username"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create group '$username'."
            continue
        fi
    fi

    # Create user
    if ! id "$username" > /dev/null 2>&1; then
        sudo useradd -m -s /bin/bash -g "$username" -G "$groups" "$username"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create user '$username'."
            continue
        fi
    else
        echo "User '$username' already exists."
        continue
    fi

    # Generate a password
    password=$(generate_password)

    # Set password for the user
    echo "$username:$password" | sudo chpasswd
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set password for user '$username'."
        continue
    fi

    # Log actions
    log_message="Created user '$username' with groups '$groups'"
    echo "$(date +"%Y-%m-%d %T") $log_message" | sudo tee -a "$log_file" > /dev/null

    # Store password securely
    echo "$username,$password" | sudo tee -a "$password_file" > /dev/null

done < "$input_file"

echo "User creation process complete."
