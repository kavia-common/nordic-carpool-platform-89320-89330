#!/bin/bash

# BlablaBil Database Schema Validation Script
# This script validates that the database schema is properly installed and functional

DB_NAME="blablabil_database"
DB_USER="appuser"
DB_PASSWORD="dbuser123"
DB_PORT="5000"

echo "BlablaBil Database Schema Validation"
echo "==================================="

# Find PostgreSQL version and set paths
PG_VERSION=$(ls /usr/lib/postgresql/ | head -1)
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"

# Check if PostgreSQL is running
echo -n "Checking PostgreSQL service... "
if sudo -u postgres ${PG_BIN}/pg_isready -p ${DB_PORT} > /dev/null 2>&1; then
    echo "✓ Running"
else
    echo "✗ Not running"
    echo "Please start PostgreSQL using ./startup.sh"
    exit 1
fi

# Check if database exists
echo -n "Checking database existence... "
if sudo -u postgres ${PG_BIN}/psql -p ${DB_PORT} -lqt | cut -d \| -f 1 | grep -qw ${DB_NAME}; then
    echo "✓ Database exists"
else
    echo "✗ Database not found"
    echo "Please create database using ./startup.sh"
    exit 1
fi

# Check if schema is applied
echo -n "Checking schema installation... "
if PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "\dt users" 2>/dev/null | grep -q "users"; then
    echo "✓ Schema applied"
else
    echo "✗ Schema not applied"
    echo "Please apply schema using ./init_schema.sh"
    exit 1
fi

# Validate core tables
echo ""
echo "Validating core tables:"

core_tables=("users" "trips" "bookings" "payments" "notifications" "support_tickets" "vehicles" "trip_reviews")

for table in "${core_tables[@]}"; do
    echo -n "  - $table: "
    if PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "\dt $table" 2>/dev/null | grep -q "$table"; then
        echo "✓"
    else
        echo "✗"
    fi
done

# Check indexes
echo ""
echo -n "Checking indexes... "
index_count=$(PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "\di" 2>/dev/null | grep -c "idx_")
if [ "$index_count" -gt 10 ]; then
    echo "✓ ($index_count indexes found)"
else
    echo "⚠ Only $index_count indexes found"
fi

# Check triggers
echo -n "Checking triggers... "
trigger_count=$(PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT count(*) FROM information_schema.triggers WHERE trigger_schema = 'public';" -t 2>/dev/null | tr -d ' ')
if [ "$trigger_count" -gt 5 ]; then
    echo "✓ ($trigger_count triggers found)"
else
    echo "⚠ Only $trigger_count triggers found"
fi

# Check views
echo -n "Checking views... "
view_count=$(PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "\dv" 2>/dev/null | grep -c "_view")
if [ "$view_count" -gt 2 ]; then
    echo "✓ ($view_count views found)"
else
    echo "⚠ Only $view_count views found"
fi

# Test basic operations
echo ""
echo "Testing basic operations:"

# Test user insertion
echo -n "  - User creation: "
if PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "
INSERT INTO users (email, phone_number, password_hash, first_name, last_name) 
VALUES ('test@example.com', '+4712345678', 'hashed_password', 'Test', 'User') 
ON CONFLICT (email) DO NOTHING;
" > /dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

# Test user selection
echo -n "  - User retrieval: "
if PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT id FROM users WHERE email = 'test@example.com';" -t 2>/dev/null | grep -q "[0-9a-f-]"; then
    echo "✓"
else
    echo "✗"
fi

# Clean up test data
PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "DELETE FROM users WHERE email = 'test@example.com';" > /dev/null 2>&1

# Check schema version
echo -n "  - Schema version: "
schema_version=$(PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT version FROM schema_migrations ORDER BY applied_at DESC LIMIT 1;" -t 2>/dev/null | tr -d ' ')
if [ ! -z "$schema_version" ]; then
    echo "✓ $schema_version"
else
    echo "⚠ Not found"
fi

echo ""
echo "Validation complete!"
echo ""
echo "Connection details:"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Port: $DB_PORT"
echo "  Connection: psql postgresql://$DB_USER:$DB_PASSWORD@localhost:$DB_PORT/$DB_NAME"
