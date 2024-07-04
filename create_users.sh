#!/bin/bash

# Define paths for log and password files
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure the password file directory exists and has the correct permissions
mkdir -p /var/secure
chmod 700 /var/secure

# Clear previous log and password files or create new ones
> $LOG_FILE
> $PASSWORD_FILE

# Function to generate a random password
generate_password() {
    local PASSWORD=$(openssl rand -base64 12)
    echo $PASSWORD
}

# Read the input file line by line
while IFS=';' read -r USERNAME GROUPS; do
    # Trim whitespace from USERNAME and GROUPS
    USERNAME=$(echo $USERNAME | xargs)
    GROUPS=$(echo $GROUPS | xargs)
    
    if id "$USERNAME" &>/dev/null; then
        echo "User $USERNAME already exists" | tee -a $LOG_FILE
        continue
    fi
    
    # Create a personal group with the same name as the user
    if ! getent group "$USERNAME" &>/dev/null; then
        groupadd "$USERNAME"
    fi

    # Create the user and add to the primary group (same as username)
    useradd -m -g "$USERNAME" "$USERNAME" | tee -a $LOG_FILE

    # Assign additional groups to the user
    IFS=',' read -ra ADDITIONAL_GROUPS <<< "$GROUPS"
    for GROUP in "${ADDITIONAL_GROUPS[@]}"; do
        GROUP=$(echo $GROUP | xargs)
        if ! getent group "$GROUP" &>/dev/null; then
            groupadd "$GROUP" | tee -a $LOG_FILE
        fi
        usermod -aG "$GROUP" "$USERNAME" | tee -a $LOG_FILE
    done

    # Generate a random password for the user
    PASSWORD=$(generate_password)

    # Set the user's password
    echo "$USERNAME:$PASSWORD" | chpasswd

    # Store the password securely
    echo "$USERNAME,$PASSWORD" >> $PASSWORD_FILE

    # Set permissions for the password file
    chown root:root $PASSWORD_FILE
    chmod 600 $PASSWORD_FILE

    echo "User $USERNAME created and assigned to groups: $GROUPS" | tee -a $LOG_FILE
done < "$1"

echo "User creation process completed. Check $LOG_FILE for details and $PASSWORD_FILE for passwords."
