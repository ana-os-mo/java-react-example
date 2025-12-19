#! /bin/bash

# This script sets up the secured environment for the Java application,
# including a restricted service user, required directories, and firewall rules.
# This script must be run with 'sudo' by an administrative user.
# ---

# Usage: ./setup_app_env.sh <app_name> <service_user> <port>

APP_NAME=$1
SVC_USER=$2
PORT=$3

APP_DIR="/opt/$APP_NAME"

# 1. Create Service User (System user, no home, no login)

# Check if the service user already exists to make the script idempotent.
# id "$SVC_USER": Attempts to get information about the user ID.
# &>/dev/null: Redirects both standard output and standard error to the trash, suppressing screen output.
if id "$SVC_USER" &>/dev/null; then
    echo "User $SVC_USER already exists."
else
    # useradd: Creates a new user account.
    # -r: Creates a 'system user' (UID usually < 1000). System users do not typically have home directories by default.
    # -s /usr/sbin/nologin: Sets the user's shell to 'nologin', which prevents any interactive or remote login via SSH.
    # This is a critical security measure to prevent a compromised app from being used for user access.
    useradd -r -s /usr/sbin/nologin "$SVC_USER"
    echo "User $SVC_USER created."
fi

# 2. Create Application Directory

# Creates the application's root directory and the logs subdirectory.
mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/logs"

# 3. Configure Permissions (Principle of Least Privilege)

# The directory is owned by root, but group-owned by the service user.
# chown -R: Recursively changes ownership of the directory and all contents.
# root:"$SVC_USER": Sets the Owner to 'root' (for security/immutability) and the Group to the service user.
# The '.jar' file will be placed here and owned by root to prevent the app user from modifying its own binary.
chown -R root:"$SVC_USER" "$APP_DIR"

# Allow service user to write only to the logs directory.
# chown -R "$SVC_USER":"$SVC_USER": Sets the Owner and Group to the service user, granting it full write access here.
chown -R "$SVC_USER":"$SVC_USER" "$APP_DIR/logs"

# chmod 750: Sets permissions for the application root directory.
# 7 (rwx): Owner (root) can read, write, and traverse.
# 5 (r-x): Group (appsvc) can read and traverse (necessary for the app to read the JAR and enter the logs folder).
# 0 (---): Others have no permissions.
chmod 750 "$APP_DIR"

echo "Environment for $APP_NAME setup complete at $APP_DIR"
echo "NEXT STEP: Open the firewall for port $PORT if not already done."
