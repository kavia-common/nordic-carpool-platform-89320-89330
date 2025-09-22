#!/bin/bash

# BlablaBil Database Cleanup Script
# This script removes all data while preserving the schema structure

DB_NAME="blablabil_database"
DB_USER="appuser"
DB_PASSWORD="dbuser123"
DB_PORT="5000"

echo "BlablaBil Database Cleanup"
echo "========================="

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
    echo "Database ${DB_NAME} does not exist."
    exit 1
fi

# Show current data counts
echo "Current data in database:"
PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} << 'EOF'
SELECT 
    'Users: ' || COUNT(*) as count FROM users
UNION ALL
SELECT 
    'Trips: ' || COUNT(*) FROM trips
UNION ALL
SELECT 
    'Bookings: ' || COUNT(*) FROM bookings
UNION ALL
SELECT 
    'Payments: ' || COUNT(*) FROM payments
UNION ALL
SELECT 
    'Reviews: ' || COUNT(*) FROM trip_reviews
UNION ALL
SELECT 
    'Support Tickets: ' || COUNT(*) FROM support_tickets
UNION ALL
SELECT 
    'Notifications: ' || COUNT(*) FROM notifications;
EOF

echo ""
echo "⚠️  WARNING: This will delete ALL data from the database!"
echo "   The schema structure will be preserved."
echo ""
read -p "Are you sure you want to continue? Type 'DELETE ALL DATA' to confirm: " confirm

if [ "$confirm" != "DELETE ALL DATA" ]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo "Cleaning up database data..."

# Delete data in correct order to respect foreign key constraints
PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} << 'EOF'
-- Disable triggers temporarily for faster deletion
SET session_replication_role = replica;

-- Delete data in dependency order
TRUNCATE TABLE 
    gdpr_data_logs,
    user_activity_logs,
    system_logs,
    admin_users,
    support_ticket_messages,
    support_tickets,
    faq_items,
    notifications,
    trip_reviews,
    credit_transactions,
    payments,
    bookings,
    trip_waypoints,
    trips,
    vehicles,
    subscriptions,
    password_reset_tokens,
    user_sessions,
    users
RESTART IDENTITY CASCADE;

-- Re-enable triggers
SET session_replication_role = DEFAULT;

-- Keep admin roles, FAQ categories, and notification templates
-- These are structural data that should persist

-- Reset sequences if needed
SELECT setval(pg_get_serial_sequence('users', 'id'), 1, false);

-- Log the cleanup
INSERT INTO system_logs (log_level, log_category, message, additional_data)
VALUES ('INFO', 'database', 'Database cleanup completed', 
        '{"action": "truncate_all_user_data", "timestamp": "' || CURRENT_TIMESTAMP || '"}');

SELECT 'Database cleanup completed successfully!' as status;
EOF

if [ $? -eq 0 ]; then
    echo "✓ Database cleanup completed successfully!"
    echo ""
    echo "All user data has been removed."
    echo "Schema structure, admin roles, FAQ categories, and notification templates preserved."
    echo ""
    echo "To reload sample data, run: ./load_seed_data.sh"
else
    echo "✗ Database cleanup failed."
    exit 1
fi
