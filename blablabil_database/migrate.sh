#!/bin/bash

# BlablaBil Database Migration Script
# This script handles database schema migrations and version tracking

DB_NAME="blablabil_database"
DB_USER="appuser"
DB_PASSWORD="dbuser123"
DB_PORT="5000"

# Migration directory
MIGRATIONS_DIR="migrations"

echo "BlablaBil Database Migration Tool"
echo "================================"

# Find PostgreSQL version and set paths
PG_VERSION=$(ls /usr/lib/postgresql/ | head -1)
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"

# Function to check database connectivity
check_database() {
    if ! sudo -u postgres ${PG_BIN}/pg_isready -p ${DB_PORT} > /dev/null 2>&1; then
        echo "PostgreSQL is not running. Please start PostgreSQL first using ./startup.sh"
        exit 1
    fi

    if ! sudo -u postgres ${PG_BIN}/psql -p ${DB_PORT} -lqt | cut -d \| -f 1 | grep -qw ${DB_NAME}; then
        echo "Database ${DB_NAME} does not exist. Please create it first using ./startup.sh"
        exit 1
    fi
}

# Function to get current schema version
get_current_version() {
    local version
    version=$(PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT version FROM schema_migrations ORDER BY applied_at DESC LIMIT 1;" -t 2>/dev/null | tr -d ' ')
    if [ -z "$version" ]; then
        echo "0.0.0"
    else
        echo "$version"
    fi
}

# Function to list available migrations
list_migrations() {
    if [ ! -d "$MIGRATIONS_DIR" ]; then
        echo "No migrations directory found."
        return
    fi
    
    echo "Available migrations:"
    for file in "$MIGRATIONS_DIR"/*.sql; do
        if [ -f "$file" ]; then
            basename "$file"
        fi
    done
}

# Function to apply a specific migration
apply_migration() {
    local migration_file="$1"
    local version="$2"
    local description="$3"
    
    echo "Applying migration: $migration_file"
    
    if PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -f "$migration_file"; then
        # Record the migration
        PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "
            INSERT INTO schema_migrations (version, description) 
            VALUES ('$version', '$description')
            ON CONFLICT (version) DO UPDATE SET 
                applied_at = CURRENT_TIMESTAMP,
                description = EXCLUDED.description;
        " > /dev/null
        
        echo "✓ Migration $version applied successfully"
        return 0
    else
        echo "✗ Migration $version failed"
        return 1
    fi
}

# Function to create migrations directory and sample migration
setup_migrations() {
    mkdir -p "$MIGRATIONS_DIR"
    
    # Create a sample migration file
    cat > "$MIGRATIONS_DIR/001_add_user_preferences.sql" << 'EOF'
-- Migration: Add user notification preferences
-- Version: 1.0.1
-- Description: Add more granular notification preferences for users

-- Add new columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS trip_reminder_notifications BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS booking_update_notifications BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS promotional_notifications BOOLEAN DEFAULT FALSE;

-- Add notification preference settings table
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    email_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT TRUE,
    push_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, notification_type)
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_user_notification_preferences_user_id 
ON user_notification_preferences(user_id);

-- Add trigger for updated_at
CREATE TRIGGER update_user_notification_preferences_updated_at 
    BEFORE UPDATE ON user_notification_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default preferences for existing users
INSERT INTO user_notification_preferences (user_id, notification_type, email_enabled, sms_enabled, push_enabled)
SELECT 
    id, 
    'trip_reminders',
    email_notifications,
    sms_notifications,
    push_notifications
FROM users
ON CONFLICT (user_id, notification_type) DO NOTHING;

-- Log the migration
INSERT INTO system_logs (log_level, log_category, message, additional_data)
VALUES ('INFO', 'database', 'Migration 1.0.1 applied: User notification preferences', 
        '{"migration": "001_add_user_preferences", "timestamp": "' || CURRENT_TIMESTAMP || '"}');
EOF

    echo "✓ Migrations directory created with sample migration"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  status              Show current schema version and pending migrations"
    echo "  list               List all available migrations"
    echo "  apply [version]    Apply a specific migration by version"
    echo "  up                 Apply all pending migrations"
    echo "  setup              Create migrations directory and sample files"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 apply 1.0.1"
    echo "  $0 up"
}

# Main script logic
case "$1" in
    "status")
        check_database
        current_version=$(get_current_version)
        echo "Current schema version: $current_version"
        echo ""
        if [ -d "$MIGRATIONS_DIR" ]; then
            echo "Migrations directory: $MIGRATIONS_DIR"
            list_migrations
        else
            echo "No migrations directory found. Run '$0 setup' to create it."
        fi
        ;;
    
    "list")
        list_migrations
        ;;
    
    "apply")
        if [ -z "$2" ]; then
            echo "Error: Please specify a migration version"
            echo "Usage: $0 apply [version]"
            exit 1
        fi
        
        check_database
        migration_version="$2"
        migration_file="$MIGRATIONS_DIR/$(ls $MIGRATIONS_DIR/ | grep "$migration_version" | head -1)"
        
        if [ ! -f "$migration_file" ]; then
            echo "Error: Migration file for version $migration_version not found"
            exit 1
        fi
        
        apply_migration "$migration_file" "$migration_version" "Manual migration"
        ;;
    
    "up")
        check_database
        if [ ! -d "$MIGRATIONS_DIR" ]; then
            echo "No migrations directory found. Run '$0 setup' to create it."
            exit 1
        fi
        
        current_version=$(get_current_version)
        echo "Current version: $current_version"
        echo "Applying pending migrations..."
        
        for migration_file in "$MIGRATIONS_DIR"/*.sql; do
            if [ -f "$migration_file" ]; then
                filename=$(basename "$migration_file")
                version=$(echo "$filename" | sed 's/^[0-9]*_.*\.sql$//' | head -c 10)
                if [ -z "$version" ]; then
                    version=$(echo "$filename" | sed 's/\.sql$//')
                fi
                
                # Check if migration already applied
                existing=$(PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT COUNT(*) FROM schema_migrations WHERE version = '$version';" -t 2>/dev/null | tr -d ' ')
                
                if [ "$existing" = "0" ]; then
                    apply_migration "$migration_file" "$version" "Automated migration"
                else
                    echo "⏭ Migration $version already applied, skipping"
                fi
            fi
        done
        ;;
    
    "setup")
        setup_migrations
        ;;
    
    *)
        show_usage
        ;;
esac
