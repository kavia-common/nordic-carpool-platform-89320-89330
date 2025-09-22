-- BlablaBil Database Sample Data
-- This file contains sample data for development and testing purposes

-- ============================================================================= 
-- SAMPLE DATA INSERTION
-- =============================================================================

-- Insert sample admin roles (already exists from schema)
-- These are created in the main schema, so we'll just reference them

-- Insert sample users
INSERT INTO users (
    id, email, phone_number, password_hash, first_name, last_name, 
    date_of_birth, gender, norwegian_id, id_verified, 
    profile_picture_url, bio, languages, status, 
    email_verified, phone_verified, is_driver, 
    license_number, license_verified, license_expiry_date,
    avg_rating_as_driver, avg_rating_as_passenger,
    total_trips_as_driver, total_trips_as_passenger,
    subscription_type, credit_balance,
    data_processing_consent, marketing_consent
) VALUES 
-- Driver users
(
    uuid_generate_v4(), 'erik.hansen@email.no', '+4798765432', 
    '$2b$10$example_hashed_password_1', 'Erik', 'Hansen',
    '1985-03-15', 'male', '15038512345', true,
    '/assets/profiles/erik.jpg', 'Hyggelig sjåfør som liker å møte nye mennesker. Kjører forsiktig og punktlig.',
    'nb', 'active', true, true, true,
    'NO123456789', true, '2027-08-20',
    4.7, 4.5, 156, 23, 'premium', 250.00,
    true, true
),
(
    uuid_generate_v4(), 'maria.olsen@gmail.com', '+4799887766', 
    '$2b$10$example_hashed_password_2', 'Maria', 'Olsen',
    '1990-07-22', 'female', '22079012345', true,
    '/assets/profiles/maria.jpg', 'Erfaren sjåfør fra Oslo. Ikke-røyker, liker musikk og gode samtaler.',
    'nb', 'active', true, true, true,
    'NO987654321', true, '2026-12-15',
    4.9, 4.8, 89, 12, 'vip', 450.75,
    true, false
),
(
    uuid_generate_v4(), 'lars.berg@hotmail.com', '+4791234567',
    '$2b$10$example_hashed_password_3', 'Lars', 'Berg',
    '1988-11-08', 'male', '08118812345', true,
    '/assets/profiles/lars.jpg', 'Pendler daglig mellom Bergen og Oslo. Tilbyr regelmessige turer.',
    'nb', 'active', true, true, true,
    'NO456789123', true, '2025-05-30',
    4.6, 4.4, 203, 45, 'basic', 120.50,
    true, true
),
-- Passenger users
(
    uuid_generate_v4(), 'anna.kristiansen@student.uio.no', '+4795556666',
    '$2b$10$example_hashed_password_4', 'Anna', 'Kristiansen',
    '1995-02-28', 'female', '28029512345', true,
    '/assets/profiles/anna.jpg', 'Student ved UiO. Reiser ofte mellom Oslo og Trondheim.',
    'nb', 'active', true, true, false,
    NULL, false, NULL,
    0, 4.8, 0, 67, 'basic', 85.25,
    true, false
),
(
    uuid_generate_v4(), 'thomas.johansen@work.no', '+4792223333',
    '$2b$10$example_hashed_password_5', 'Thomas', 'Johansen',
    '1982-09-14', 'male', '14098212345', true,
    '/assets/profiles/thomas.jpg', 'Jobber i tech. Miljøbevisst og foretrekker samkjøring.',
    'nb', 'active', true, true, false,
    NULL, false, NULL,
    0, 4.7, 0, 34, 'premium', 200.00,
    true, true
),
-- International user
(
    uuid_generate_v4(), 'john.smith@international.com', '+4793334444',
    '$2b$10$example_hashed_password_6', 'John', 'Smith',
    '1987-06-10', 'male', NULL, false,
    '/assets/profiles/john.jpg', 'Expat living in Norway. Speaks English and basic Norwegian.',
    'en', 'active', true, true, true,
    'NO789123456', true, '2026-03-25',
    4.5, 4.6, 45, 28, 'basic', 150.00,
    true, false
);

