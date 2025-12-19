#! /bin/bash

# This script creates a new non-root administrative user with sudo privileges
# and configures SSH key-based login for security.
# ---
# NOTE: This script must be run as the root user or by another admin user.
# ---

# Usage: ./create_admin_user.sh <username> "<public_ssh_key_string>"

USERNAME=$1
SSH_KEY=$2

# --- Input Validation ---
if [ -z "$USERNAME" ] || [ -z "$SSH_KEY" ]; then
  # Check if both username and SSH key arguments were provided.
  # $0: The name of the script being executed.
  echo "Error: Missing arguments."
  echo "Usage: $0 <username> \"<public_ssh_key>\""
  exit 1
fi

# 1. Create User
# useradd: Creates a new user account.
# -m: Creates the user's home directory (/home/$USERNAME).
# -s /bin/bash: Sets the default login shell to Bash, allowing interactive command line access.
useradd -m -s /bin/bash "$USERNAME"

# Set an initial password so the user can actually use sudo
echo "Please set a temporary password for $USERNAME user:"
passwd "$USERNAME"

# 2. Add to Sudo group
# usermod: Modifies an existing user's attributes.
# -aG: Appends the user (-a) to the specified supplementary group (-G).
# sudo: The group that grants elevated permissions via the 'sudo' command.
usermod -aG sudo "$USERNAME"

# 3. Setup SSH directory
# -p: Creates parent directories as needed.
# This is where the authorized_keys file will reside for secure login.
mkdir -p "/home/$USERNAME/.ssh"

# >>: Appends the output (the SSH key) to the file.
# authorized_keys: The file SSH uses to verify the user's private key.
echo "$SSH_KEY" >> "/home/$USERNAME/.ssh/authorized_keys"

# 4. Fix permissions
# chmod 700: Sets permissions for the .ssh directory to owner read/write/execute (rwx), and nothing for group/other.
# SSH daemon requires these restrictive permissions to function.
chmod 700 "/home/$USERNAME/.ssh"

# chmod 600: Sets permissions for the authorized_keys file to owner read/write (rw), and nothing for group/other.
# This prevents other users from reading or modifying the key file.
chmod 600 "/home/$USERNAME/.ssh/authorized_keys"

# chown -R: Recursively changes the ownership of files/directories.
# "$USERNAME:$USERNAME": Sets the owner and the group to the newly created user.
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"

# 5. Configure sudo to require password
# This creates a file in the /etc/sudoers.d/ directory.
# The system default is to require the password.
echo "$USERNAME ALL=(ALL) ALL" > "/etc/sudoers.d/90-$USERNAME"

echo "User $USERNAME created successfully."
