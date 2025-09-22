-- BlablaBil Database Support and GDPR Tests
-- Testing notifications, support tickets, and GDPR compliance features

-- Load test utilities
\i test_setup.sql

-- =============================================================================
-- SUPPORT AND GDPR FUNCTIONALITY TESTS
-- =============================================================================

DO $$
DECLARE
    test_user_id UUID;
    test_agent_id UUID;
    test_ticket_id UUID;
    test_notification_id UUID;
    test_gdpr_log_id UUID;
    test_suite TEXT := 'SUPPORT_GDPR';
    row_count INTEGER;
BEGIN
    RAISE NOTICE 'Starting Support and GDPR Tests...';
    
    -- Clean up before tests
    PERFORM cleanup_test_data();
    
    -- =============================================================================
    -- TEST 1: Notification System Tests
    -- =============================================================================
    
    test_user_id := create_test_user('notification_user@example.com', '+4712345200');
    
    BEGIN
        -- Test notification creation with all channels
        INSERT INTO notifications (
            user_id, title, message, notification_type, channel, priority
        ) VALUES (
            test_user_id, 'Test Notification', 'This is a test message', 'system', 'email', 'normal'
        ) RETURNING id INTO test_notification_id;
        
        PERFORM record_test_result(test_suite, 'Create email notification', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create email notification', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Test SMS notification
        INSERT INTO notifications (
            user_id, title, message, notification_type, channel, priority
        ) VALUES (
            test_user_id, 'SMS Test', 'SMS message', 'trip_reminder', 'sms', 'high'
        );
        
        PERFORM record_test_result(test_suite, 'Create SMS notification', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create SMS notification', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Test push notification
        INSERT INTO notifications (
            user_id, title, message, notification_type, channel, priority
        ) VALUES (
            test_user_id, 'Push Test', 'Push message', 'booking_update', 'push', 'urgent'
        );
        
        PERFORM record_test_result(test_suite, 'Create push notification', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create push notification', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Test in-app notification
        INSERT INTO notifications (
            user_id, title, message, notification_type, channel, priority
        ) VALUES (
            test_user_id, 'In-App Test', 'In-app message', 'payment_update', 'in_app', 'low'
        );
        
        PERFORM record_test_result(test_suite, 'Create in-app notification', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create in-app notification', 'FAIL', SQLERRM);
    END;
    
    -- Test notification channel constraint
    BEGIN
        INSERT INTO notifications (
            user_id, title, message, notification_type, channel, priority
        ) VALUES (
            test_user_id, 'Invalid Channel', 'Test message', 'system', 'invalid_channel', 'normal'
        );
        
        PERFORM record_test_result(test_suite, 'Invalid notification channel constraint', 'FAIL', 'Should have failed with invalid channel');
    EXCEPTION WHEN CHECK_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Invalid notification channel constraint', 'PASS');
    END;
    
    -- Test notification status constraint
    BEGIN
        INSERT INTO notifications (
            user_id, title, message, notification_type, channel, status
        ) VALUES (
            test_user_id, 'Invalid Status', 'Test message', 'system', 'email', 'invalid_status'
        );
        
        PERFORM record_test_result(test_suite, 'Invalid notification status constraint', 'FAIL', 'Should have failed with invalid status');
    EXCEPTION WHEN CHECK_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Invalid notification status constraint', 'PASS');
    END;
    
    -- Test notification priority constraint
    BEGIN
        INSERT INTO notifications (
            user_id, title, message, notification_type, channel, priority
        ) VALUES (
            test_user_id, 'Invalid Priority', 'Test message', 'system', 'email', 'invalid_priority'
        );
        
        PERFORM record_test_result(test_suite, 'Invalid notification priority constraint', 'FAIL', 'Should have failed with invalid priority');
    EXCEPTION WHEN CHECK_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Invalid notification priority constraint', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 2: Notification Templates Tests
    -- =============================================================================
    
    BEGIN
        -- Test notification template creation
        INSERT INTO notification_templates (
            template_name, template_type, subject_template, body_template, language
        ) VALUES (
            'test_template_email', 'email', 'Test Subject: {trip_route}', 'Test body with {user_name}', 'nb'
        );
        
        PERFORM record_test_result(test_suite, 'Create email notification template', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create email notification template', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Test SMS template (no subject)
        INSERT INTO notification_templates (
            template_name, template_type, body_template, language
        ) VALUES (
            'test_template_sms', 'sms', 'SMS: Your trip from {origin} to {destination}', 'en'
        );
        
        PERFORM record_test_result(test_suite, 'Create SMS notification template', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create SMS notification template', 'FAIL', SQLERRM);
    END;
    
    -- Test template type constraint
    BEGIN
        INSERT INTO notification_templates (
            template_name, template_type, body_template
        ) VALUES (
            'test_invalid_type', 'invalid_type', 'Test body'
        );
        
        PERFORM record_test_result(test_suite, 'Invalid template type constraint', 'FAIL', 'Should have failed with invalid type');
    EXCEPTION WHEN CHECK_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Invalid template type constraint', 'PASS');
    END;
    
    -- Test template language constraint
    BEGIN
        INSERT INTO notification_templates (
            template_name, template_type, body_template, language
        ) VALUES (
            'test_invalid_language', 'email', 'Test body', 'invalid_lang'
        );
        
        PERFORM record_test_result(test_suite, 'Invalid template language constraint', 'FAIL', 'Should have failed with invalid language');
    EXCEPTION WHEN CHECK_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Invalid template language constraint', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 3: Support Ticket System Tests
    -- =============================================================================
    
    test_agent_id := create_test_user('support_agent@example.com', '+4712345201');
    
    BEGIN
        -- Create support ticket
        INSERT INTO support_tickets (
            user_id, subject, description, category, priority, assigned_to
        ) VALUES (
            test_user_id, 'Test Support Issue', 'Detailed description of the issue', 'technical', 'medium', test_agent_id
        ) RETURNING id INTO test_ticket_id;
        
        PERFORM record_test_result(test_suite, 'Create support ticket', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create support ticket', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Add message to support ticket
        INSERT INTO support_ticket_messages (
            ticket_id, sender_id, message, message_type
        ) VALUES (
            test_ticket_id, test_user_id, 'This is my first message about the issue', 'text'
        );
        
        PERFORM record_test_result(test_suite, 'Add message to support ticket', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Add message to support ticket', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Add agent response
        INSERT INTO support_ticket_messages (
            ticket_id, sender_id, message, message_type, is_internal
        ) VALUES (
            test_ticket_id, test_agent_id, 'Internal note: Escalate to technical team', 'text', TRUE
        );
        
        PERFORM record_test_result(test_suite, 'Add internal agent message', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Add internal agent message', 'FAIL', SQLERRM);
    END;
    
    -- Test support ticket status constraint
    BEGIN
        INSERT INTO support_tickets (
            user_id, subject, description, category, status
        ) VALUES (
            test_user_id, 'Invalid Status Ticket', 'Test description', 'payment', 'invalid_status'
        );
        
        PERFORM record_test_result(test_suite, 'Invalid ticket status constraint', 'FAIL', 'Should have failed with invalid status');
    EXCEPTION WHEN CHECK_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Invalid ticket status constraint', 'PASS');
    END;
    
    -- Test support ticket priority constraint
    BEGIN
        INSERT INTO support_tickets (
            user_id, subject, description, category, priority
        ) VALUES (
            test_user_id, 'Invalid Priority Ticket', 'Test description', 'booking', 'invalid_priority'
        );
        
        PERFORM record_test_result(test_suite, 'Invalid ticket priority constraint', 'FAIL', 'Should have failed with invalid priority');
    EXCEPTION WHEN CHECK_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Invalid ticket priority constraint', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 4: FAQ System Tests
    -- =============================================================================
    
    DECLARE
        test_category_id UUID;
        test_faq_id UUID;
    BEGIN
        -- Create FAQ category
        INSERT INTO faq_categories (
            name, description, display_order, language
        ) VALUES (
            'Test Category', 'Test category for testing', 1, 'nb'
        ) RETURNING id INTO test_category_id;
        
        PERFORM record_test_result(test_suite, 'Create FAQ category', 'PASS');
        
        -- Create FAQ item
        INSERT INTO faq_items (
            category_id, question, answer, display_order, language
        ) VALUES (
            test_category_id, 'Test question?', 'Test answer with detailed information.', 1, 'nb'
        ) RETURNING id INTO test_faq_id;
        
        PERFORM record_test_result(test_suite, 'Create FAQ item', 'PASS');
        
        -- Test FAQ language constraint
        INSERT INTO faq_items (
            category_id, question, answer, language
        ) VALUES (
            test_category_id, 'English question?', 'English answer.', 'en'
        );
        
        PERFORM record_test_result(test_suite, 'Create FAQ item in English', 'PASS');
        
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'FAQ system operations', 'FAIL', SQLERRM);
    END;
    
    -- Test FAQ language constraint violation
    BEGIN
        INSERT INTO faq_categories (
            name, description, language
        ) VALUES (
            'Invalid Language Category', 'Test description', 'invalid_lang'
        );
        
        PERFORM record_test_result(test_suite, 'Invalid FAQ language constraint', 'FAIL', 'Should have failed with invalid language');
    EXCEPTION WHEN CHECK_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Invalid FAQ language constraint', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 5: GDPR Data Processing Tests
    -- =============================================================================
    
    BEGIN
        -- Test GDPR data export request
        INSERT INTO gdpr_data_logs (
            user_id, processing_type, processing_reason, data_categories, status
        ) VALUES (
            test_user_id, 'export', 'User requested data export', ARRAY['personal_data', 'trip_history'], 'pending'
        ) RETURNING id INTO test_gdpr_log_id;
        
        PERFORM record_test_result(test_suite, 'Create GDPR data export log', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create GDPR data export log', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Test GDPR data anonymization request
        INSERT INTO gdpr_data_logs (
            user_id, processing_type, processing_reason, data_categories, requested_by, status
        ) VALUES (
            test_user_id, 'anonymize', 'Account deletion requested', ARRAY['all_data'], test_agent_id, 'in_progress'
        );
        
        PERFORM record_test_result(test_suite, 'Create GDPR anonymization log', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create GDPR anonymization log', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Test GDPR consent update
        INSERT INTO gdpr_data_logs (
            user_id, processing_type, processing_reason, data_categories, status
        ) VALUES (
            test_user_id, 'consent_update', 'User updated marketing consent', ARRAY['consent_data'], 'completed'
        );
        
        PERFORM record_test_result(test_suite, 'Create GDPR consent update log', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Create GDPR consent update log', 'FAIL', SQLERRM);
    END;
    
    -- Test GDPR processing type constraint
    BEGIN
        INSERT INTO gdpr_data_logs (
            user_id, processing_type, processing_reason, data_categories
        ) VALUES (
            test_user_id, 'invalid_type', 'Test reason', ARRAY['test_data']
        );
        
        PERFORM record_test_result(test_suite, 'Invalid GDPR processing type constraint', 'FAIL', 'Should have failed with invalid processing type');
    EXCEPTION WHEN CHECK_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Invalid GDPR processing type constraint', 'PASS');
    END;
    
    -- Test GDPR status constraint
    BEGIN
        INSERT INTO gdpr_data_logs (
            user_id, processing_type, processing_reason, data_categories, status
        ) VALUES (
            test_user_id, 'export', 'Test reason', ARRAY['test_data'], 'invalid_status'
        );
        
        PERFORM record_test_result(test_suite, 'Invalid GDPR status constraint', 'FAIL', 'Should have failed with invalid status');
    EXCEPTION WHEN CHECK_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Invalid GDPR status constraint', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 6: Admin Roles and Permissions Tests
    -- =============================================================================
    
    DECLARE
        test_role_id UUID;
        test_admin_user_id UUID;
    BEGIN
        -- Test admin role creation
        INSERT INTO admin_roles (
            role_name, description, permissions
        ) VALUES (
            'test_role', 'Test role for testing', '{"users": "read", "tickets": "full"}'::jsonb
        ) RETURNING id INTO test_role_id;
        
        PERFORM record_test_result(test_suite, 'Create admin role', 'PASS');
        
        -- Test admin user assignment
        INSERT INTO admin_users (
            user_id, role_id, granted_by
        ) VALUES (
            test_agent_id, test_role_id, test_agent_id
        ) RETURNING id INTO test_admin_user_id;
        
        PERFORM record_test_result(test_suite, 'Assign admin role to user', 'PASS');
        
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Admin role operations', 'FAIL', SQLERRM);
    END;
    
    -- Test unique admin role name
    BEGIN
        INSERT INTO admin_roles (
            role_name, description, permissions
        ) VALUES (
            'test_role', 'Duplicate role name', '{"test": "permission"}'::jsonb
        );
        
        PERFORM record_test_result(test_suite, 'Duplicate admin role name constraint', 'FAIL', 'Should have failed with unique violation');
    EXCEPTION WHEN UNIQUE_VIOLATION THEN
        PERFORM record_test_result(test_suite, 'Duplicate admin role name constraint', 'PASS');
    END;
    
    -- =============================================================================
    -- TEST 7: Data Retention and Privacy Tests
    -- =============================================================================
    
    BEGIN
        -- Test data retention date setting
        UPDATE users 
        SET data_retention_until = CURRENT_DATE + INTERVAL '7 years'
        WHERE id = test_user_id;
        
        PERFORM record_test_result(test_suite, 'Set data retention date', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Set data retention date', 'FAIL', SQLERRM);
    END;
    
    BEGIN
        -- Test consent management
        UPDATE users 
        SET data_processing_consent = TRUE,
            marketing_consent = FALSE
        WHERE id = test_user_id;
        
        PERFORM record_test_result(test_suite, 'Update consent settings', 'PASS');
    EXCEPTION WHEN OTHERS THEN
        PERFORM record_test_result(test_suite, 'Update consent settings', 'FAIL', SQLERRM);
    END;
    
    -- Clean up test data
    PERFORM cleanup_test_data();
    
    RAISE NOTICE 'Support and GDPR Tests completed';
END;
$$;
