#!/bin/bash

# BlablaBil Database Performance Optimization Script
# This script provides database performance monitoring and optimization tools

DB_NAME="blablabil_database"
DB_USER="appuser"
DB_PASSWORD="dbuser123"
DB_PORT="5000"

echo "BlablaBil Database Performance Optimizer"
echo "======================================="

# Find PostgreSQL version and set paths
PG_VERSION=$(ls /usr/lib/postgresql/ | head -1)
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"

# Check if PostgreSQL is running
if ! sudo -u postgres ${PG_BIN}/pg_isready -p ${DB_PORT} > /dev/null 2>&1; then
    echo "PostgreSQL is not running. Please start PostgreSQL first using ./startup.sh"
    exit 1
fi

# Function to analyze table sizes
analyze_table_sizes() {
    echo "Table Size Analysis"
    echo "==================="
    
    PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} << 'EOF'
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
EOF
}

# Function to analyze index usage
analyze_index_usage() {
    echo ""
    echo "Index Usage Analysis"
    echo "==================="
    
    PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} << 'EOF'
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    CASE 
        WHEN idx_tup_read = 0 THEN 'Unused'
        WHEN idx_tup_read < 1000 THEN 'Low Usage'
        WHEN idx_tup_read < 10000 THEN 'Medium Usage'
        ELSE 'High Usage'
    END as usage_level
FROM pg_stat_user_indexes 
ORDER BY idx_tup_read DESC;
EOF
}

# Function to show slow queries
analyze_slow_queries() {
    echo ""
    echo "Query Performance Statistics"
    echo "==========================="
    
    PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} << 'EOF'
-- Note: This requires pg_stat_statements extension
-- If not available, it will show an error which can be ignored
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_time DESC 
LIMIT 10;
EOF
}

# Function to analyze database statistics
analyze_db_stats() {
    echo ""
    echo "Database Statistics"
    echo "=================="
    
    PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} << 'EOF'
-- Database size and connections
SELECT 
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) as size,
    numbackends as active_connections
FROM pg_database 
LEFT JOIN pg_stat_database ON pg_database.datname = pg_stat_database.datname
WHERE pg_database.datname = current_database();

-- Table statistics
SELECT 
    'Total Tables' as metric,
    COUNT(*) as value
FROM information_schema.tables 
WHERE table_schema = 'public'
UNION ALL
SELECT 
    'Total Indexes',
    COUNT(*)
FROM pg_indexes 
WHERE schemaname = 'public'
UNION ALL
SELECT 
    'Total Users',
    COUNT(*)::text
FROM users
UNION ALL
SELECT 
    'Active Trips',
    COUNT(*)::text
FROM trips 
WHERE status = 'active'
UNION ALL
SELECT 
    'Total Bookings',
    COUNT(*)::text
FROM bookings;
EOF
}

# Function to run vacuum and analyze
optimize_database() {
    echo ""
    echo "Running Database Optimization"
    echo "============================"
    
    echo "Running VACUUM ANALYZE on all tables..."
    
    # Get list of all tables
    tables=$(PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public';" -t)
    
    for table in $tables; do
        table=$(echo $table | tr -d ' ')
        if [ ! -z "$table" ]; then
            echo "  Optimizing table: $table"
            PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "VACUUM ANALYZE $table;" > /dev/null 2>&1
        fi
    done
    
    echo "✓ Database optimization completed"
}

# Function to check for missing indexes
suggest_indexes() {
    echo ""
    echo "Index Recommendations"
    echo "===================="
    
    PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} << 'EOF'
-- Check for tables with high sequential scans
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    CASE 
        WHEN seq_scan > 1000 AND seq_tup_read / seq_scan > 1000 THEN 'Consider adding indexes'
        WHEN seq_scan > 10000 THEN 'High sequential scan usage'
        ELSE 'OK'
    END as recommendation
FROM pg_stat_user_tables 
WHERE seq_scan > 0
ORDER BY seq_scan DESC;
EOF
}

# Function to show database health
check_database_health() {
    echo ""
    echo "Database Health Check"
    echo "===================="
    
    PGPASSWORD="${DB_PASSWORD}" ${PG_BIN}/psql -h localhost -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} << 'EOF'
-- Check for dead tuples
SELECT 
    schemaname,
    tablename,
    n_dead_tup,
    CASE 
        WHEN n_dead_tup > 1000 THEN 'Consider VACUUM'
        WHEN n_dead_tup > 10000 THEN 'VACUUM needed urgently'
        ELSE 'OK'
    END as status
FROM pg_stat_user_tables 
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC;

-- Check for bloated tables
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(tablename::regclass)) as total_size,
    pg_size_pretty(pg_relation_size(tablename::regclass)) as table_size
FROM pg_tables 
WHERE schemaname = 'public'
    AND pg_total_relation_size(tablename::regclass) > 1048576  -- > 1MB
ORDER BY pg_total_relation_size(tablename::regclass) DESC;
EOF
}

# Show usage information
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  analyze     Show comprehensive database analysis"
    echo "  sizes       Show table and index sizes"
    echo "  indexes     Show index usage statistics"
    echo "  queries     Show query performance statistics"
    echo "  stats       Show general database statistics"
    echo "  optimize    Run VACUUM ANALYZE on all tables"
    echo "  suggest     Suggest index optimizations"
    echo "  health      Check database health"
    echo "  all         Run all analysis commands"
    echo ""
}

# Main script logic
case "$1" in
    "analyze"|"all")
        analyze_db_stats
        analyze_table_sizes
        analyze_index_usage
        suggest_indexes
        check_database_health
        ;;
    
    "sizes")
        analyze_table_sizes
        ;;
    
    "indexes")
        analyze_index_usage
        ;;
    
    "queries")
        analyze_slow_queries
        ;;
    
    "stats")
        analyze_db_stats
        ;;
    
    "optimize")
        optimize_database
        ;;
    
    "suggest")
        suggest_indexes
        ;;
    
    "health")
        check_database_health
        ;;
    
    *)
        show_usage
        ;;
esac
