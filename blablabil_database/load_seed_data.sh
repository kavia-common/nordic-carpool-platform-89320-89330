#!/bin/bash

# BlablaBil Database Seed Data Loading Script
# This script loads sample data into the database for development and testing

DB_NAME="blablabil_database"
DB_USER="appuser"
DB_PASSWORD="dbuser123"
DB_PORT="5000"

echo "Loading BlablaBil sample data..."

# Find PostgreSQL version and set paths
PG_VERSION=$(ls /usr/lib/postgresql/ | head -1)
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"

# Check if PostgreSQL is running
if ! sudo -u postgres ${PG_BIN}/pg_isready -p ${DB_PORT} > /dev/null 2>&1; then
    echo "PostgreSQL is not running. Please start PostgreSQL first using ./startup.sh"
    exit 1
fi

# Check if database exists
if ! sudo -u postgres ${PG_BIN}/psql -p ${DB_PORT} -lqt | cut -d \| -f 1 | grep -qw ${DB_NAME}; then
    echo "Database ${DB_NAME} does not exist. Please create and initialize it first:"
    echo "  ./startup.sh"
    echo "  ./init_schema.sh"
    exit 1
fi

# Check if schema is applied
if ! PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "\dt users" 2>/dev/null | grep -q "users"; then
    echo "Schema not applied. Please apply schema first using ./init_schema.sh"
    exit 1
fi

# Check if data already exists
user_count=$(PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT COUNT(*) FROM users WHERE email LIKE '%@%';" -t 2>/dev/null | tr -d ' ')

if [ "$user_count" -gt 0 ]; then
    echo "Sample data appears to already exist ($user_count users found)."
    read -p "Do you want to proceed anyway? This might create duplicate data. (y/N): " confirm
    case $confirm in
        [Yy]* ) 
            echo "Proceeding with data loading..."
            ;;
        * ) 
            echo "Operation cancelled."
            exit 0
            ;;
    esac
fi

# Load the seed data
echo "Applying seed data..."
if PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -f seed_data.sql; then
    echo "✓ Sample data loaded successfully!"
    echo ""
    echo "Sample data includes:"
    echo "- 6 users (3 drivers, 2 passengers, 1 international user)"
    echo "- 4 vehicles"
    echo "- 4 upcoming trips"
    echo "- 2 bookings with payments"
    echo "- Trip reviews and ratings"
    echo "- Support tickets"
    echo "- FAQ items in Norwegian and English"
    echo "- Notifications"
    echo "- Premium subscriptions"
    echo ""
    echo "You can now test the application with realistic data!"
    echo ""
    echo "To connect to the database:"
    echo "psql postgresql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}"
else
    echo "✗ Failed to load sample data."
    echo "Please check the seed_data.sql file for any errors."
    exit 1
fi
