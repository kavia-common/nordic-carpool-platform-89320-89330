-- BlablaBil Database Test Setup and Utilities
-- This file contains setup functions and utilities for running database tests

-- =============================================================================
-- TEST CONFIGURATION AND SETUP
-- =============================================================================

-- Create test schema if needed (optional isolation)
-- CREATE SCHEMA IF NOT EXISTS test_blablabil;

-- Set session for consistent test behavior
SET TIME ZONE 'UTC';
SET datestyle = 'ISO, MDY';

-- =============================================================================
-- TEST UTILITY FUNCTIONS
-- =============================================================================

-- Function to generate test UUID (deterministic for tests)
CREATE OR REPLACE FUNCTION test_uuid(seed TEXT DEFAULT 'test')
RETURNS UUID AS $$
BEGIN
    -- Generate deterministic UUID for testing
    RETURN md5(seed || extract(epoch from current_timestamp))::uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to create test user
CREATE OR REPLACE FUNCTION create_test_user(
    user_email TEXT DEFAULT 'test@example.com',
    user_phone TEXT DEFAULT '+4712345678'
)
RETURNS UUID AS $$
DECLARE
    user_id UUID;
BEGIN
    INSERT INTO users (
        email, phone_number, password_hash, 
        first_name, last_name, 
        data_processing_consent, marketing_consent
    ) VALUES (
        user_email, user_phone, 'test_hash_' || user_email,
        'Test', 'User',
        true, false
    ) RETURNING id INTO user_id;
    
    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create test trip
CREATE OR REPLACE FUNCTION create_test_trip(
    driver_user_id UUID,
    origin TEXT DEFAULT 'Oslo',
    destination TEXT DEFAULT 'Bergen'
)
RETURNS UUID AS $$
DECLARE
    trip_id UUID;
BEGIN
    INSERT INTO trips (
        driver_id, origin_city, destination_city,
        departure_time, price_per_seat, 
        available_seats, total_seats
    ) VALUES (
        driver_user_id, origin, destination,
        CURRENT_TIMESTAMP + INTERVAL '1 day', 300.00,
        3, 4
    ) RETURNING id INTO trip_id;
    
    RETURN trip_id;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up test data
CREATE OR REPLACE FUNCTION cleanup_test_data()
RETURNS VOID AS $$
BEGIN
    -- Delete in correct order to respect foreign key constraints
    DELETE FROM gdpr_data_logs WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM user_activity_logs WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM system_logs WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM support_ticket_messages WHERE ticket_id IN (SELECT id FROM support_tickets WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%'));
    DELETE FROM support_tickets WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM notifications WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM trip_reviews WHERE reviewer_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM credit_transactions WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM payments WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM bookings WHERE passenger_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM trip_waypoints WHERE trip_id IN (SELECT id FROM trips WHERE driver_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%'));
    DELETE FROM trips WHERE driver_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM vehicles WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM subscriptions WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM password_reset_tokens WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM user_sessions WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM admin_users WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%');
    DELETE FROM users WHERE email LIKE '%test%' OR email LIKE '%@example.%';
    
    -- Clean up test notification templates
    DELETE FROM notification_templates WHERE template_name LIKE 'test_%';
    
    -- Clean up test FAQ items
    DELETE FROM faq_items WHERE question LIKE 'Test%' OR answer LIKE 'Test%';
    DELETE FROM faq_categories WHERE name LIKE 'Test%';
    
    RAISE NOTICE 'Test data cleanup completed';
END;
$$ LANGUAGE plpgsql;

-- Function to assert test condition
CREATE OR REPLACE FUNCTION test_assert(
    condition BOOLEAN,
    test_name TEXT,
    error_message TEXT DEFAULT 'Test assertion failed'
)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT condition THEN
        RAISE EXCEPTION 'TEST FAILED: % - %', test_name, error_message;
    END IF;
    
    RAISE NOTICE 'TEST PASSED: %', test_name;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to count table rows
CREATE OR REPLACE FUNCTION count_rows(table_name TEXT)
RETURNS INTEGER AS $$
DECLARE
    row_count INTEGER;
BEGIN
    EXECUTE 'SELECT COUNT(*) FROM ' || quote_ident(table_name) INTO row_count;
    RETURN row_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TEST EXECUTION FRAMEWORK
-- =============================================================================

-- Create test results table
CREATE TABLE IF NOT EXISTS test_results (
    id SERIAL PRIMARY KEY,
    test_suite VARCHAR(100) NOT NULL,
    test_name VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('PASS', 'FAIL', 'SKIP')),
    error_message TEXT,
    execution_time INTERVAL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Function to record test result
CREATE OR REPLACE FUNCTION record_test_result(
    suite_name TEXT,
    test_name TEXT,
    test_status TEXT,
    error_msg TEXT DEFAULT NULL,
    exec_time INTERVAL DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO test_results (test_suite, test_name, status, error_message, execution_time)
    VALUES (suite_name, test_name, test_status, error_msg, exec_time);
END;
$$ LANGUAGE plpgsql;

-- Function to run test suite and capture results
CREATE OR REPLACE FUNCTION run_test_block(
    suite_name TEXT,
    test_name TEXT,
    test_sql TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    exec_time INTERVAL;
    test_passed BOOLEAN := TRUE;
    error_msg TEXT;
BEGIN
    start_time := clock_timestamp();
    
    BEGIN
        -- Execute the test SQL
        EXECUTE test_sql;
        
        -- Record success
        end_time := clock_timestamp();
        exec_time := end_time - start_time;
        PERFORM record_test_result(suite_name, test_name, 'PASS', NULL, exec_time);
        
    EXCEPTION WHEN OTHERS THEN
        test_passed := FALSE;
        error_msg := SQLERRM;
        end_time := clock_timestamp();
        exec_time := end_time - start_time;
        
        PERFORM record_test_result(suite_name, test_name, 'FAIL', error_msg, exec_time);
        RAISE NOTICE 'TEST FAILED: % - %', test_name, error_msg;
    END;
    
    RETURN test_passed;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- INITIAL SETUP VALIDATION
-- =============================================================================

-- Validate that essential tables exist
DO $$
BEGIN
    PERFORM test_assert(
        EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users'),
        'SETUP_CHECK',
        'Users table must exist'
    );
    
    PERFORM test_assert(
        EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trips'),
        'SETUP_CHECK',
        'Trips table must exist'
    );
    
    PERFORM test_assert(
        EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'bookings'),
        'SETUP_CHECK',
        'Bookings table must exist'
    );
    
    PERFORM test_assert(
        EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'payments'),
        'SETUP_CHECK',
        'Payments table must exist'
    );
    
    RAISE NOTICE 'Database setup validation completed successfully';
END;
$$;

-- Clean up any existing test data before starting
SELECT cleanup_test_data();

RAISE NOTICE 'Test setup utilities loaded successfully';