-- Get user IDs for reference (in a real application, you'd handle this differently)
-- For this seed script, we'll create some variables to use

-- Insert sample vehicles
INSERT INTO vehicles (
    user_id, make, model, year, color, license_plate, 
    seats_available, vehicle_type, fuel_type, transmission,
    air_conditioning, smoking_allowed, pets_allowed, music_allowed,
    vehicle_description, is_active
) VALUES 
(
    (SELECT id FROM users WHERE email = 'erik.hansen@email.no'),
    'Toyota', 'Camry', 2020, 'Blå', 'EL12345', 3, 'car', 'hybrid', 'automatic',
    true, false, true, true,
    'Komfortabel hybrid bil med god plass. Alltid ren og velholdt.',
    true
),
(
    (SELECT id FROM users WHERE email = 'maria.olsen@gmail.com'),
    'Volvo', 'XC60', 2021, 'Sølv', 'MO67890', 4, 'suv', 'diesel', 'automatic',
    true, false, false, true,
    'Romslig SUV perfekt for lange turer. Luksus komfort og sikkerhet.',
    true
),
(
    (SELECT id FROM users WHERE email = 'lars.berg@hotmail.com'),
    'Volkswagen', 'Golf', 2019, 'Hvit', 'LB11223', 3, 'car', 'petrol', 'manual',
    false, false, true, true,
    'Pålitelig økonomi bil. Perfekt for pendling og korte turer.',
    true
),
(
    (SELECT id FROM users WHERE email = 'john.smith@international.com'),
    'Tesla', 'Model 3', 2022, 'Rød', 'JS99888', 4, 'car', 'electric', 'automatic',
    true, false, true, true,
    'Modern electric vehicle. Silent and environmentally friendly.',
    true
);

-- Insert sample trips
INSERT INTO trips (
    driver_id, vehicle_id, origin_city, destination_city,
    origin_address, destination_address,
    departure_time, estimated_arrival_time,
    distance_km, duration_minutes,
    price_per_seat, available_seats, total_seats,
    smoking_allowed, pets_allowed, music_allowed,
    max_two_passengers_back, status, trip_description,
    auto_accept_bookings, is_recurring, recurrence_pattern
) VALUES 
-- Future trips
(
    (SELECT id FROM users WHERE email = 'erik.hansen@email.no'),
    (SELECT id FROM vehicles WHERE license_plate = 'EL12345'),
    'Oslo', 'Bergen',
    'Oslo Sentralstasjon, Oslo', 'Bergen Stasjon, Bergen',
    CURRENT_TIMESTAMP + INTERVAL '2 days', 
    CURRENT_TIMESTAMP + INTERVAL '2 days 7 hours',
    463, 420,
    350.00, 2, 3,
    false, true, true, false, 'active',
    'Komfortabel tur til Bergen. Stopp for kaffe underveis. Vennlig atmosfære.',
    false, false, NULL
),
(
    (SELECT id FROM users WHERE email = 'maria.olsen@gmail.com'),
    (SELECT id FROM vehicles WHERE license_plate = 'MO67890'),
    'Oslo', 'Trondheim',
    'Majorstuen, Oslo', 'Trondheim Sentralstasjon',
    CURRENT_TIMESTAMP + INTERVAL '1 day',
    CURRENT_TIMESTAMP + INTERVAL '1 day 5 hours',
    553, 300,
    280.00, 3, 4,
    false, false, true, false, 'active',
    'Direktetur til Trondheim. Luksus SUV med klimaanlegg. Perfekt for business travel.',
    true, false, NULL
),
(
    (SELECT id FROM users WHERE email = 'lars.berg@hotmail.com'),
    (SELECT id FROM vehicles WHERE license_plate = 'LB11223'),
    'Bergen', 'Oslo',
    'Bergen Sentrum', 'Oslo Sentrum',
    CURRENT_TIMESTAMP + INTERVAL '3 days',
    CURRENT_TIMESTAMP + INTERVAL '3 days 6 hours',
    463, 360,
    300.00, 1, 3,
    false, true, true, true, 'active',
    'Hyggelig tur tilbake til Oslo. Rimelig og pålitelig transport.',
    false, true, 'weekly'
),
(
    (SELECT id FROM users WHERE email = 'john.smith@international.com'),
    (SELECT id FROM vehicles WHERE license_plate = 'JS99888'),
    'Oslo', 'Stavanger',
    'Oslo Airport, Gardermoen', 'Stavanger Airport, Sola',
    CURRENT_TIMESTAMP + INTERVAL '5 days',
    CURRENT_TIMESTAMP + INTERVAL '5 days 4 hours 30 minutes',
    372, 270,
    250.00, 3, 4,
    false, true, true, false, 'active',
    'Electric vehicle trip to Stavanger. Eco-friendly and quiet journey.',
    false, false, NULL
);

-- Insert sample bookings
INSERT INTO bookings (
    trip_id, passenger_id, seats_booked,
    pickup_location, dropoff_location,
    total_price, status, payment_method, payment_status,
    special_requests
) VALUES 
(
    (SELECT id FROM trips WHERE origin_city = 'Oslo' AND destination_city = 'Bergen' 
     AND driver_id = (SELECT id FROM users WHERE email = 'erik.hansen@email.no')),
    (SELECT id FROM users WHERE email = 'anna.kristiansen@student.uio.no'),
    1, 'Oslo Sentralstasjon', 'Bergen Sentrum',
    350.00, 'confirmed', 'vipps', 'completed',
    'Kan vi stoppe for en kaffepaue i Drammen?'
),
(
    (SELECT id FROM trips WHERE origin_city = 'Oslo' AND destination_city = 'Trondheim'
     AND driver_id = (SELECT id FROM users WHERE email = 'maria.olsen@gmail.com')),
    (SELECT id FROM users WHERE email = 'thomas.johansen@work.no'),
    1, 'Majorstuen', 'Trondheim Sentralstasjon',
    280.00, 'confirmed', 'credit', 'completed',
    'Trenger å være på jobb klokka 14:00. Takk!'
);

-- Insert sample payments
INSERT INTO payments (
    booking_id, user_id, amount, currency, payment_method,
    status, external_payment_id, payment_description
) VALUES 
(
    (SELECT b.id FROM bookings b 
     JOIN trips t ON b.trip_id = t.id 
     JOIN users u ON b.passenger_id = u.id 
     WHERE u.email = 'anna.kristiansen@student.uio.no' 
     AND t.origin_city = 'Oslo' AND t.destination_city = 'Bergen'),
    (SELECT id FROM users WHERE email = 'anna.kristiansen@student.uio.no'),
    350.00, 'NOK', 'vipps',
    'completed', 'VIPPS_TXN_001234567', 'Payment for Oslo to Bergen trip'
),
(
    (SELECT b.id FROM bookings b 
     JOIN trips t ON b.trip_id = t.id 
     JOIN users u ON b.passenger_id = u.id 
     WHERE u.email = 'thomas.johansen@work.no' 
     AND t.origin_city = 'Oslo' AND t.destination_city = 'Trondheim'),
    (SELECT id FROM users WHERE email = 'thomas.johansen@work.no'),
    280.00, 'NOK', 'credit',
    'completed', NULL, 'Credit payment for Oslo to Trondheim trip'
);

-- Insert credit transactions
INSERT INTO credit_transactions (
    user_id, amount, transaction_type, description,
    booking_id, balance_before, balance_after
) VALUES 
(
    (SELECT id FROM users WHERE email = 'thomas.johansen@work.no'),
    -280.00, 'payment', 'Payment for trip booking',
    (SELECT b.id FROM bookings b 
     JOIN trips t ON b.trip_id = t.id 
     JOIN users u ON b.passenger_id = u.id 
     WHERE u.email = 'thomas.johansen@work.no'),
    480.00, 200.00
),
(
    (SELECT id FROM users WHERE email = 'anna.kristiansen@student.uio.no'),
    100.00, 'purchase', 'Credit purchase via Vipps',
    NULL, 350.25, 450.25
),
(
    (SELECT id FROM users WHERE email = 'maria.olsen@gmail.com'),
    50.00, 'bonus', 'Premium subscription monthly bonus',
    NULL, 400.75, 450.75
);

-- Insert sample trip reviews
INSERT INTO trip_reviews (
    trip_id, booking_id, reviewer_id, reviewee_id,
    rating, review_text,
    punctuality_rating, communication_rating, 
    cleanliness_rating, driving_rating
) VALUES 
-- Anna reviews Erik (driver)
(
    (SELECT t.id FROM trips t 
     JOIN users u ON t.driver_id = u.id 
     WHERE u.email = 'erik.hansen@email.no' 
     AND t.origin_city = 'Oslo' AND t.destination_city = 'Bergen'),
    (SELECT b.id FROM bookings b 
     JOIN trips t ON b.trip_id = t.id 
     JOIN users u ON b.passenger_id = u.id 
     WHERE u.email = 'anna.kristiansen@student.uio.no'),
    (SELECT id FROM users WHERE email = 'anna.kristiansen@student.uio.no'),
    (SELECT id FROM users WHERE email = 'erik.hansen@email.no'),
    5, 'Fantastisk tur! Erik var punktlig, hyggelig og bil var ren. Anbefaler sterkt!',
    5, 5, 5, 5
),
-- Erik reviews Anna (passenger)
(
    (SELECT t.id FROM trips t 
     JOIN users u ON t.driver_id = u.id 
     WHERE u.email = 'erik.hansen@email.no' 
     AND t.origin_city = 'Oslo' AND t.destination_city = 'Bergen'),
    (SELECT b.id FROM bookings b 
     JOIN trips t ON b.trip_id = t.id 
     JOIN users u ON b.passenger_id = u.id 
     WHERE u.email = 'anna.kristiansen@student.uio.no'),
    (SELECT id FROM users WHERE email = 'erik.hansen@email.no'),
    (SELECT id FROM users WHERE email = 'anna.kristiansen@student.uio.no'),
    5, 'Anna var en fin passasjer. Punktlig og hyggelig selskap på turen.',
    5, 5, 5, 4
);

-- Insert sample support tickets
INSERT INTO support_tickets (
    user_id, subject, description, category, priority, status
) VALUES 
(
    (SELECT id FROM users WHERE email = 'anna.kristiansen@student.uio.no'),
    'Problem med betaling via Vipps',
    'Jeg prøvde å betale for en tur, men Vipps-betalingen feilet. Pengene er trukket fra kontoen min, men bookingen viser som ikke betalt.',
    'payment', 'high', 'open'
),
(
    (SELECT id FROM users WHERE email = 'thomas.johansen@work.no'),
    'Kan ikke finne min booking',
    'Jeg bookd en tur for i går, men kan ikke finne den i min profil. Kan dere hjelpe meg?',
    'booking', 'medium', 'resolved'
);

-- Insert sample notifications
INSERT INTO notifications (
    user_id, title, message, notification_type, channel,
    status, related_trip_id, priority
) VALUES 
(
    (SELECT id FROM users WHERE email = 'anna.kristiansen@student.uio.no'),
    'Booking bekreftet',
    'Din booking fra Oslo til Bergen den 25. mars er bekreftet. Sjåfør: Erik Hansen.',
    'booking_confirmation', 'email',
    'delivered', 
    (SELECT id FROM trips WHERE origin_city = 'Oslo' AND destination_city = 'Bergen' 
     AND driver_id = (SELECT id FROM users WHERE email = 'erik.hansen@email.no')),
    'normal'
),
(
    (SELECT id FROM users WHERE email = 'erik.hansen@email.no'),
    'Ny booking mottatt',
    'Du har fått en ny booking for turen Oslo - Bergen. Passasjer: Anna K.',
    'new_booking', 'push',
    'delivered',
    (SELECT id FROM trips WHERE origin_city = 'Oslo' AND destination_city = 'Bergen' 
     AND driver_id = (SELECT id FROM users WHERE email = 'erik.hansen@email.no')),
    'normal'
),
(
    (SELECT id FROM users WHERE email = 'thomas.johansen@work.no'),
    'Turpåminnelse',
    'Din tur fra Oslo til Trondheim starter om 2 timer. Møtested: Majorstuen.',
    'trip_reminder', 'sms',
    'sent',
    (SELECT id FROM trips WHERE origin_city = 'Oslo' AND destination_city = 'Trondheim'
     AND driver_id = (SELECT id FROM users WHERE email = 'maria.olsen@gmail.com')),
    'high'
);

-- Insert sample FAQ items (Norwegian)
INSERT INTO faq_items (
    category_id, question, answer, display_order, language
) VALUES 
(
    (SELECT id FROM faq_categories WHERE name = 'Generelt' AND language = 'nb'),
    'Hvordan fungerer BlablaBil?',
    'BlablaBil kobler sammen sjåfører som har ledige plasser i bilen med passasjerer som trenger transport. Sjåfører legger ut turer, og passasjerer kan søke og booke plasser.',
    1, 'nb'
),
(
    (SELECT id FROM faq_categories WHERE name = 'Generelt' AND language = 'nb'),
    'Er BlablaBil trygt å bruke?',
    'Ja, vi har flere sikkerhetstiltak inkludert ID-verifisering, førerkortverifisering, vurderingssystem og 24/7 kundesupport.',
    2, 'nb'
),
(
    (SELECT id FROM faq_categories WHERE name = 'Booking' AND language = 'nb'),
    'Hvordan booker jeg en tur?',
    'Søk etter din ønskede rute og dato, velg en tur som passer deg, og klikk "Book". Følg instruksjonene for å fullføre betalingen.',
    1, 'nb'
),
(
    (SELECT id FROM faq_categories WHERE name = 'Betaling' AND language = 'nb'),
    'Hvilke betalingsmetoder aksepterer dere?',
    'Vi aksepterer Vipps, kontant betaling til sjåfør, og BlablaBil-kreditt. Vipps er den anbefalte metoden.',
    1, 'nb'
);

-- Insert sample FAQ items (English)
INSERT INTO faq_items (
    category_id, question, answer, display_order, language
) VALUES 
(
    (SELECT id FROM faq_categories WHERE name = 'General' AND language = 'en'),
    'How does BlablaBil work?',
    'BlablaBil connects drivers who have empty seats with passengers who need transportation. Drivers post trips, and passengers can search and book seats.',
    1, 'en'
),
(
    (SELECT id FROM faq_categories WHERE name = 'General' AND language = 'en'),
    'Is BlablaBil safe to use?',
    'Yes, we have several safety measures including ID verification, license verification, rating system, and 24/7 customer support.',
    2, 'en'
),
(
    (SELECT id FROM faq_categories WHERE name = 'Booking' AND language = 'en'),
    'How do I book a trip?',
    'Search for your desired route and date, choose a trip that suits you, and click "Book". Follow the instructions to complete payment.',
    1, 'en'
),
(
    (SELECT id FROM faq_categories WHERE name = 'Payment' AND language = 'en'),
    'What payment methods do you accept?',
    'We accept Vipps, cash payment to driver, and BlablaBil credit. Vipps is the recommended method.',
    1, 'en'
);

-- Insert sample subscriptions
INSERT INTO subscriptions (
    user_id, subscription_type, status, monthly_price,
    billing_cycle, next_billing_date, auto_renew,
    monthly_credit_bonus, reduced_commission_rate
) VALUES 
(
    (SELECT id FROM users WHERE email = 'maria.olsen@gmail.com'),
    'vip', 'active', 99.00,
    'monthly', CURRENT_DATE + INTERVAL '1 month', true,
    50.00, 0.02
),
(
    (SELECT id FROM users WHERE email = 'thomas.johansen@work.no'),
    'premium', 'active', 49.00,
    'monthly', CURRENT_DATE + INTERVAL '1 month', true,
    25.00, 0.01
);

-- Update user credit balances based on credit transactions
UPDATE users SET credit_balance = (
    SELECT COALESCE(SUM(amount), 0) 
    FROM credit_transactions 
    WHERE credit_transactions.user_id = users.id
) + users.credit_balance;

-- Log the sample data insertion
INSERT INTO system_logs (
    log_level, log_category, message, additional_data
) VALUES 
(
    'INFO', 'database', 'Sample data inserted successfully',
    '{"tables_populated": ["users", "vehicles", "trips", "bookings", "payments", "credit_transactions", "trip_reviews", "support_tickets", "notifications", "faq_items", "subscriptions"], "timestamp": "' || CURRENT_TIMESTAMP || '"}'
);

-- Display summary
SELECT 'Sample data insertion completed successfully!' as status;
SELECT 
    'Users: ' || (SELECT COUNT(*) FROM users) ||
    ', Trips: ' || (SELECT COUNT(*) FROM trips) ||
    ', Bookings: ' || (SELECT COUNT(*) FROM bookings) ||
    ', Payments: ' || (SELECT COUNT(*) FROM payments) ||
    ', Reviews: ' || (SELECT COUNT(*) FROM trip_reviews) ||
    ', FAQ Items: ' || (SELECT COUNT(*) FROM faq_items)
    as summary;
