#!/bin/bash

# BlablaBil Database Schema Initialization Script
# This script applies the database schema to the PostgreSQL database

DB_NAME="blablabil_database"
DB_USER="appuser"
DB_PASSWORD="dbuser123"
DB_PORT="5000"

echo "Initializing BlablaBil database schema..."

# Find PostgreSQL version and set paths
PG_VERSION=$(ls /usr/lib/postgresql/ | head -1)
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"

# Check if PostgreSQL is running
if ! sudo -u postgres ${PG_BIN}/pg_isready -p ${DB_PORT} > /dev/null 2>&1; then
    echo "PostgreSQL is not running. Please start PostgreSQL first using ./startup.sh"
    exit 1
fi

# Check if database exists
if sudo -u postgres ${PG_BIN}/psql -p ${DB_PORT} -lqt | cut -d \| -f 1 | grep -qw ${DB_NAME}; then
    echo "Database ${DB_NAME} already exists."
    echo "Checking if schema is already applied..."
    
    # Check if users table exists (indicating schema is applied)
    if PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "\dt users" 2>/dev/null | grep -q "users"; then
        echo "Schema appears to be already applied (users table exists)."
        echo "To force re-initialization, drop the database first or use a different approach."
        exit 0
    fi
else
    echo "Database ${DB_NAME} does not exist. Creating database..."
    sudo -u postgres ${PG_BIN}/createdb -p ${DB_PORT} ${DB_NAME}
    
    # Grant permissions to appuser
    sudo -u postgres ${PG_BIN}/psql -p ${DB_PORT} -d postgres << EOF
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF
fi

# Apply the schema
echo "Applying database schema..."
if PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -f schema.sql; then
    echo "✓ Database schema applied successfully!"
    echo ""
    echo "Database: ${DB_NAME}"
    echo "User: ${DB_USER}"
    echo "Port: ${DB_PORT}"
    echo ""
    echo "Schema includes:"
    echo "- Users and authentication tables"
    echo "- Trips and bookings management"
    echo "- Payment and subscription system"
    echo "- Notifications and support system"
    echo "- Admin and logging tables"
    echo "- GDPR compliance features"
    echo "- Performance indexes and triggers"
    echo ""
    echo "To connect to the database:"
    echo "psql postgresql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}"
else
    echo "✗ Failed to apply database schema."
    echo "Please check the schema.sql file for any syntax errors."
    exit 1
fi
