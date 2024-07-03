#!/bin/bash

# Check if the user has provided a file
if [ $# -ne 1 ]; then
  echo "Usage: $0 <name-of-text-file>"
  exit 1
fi

INPUT_FILE=$1

# Check if the file exists
if [ ! -f $INPUT_FILE ]; then
  echo "File $INPUT_FILE does not exist."
  exit 1
fi

# Log and password files
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create the necessary directories if they don't exist
mkdir -p /var/secure
touch $LOG_FILE
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Function to create a user and assign groups
create_user() {
  USERNAME=$1
  GROUPS=$2

  # Create user group with the same name as the username
  if ! getent group $USERNAME > /dev/null 2>&1; then
    groupadd $USERNAME
    echo "$(date) - Group $USERNAME created." >> $LOG_FILE
  else
    echo "$(date) - Group $USERNAME already exists." >> $LOG_FILE
  fi

  # Create the user with the specified groups
  if ! id -u $USERNAME > /dev/null 2>&1; then
    useradd -m -g $USERNAME -G $GROUPS $USERNAME
    echo "$(date) - User $USERNAME created and added to groups $GROUPS." >> $LOG_FILE

    # Generate a random password for the user
    PASSWORD=$(openssl rand -base64 12)
    echo "$USERNAME,$PASSWORD" >> $PASSWORD_FILE
    echo "$(date) - Password for $USERNAME set and stored securely." >> $LOG_FILE

    # Set the password for the user
    echo "$USERNAME:$PASSWORD" | chpasswd
  else
    echo "$(date) - User $USERNAME already exists." >> $LOG_FILE
  fi
}

# Read the file line by line
while IFS=';' read -r USERNAME GROUPS; do
  # Trim leading/trailing whitespace from username and groups
  USERNAME=$(echo $USERNAME | xargs)
  GROUPS=$(echo $GROUPS | xargs)

  # Replace any spaces in group list with commas
  GROUPS=$(echo $GROUPS | sed 's/ /,/g')

  # Create the user
  create_user $USERNAME $GROUPS
done < $INPUT_FILE

echo "User creation process completed. Check $LOG_FILE for details and $PASSWORD_FILE for passwords."

