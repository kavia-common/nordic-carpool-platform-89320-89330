-- BlablaBil Database Relationship and Foreign Key Tests
-- Testing foreign key constraints, cardinality, and cascading behavior

-- Load test utilities
\i test_setup.sql

-- =============================================================================
-- RELATIONSHIP AND FOREIGN KEY TESTS
-- =============================================================================

DO $$
DECLARE
    test_driver_id UUID;
    test_passenger_id UUID;
    test_trip_id UUID;
    test_booking_id UUID;
    test_payment_id UUID;
    test_vehicle_id UUID;
    test_suite TEXT := 'RELATIONSHIPS';
    row_count INTEGER;
BEGIN
    RAISE NOTICE 'Starting Relationship and Foreign Key Tests...';
    
    -- Clean up before tests
    PERFORM cleanup_test_data();
    
    -- =============================================================================
    -- TEST 1: User-Trip Relationship
    -- =============================================================================
    
    -- Create test driver
    test_driver_id := create_test_user('driver@example.com', '+4712345100');
    
    -- Create trip with valid driver
    test_trip_id := create_test_trip(test_driver_id, 'Oslo', 'Bergen');
    PERFORM record_test_result(test_suite, 'Create trip with valid driver', 'PASS');
    
    BEGIN
        -- Should fail to create trip with non-existent driver
        INSERT INTO trips (
            driver_id, origin_city, destination_city,
            departure_time, price_per_seat, available_seats, total_seats
        ) VALUES (
            uuid_generate_v4(), 'Oslo', 'Trondheim',
            CURRENT_TIMESTAMP + INTERVAL '1 day', 250.00, 3, 4
        );
        
        PERFORM record_test_result(test_suite, 'Trip with non-existent driver', 'FAIL', 'Should have failed with FK violation');
    EXCEPTION WHEN FOREIGN_KEY_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Trip with non-existent driver', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 2: Vehicle-User Relationship
    -- =============================================================================
    
    BEGIN
        -- Create vehicle with valid user
        INSERT INTO vehicles (
            user_id, make, model, license_plate
        ) VALUES (
            test_driver_id, 'Toyota', 'Camry', 'TEST001'
        ) RETURNING id INTO test_vehicle_id;
        
        PERFORM record_test_result(test_suite, 'Create vehicle with valid user', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create vehicle with valid user', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Should fail to create vehicle with non-existent user
        INSERT INTO vehicles (
            user_id, make, model, license_plate
        ) VALUES (
            uuid_generate_v4(), 'Honda', 'Civic', 'TEST002'
        );
        
        PERFORM record_test_result(test_suite, 'Vehicle with non-existent user', 'FAIL', 'Should have failed with FK violation');
    EXCEPTION WHEN FOREIGN_KEY_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Vehicle with non-existent user', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 3: Trip-Booking Relationship
    -- =============================================================================
    
    -- Create test passenger
    test_passenger_id := create_test_user('passenger@example.com', '+4712345101');
    
    BEGIN
        -- Create booking with valid trip and passenger
        INSERT INTO bookings (
            trip_id, passenger_id, seats_booked, total_price
        ) VALUES (
            test_trip_id, test_passenger_id, 1, 300.00
        ) RETURNING id INTO test_booking_id;
        
        PERFORM record_test_result(test_suite, 'Create booking with valid trip and passenger', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create booking with valid trip and passenger', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Should fail to create booking with non-existent trip
        INSERT INTO bookings (
            trip_id, passenger_id, seats_booked, total_price
        ) VALUES (
            uuid_generate_v4(), test_passenger_id, 1, 300.00
        );
        
        PERFORM record_test_result(test_suite, 'Booking with non-existent trip', 'FAIL', 'Should have failed with FK violation');
    EXCEPTION WHEN FOREIGN_KEY_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Booking with non-existent trip', 'PASS');
    END;
    
    BEGIN
        -- Should fail to create booking with non-existent passenger
        INSERT INTO bookings (
            trip_id, passenger_id, seats_booked, total_price
        ) VALUES (
            test_trip_id, uuid_generate_v4(), 1, 300.00
        );
        
        PERFORM record_test_result(test_suite, 'Booking with non-existent passenger', 'FAIL', 'Should have failed with FK violation');
    EXCEPTION WHEN FOREIGN_KEY_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Booking with non-existent passenger', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 4: Booking-Payment Relationship
    -- =============================================================================
    
    BEGIN
        -- Create payment with valid booking
        INSERT INTO payments (
            booking_id, user_id, amount, payment_method
        ) VALUES (
            test_booking_id, test_passenger_id, 300.00, 'vipps'
        ) RETURNING id INTO test_payment_id;
        
        PERFORM record_test_result(test_suite, 'Create payment with valid booking', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create payment with valid booking', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Should fail to create payment with non-existent booking
        INSERT INTO payments (
            booking_id, user_id, amount, payment_method
        ) VALUES (
            uuid_generate_v4(), test_passenger_id, 300.00, 'cash'
        );
        
        PERFORM record_test_result(test_suite, 'Payment with non-existent booking', 'FAIL', 'Should have failed with FK violation');
    EXCEPTION WHEN FOREIGN_KEY_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Payment with non-existent booking', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 5: Unique Constraints in Relationships
    -- =============================================================================
    
    BEGIN
        -- Should fail to create duplicate booking (same trip + passenger)
        INSERT INTO bookings (
            trip_id, passenger_id, seats_booked, total_price
        ) VALUES (
            test_trip_id, test_passenger_id, 1, 300.00
        );
        
        PERFORM record_test_result(test_suite, 'Duplicate booking prevention', 'FAIL', 'Should have failed with unique violation');
    EXCEPTION WHEN UNIQUE_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Duplicate booking prevention', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 6: Cascade Delete Behavior
    -- =============================================================================
    
    -- Count related records before deletion
    SELECT COUNT(*) INTO row_count FROM trips WHERE driver_id = test_driver_id;
    PERFORM test_assert(row_count > 0, 'Pre-delete trip count', 'Should have trips before deletion');
    
    SELECT COUNT(*) INTO row_count FROM bookings WHERE trip_id = test_trip_id;
    PERFORM test_assert(row_count > 0, 'Pre-delete booking count', 'Should have bookings before deletion');
    
    SELECT COUNT(*) INTO row_count FROM payments WHERE booking_id = test_booking_id;
    PERFORM test_assert(row_count > 0, 'Pre-delete payment count', 'Should have payments before deletion');
    
    -- Delete user and test cascade behavior
    DELETE FROM users WHERE id = test_driver_id;
    
    -- Verify cascade deletes worked
    SELECT COUNT(*) INTO row_count FROM trips WHERE driver_id = test_driver_id;
    PERFORM test_assert(row_count = 0, 'Post-delete trip cascade', 'Trips should be deleted when user is deleted');
    PERFORM record_test_result(test_suite, 'Trip cascade delete on user deletion', 'PASS');
    
    SELECT COUNT(*) INTO row_count FROM bookings WHERE trip_id = test_trip_id;
    PERFORM test_assert(row_count = 0, 'Post-delete booking cascade', 'Bookings should be deleted when trip is deleted');
    PERFORM record_test_result(test_suite, 'Booking cascade delete on trip deletion', 'PASS');
    
    -- Note: Payments might still exist with booking_id as NULL depending on schema design
    
    -- =============================================================================
    -- TEST 7: Self-Referencing Foreign Keys
    -- =============================================================================
    
    -- Test support ticket assignment (user can be assigned to another user's ticket)
    DECLARE
        test_user_id UUID;
        test_agent_id UUID;
        test_ticket_id UUID;
    BEGIN
        -- Create test user and agent
        test_user_id := create_test_user('ticket_user@example.com', '+4712345102');
        test_agent_id := create_test_user('agent@example.com', '+4712345103');
        
        -- Create support ticket
        INSERT INTO support_tickets (
            user_id, subject, description, category, assigned_to
        ) VALUES (
            test_user_id, 'Test Issue', 'Test description', 'technical', test_agent_id
        ) RETURNING id INTO test_ticket_id;
        
        PERFORM record_test_result(test_suite, 'Self-referencing FK in support tickets', 'PASS');
        
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Self-referencing FK in support tickets', 'FAIL', SQLERRM);
    END;
    
    -- =============================================================================
    -- TEST 8: Optional Foreign Keys
    -- =============================================================================
    
    DECLARE
        test_user_id2 UUID;
        test_trip_id2 UUID;
    BEGIN
        -- Create user and trip without vehicle (optional FK)
        test_user_id2 := create_test_user('driver2@example.com', '+4712345104');
        
        INSERT INTO trips (
            driver_id, vehicle_id, origin_city, destination_city,
            departure_time, price_per_seat, available_seats, total_seats
        ) VALUES (
            test_user_id2, NULL, 'Bergen', 'Stavanger',
            CURRENT_TIMESTAMP + INTERVAL '2 days', 200.00, 3, 4
        ) RETURNING id INTO test_trip_id2;
        
        PERFORM record_test_result(test_suite, 'Optional foreign key (trip without vehicle)', 'PASS');
        
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Optional foreign key (trip without vehicle)', 'FAIL', SQLERRM);
    END;
    
    -- =============================================================================
    -- TEST 9: Complex Relationship Validation
    -- =============================================================================
    
    DECLARE
        test_driver2_id UUID;
        test_passenger2_id UUID;
        test_trip2_id UUID;
        test_booking2_id UUID;
        test_review_id UUID;
    BEGIN
        -- Create complete trip booking flow
        test_driver2_id := create_test_user('review_driver@example.com', '+4712345105');
        test_passenger2_id := create_test_user('review_passenger@example.com', '+4712345106');
        test_trip2_id := create_test_trip(test_driver2_id, 'Trondheim', 'Oslo');
        
        INSERT INTO bookings (
            trip_id, passenger_id, seats_booked, total_price, status
        ) VALUES (
            test_trip2_id, test_passenger2_id, 1, 250.00, 'confirmed'
        ) RETURNING id INTO test_booking2_id;
        
        -- Create review with proper relationships
        INSERT INTO trip_reviews (
            trip_id, booking_id, reviewer_id, reviewee_id, rating, review_text
        ) VALUES (
            test_trip2_id, test_booking2_id, test_passenger2_id, test_driver2_id, 5, 'Great trip!'
        ) RETURNING id INTO test_review_id;
        
        PERFORM record_test_result(test_suite, 'Complex relationship validation (review)', 'PASS');
        
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Complex relationship validation (review)', 'FAIL', SQLERRM);
    END;
    
    -- Clean up test data
    PERFORM cleanup_test_data();
    
    RAISE NOTICE 'Relationship and Foreign Key Tests completed';
END;
$$;
