-- BlablaBil Carpooling Platform Database Schema
-- PostgreSQL database schema for the Norwegian carpooling platform
-- Database: blablabil_database

-- Enable UUID extension for unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable PostGIS extension for location features (if needed for future geo features)
-- CREATE EXTENSION IF NOT EXISTS postgis;

-- =============================================================================
-- USERS AND AUTHENTICATION
-- =============================================================================

-- Users table - Core user information
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL, -- Norwegian phone format
    password_hash VARCHAR(255) NOT NULL,
    
    -- Personal information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(20),
    
    -- Norwegian ID verification
    norwegian_id VARCHAR(11) UNIQUE, -- Norwegian national ID (11 digits)
    id_verified BOOLEAN DEFAULT FALSE,
    id_verification_date TIMESTAMP,
    
    -- Profile information
    profile_picture_url VARCHAR(500),
    bio TEXT,
    languages VARCHAR(100) DEFAULT 'nb', -- Language preference (nb, nn, en)
    
    -- Account status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deactivated', 'pending_verification')),
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    
    -- GDPR compliance
    data_processing_consent BOOLEAN DEFAULT FALSE,
    marketing_consent BOOLEAN DEFAULT FALSE,
    data_retention_until DATE,
    
    -- Driver-specific information
    is_driver BOOLEAN DEFAULT FALSE,
    license_number VARCHAR(50),
    license_verified BOOLEAN DEFAULT FALSE,
    license_expiry_date DATE,
    license_verification_date TIMESTAMP,
    
    -- Rating and reputation
    avg_rating_as_driver DECIMAL(3,2) DEFAULT 0,
    avg_rating_as_passenger DECIMAL(3,2) DEFAULT 0,
    total_trips_as_driver INTEGER DEFAULT 0,
    total_trips_as_passenger INTEGER DEFAULT 0,
    
    -- Subscription and credits
    subscription_type VARCHAR(20) DEFAULT 'basic' CHECK (subscription_type IN ('basic', 'premium', 'vip')),
    credit_balance DECIMAL(10,2) DEFAULT 0.00,
    
    -- Notifications preferences
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT TRUE
);

-- User sessions for authentication management
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    device_info TEXT,
    ip_address INET,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Password reset tokens
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- VEHICLES AND DRIVER INFORMATION
-- =============================================================================

-- User vehicles
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INTEGER,
    color VARCHAR(30),
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    seats_available INTEGER NOT NULL DEFAULT 4,
    vehicle_type VARCHAR(20) DEFAULT 'car' CHECK (vehicle_type IN ('car', 'van', 'suv', 'other')),
    fuel_type VARCHAR(20) CHECK (fuel_type IN ('petrol', 'diesel', 'electric', 'hybrid')),
    transmission VARCHAR(20) CHECK (transmission IN ('manual', 'automatic')),
    air_conditioning BOOLEAN DEFAULT FALSE,
    smoking_allowed BOOLEAN DEFAULT FALSE,
    pets_allowed BOOLEAN DEFAULT FALSE,
    music_allowed BOOLEAN DEFAULT TRUE,
    vehicle_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- TRIPS AND BOOKINGS
-- =============================================================================

-- Trips table - Core trip information
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vehicle_id UUID REFERENCES vehicles(id),
    
    -- Route information
    origin_city VARCHAR(100) NOT NULL,
    destination_city VARCHAR(100) NOT NULL,
    origin_address TEXT,
    destination_address TEXT,
    origin_latitude DECIMAL(10, 8),
    origin_longitude DECIMAL(11, 8),
    destination_latitude DECIMAL(10, 8),
    destination_longitude DECIMAL(11, 8),
    
    -- Trip details
    departure_time TIMESTAMP NOT NULL,
    estimated_arrival_time TIMESTAMP,
    distance_km DECIMAL(10, 2),
    duration_minutes INTEGER,
    
    -- Pricing and availability
    price_per_seat DECIMAL(10, 2) NOT NULL,
    available_seats INTEGER NOT NULL,
    total_seats INTEGER NOT NULL,
    
    -- Trip preferences
    smoking_allowed BOOLEAN DEFAULT FALSE,
    pets_allowed BOOLEAN DEFAULT FALSE,
    music_allowed BOOLEAN DEFAULT TRUE,
    max_two_passengers_back BOOLEAN DEFAULT FALSE,
    
    -- Trip status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'completed', 'in_progress')),
    
    -- Additional information
    trip_description TEXT,
    auto_accept_bookings BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- Recurring trip information
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern VARCHAR(50), -- 'daily', 'weekly', 'monthly'
    recurrence_end_date DATE
);

-- Trip waypoints for intermediate stops
CREATE TABLE trip_waypoints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    city VARCHAR(100) NOT NULL,
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    stop_order INTEGER NOT NULL,
    estimated_arrival_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bookings table - Passenger trip bookings
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    passenger_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Booking details
    seats_booked INTEGER NOT NULL DEFAULT 1,
    pickup_location VARCHAR(200),
    dropoff_location VARCHAR(200),
    pickup_latitude DECIMAL(10, 8),
    pickup_longitude DECIMAL(11, 8),
    dropoff_latitude DECIMAL(10, 8),
    dropoff_longitude DECIMAL(11, 8),
    
    -- Pricing
    total_price DECIMAL(10, 2) NOT NULL,
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'no_show')),
    
    -- Payment information
    payment_method VARCHAR(20) CHECK (payment_method IN ('vipps', 'cash', 'credit')),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    
    -- Special requests
    special_requests TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- Cancellation information
    cancelled_by UUID REFERENCES users(id),
    cancellation_reason TEXT,
    
    UNIQUE(trip_id, passenger_id)
);

-- =============================================================================
-- PAYMENT AND FINANCIAL MANAGEMENT
-- =============================================================================

-- Payment transactions
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(id),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Transaction details
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'NOK',
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('vipps', 'cash', 'credit', 'bank_transfer')),
    
    -- Payment status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded')),
    
    -- External payment references
    external_payment_id VARCHAR(255), -- Vipps transaction ID, etc.
    external_payment_reference VARCHAR(255),
    
    -- Payment metadata
    payment_description TEXT,
    failure_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- Refund information
    refunded_amount DECIMAL(10, 2),
    refunded_at TIMESTAMP,
    refund_reason TEXT
);

-- Credit transactions for credit-based payments
CREATE TABLE credit_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Transaction details
    amount DECIMAL(10, 2) NOT NULL, -- Positive for credit additions, negative for deductions
    transaction_type VARCHAR(30) NOT NULL CHECK (transaction_type IN ('purchase', 'payment', 'refund', 'bonus', 'adjustment', 'expiry')),
    description TEXT,
    
    -- Related records
    booking_id UUID REFERENCES bookings(id),
    payment_id UUID REFERENCES payments(id),
    
    -- Balance tracking
    balance_before DECIMAL(10, 2) NOT NULL,
    balance_after DECIMAL(10, 2) NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP -- For credits with expiration
);

-- Subscription management
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Subscription details
    subscription_type VARCHAR(20) NOT NULL CHECK (subscription_type IN ('basic', 'premium', 'vip')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'suspended')),
    
    -- Billing
    monthly_price DECIMAL(10, 2) NOT NULL,
    billing_cycle VARCHAR(20) DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly')),
    next_billing_date DATE,
    
    -- Timestamps
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    
    -- Auto-renewal
    auto_renew BOOLEAN DEFAULT TRUE,
    
    -- Benefits
    monthly_credit_bonus DECIMAL(10, 2) DEFAULT 0.00,
    reduced_commission_rate DECIMAL(5, 4) DEFAULT 0.0000
);

-- =============================================================================
-- RATINGS AND REVIEWS
-- =============================================================================

-- Trip ratings and reviews
CREATE TABLE trip_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id),
    reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reviewee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Rating (1-5 stars)
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    
    -- Review content
    review_text TEXT,
    
    -- Review categories
    punctuality_rating INTEGER CHECK (punctuality_rating >= 1 AND punctuality_rating <= 5),
    communication_rating INTEGER CHECK (communication_rating >= 1 AND communication_rating <= 5),
    cleanliness_rating INTEGER CHECK (cleanliness_rating >= 1 AND cleanliness_rating <= 5),
    driving_rating INTEGER CHECK (driving_rating >= 1 AND driving_rating <= 5),
    
    -- Review status
    is_visible BOOLEAN DEFAULT TRUE,
    is_reported BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(trip_id, reviewer_id, reviewee_id)
);

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

-- Notification templates
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(100) UNIQUE NOT NULL,
    template_type VARCHAR(20) NOT NULL CHECK (template_type IN ('email', 'sms', 'push')),
    
    -- Template content
    subject_template TEXT,
    body_template TEXT NOT NULL,
    
    -- Localization
    language VARCHAR(5) DEFAULT 'nb' CHECK (language IN ('nb', 'nn', 'en')),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Notification content
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(30) NOT NULL,
    
    -- Delivery channels
    channel VARCHAR(20) NOT NULL CHECK (channel IN ('email', 'sms', 'push', 'in_app')),
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'read')),
    
    -- Related records
    related_trip_id UUID REFERENCES trips(id),
    related_booking_id UUID REFERENCES bookings(id),
    
    -- Delivery tracking
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    
    -- Error tracking
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Priority
    priority VARCHAR(10) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent'))
);

-- =============================================================================
-- SUPPORT AND HELP
-- =============================================================================

-- FAQ categories
CREATE TABLE faq_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    language VARCHAR(5) DEFAULT 'nb' CHECK (language IN ('nb', 'nn', 'en')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FAQ items
CREATE TABLE faq_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES faq_categories(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    language VARCHAR(5) DEFAULT 'nb' CHECK (language IN ('nb', 'nn', 'en')),
    view_count INTEGER DEFAULT 0,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Support tickets
CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Ticket details
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    
    -- Status
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed', 'escalated')),
    
    -- Assignment
    assigned_to UUID REFERENCES users(id), -- Support agent
    
    -- Related records
    related_trip_id UUID REFERENCES trips(id),
    related_booking_id UUID REFERENCES bookings(id),
    
    -- Resolution
    resolution TEXT,
    satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    closed_at TIMESTAMP
);

-- Support ticket messages
CREATE TABLE support_ticket_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Message content
    message TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
    
    -- Attachments
    attachment_url VARCHAR(500),
    attachment_name VARCHAR(255),
    
    -- Status
    is_internal BOOLEAN DEFAULT FALSE, -- Internal notes for support agents
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- ADMINISTRATIVE AND LOGGING
-- =============================================================================

-- Admin users and roles
CREATE TABLE admin_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL, -- JSON object with permission flags
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin user assignments
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES admin_roles(id),
    granted_by UUID REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    UNIQUE(user_id, role_id)
);

-- System logs for audit trail
CREATE TABLE system_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Log details
    log_level VARCHAR(10) NOT NULL CHECK (log_level IN ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')),
    log_category VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    
    -- Context
    user_id UUID REFERENCES users(id),
    session_id UUID,
    ip_address INET,
    user_agent TEXT,
    
    -- Related records
    related_trip_id UUID REFERENCES trips(id),
    related_booking_id UUID REFERENCES bookings(id),
    related_payment_id UUID REFERENCES payments(id),
    
    -- Additional data
    additional_data JSONB,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User activity logs
CREATE TABLE user_activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Activity details
    activity_type VARCHAR(50) NOT NULL,
    activity_description TEXT,
    
    -- Context
    ip_address INET,
    user_agent TEXT,
    
    -- Related records
    related_trip_id UUID REFERENCES trips(id),
    related_booking_id UUID REFERENCES bookings(id),
    
    -- Additional data
    metadata JSONB,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- GDPR data processing logs
CREATE TABLE gdpr_data_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Data processing details
    processing_type VARCHAR(50) NOT NULL CHECK (processing_type IN ('export', 'anonymize', 'delete', 'consent_update')),
    processing_reason TEXT,
    data_categories TEXT[], -- Array of data categories processed
    
    -- Request details
    requested_by UUID REFERENCES users(id), -- Admin who processed the request
    request_reference VARCHAR(100),
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    
    -- Results
    result_summary TEXT,
    exported_data_url VARCHAR(500), -- For data export requests
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =============================================================================

-- User indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_norwegian_id ON users(norwegian_id);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Trip indexes
CREATE INDEX idx_trips_driver_id ON trips(driver_id);
CREATE INDEX idx_trips_origin_city ON trips(origin_city);
CREATE INDEX idx_trips_destination_city ON trips(destination_city);
CREATE INDEX idx_trips_departure_time ON trips(departure_time);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_created_at ON trips(created_at);
CREATE INDEX idx_trips_route ON trips(origin_city, destination_city, departure_time);

-- Booking indexes
CREATE INDEX idx_bookings_trip_id ON bookings(trip_id);
CREATE INDEX idx_bookings_passenger_id ON bookings(passenger_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_created_at ON bookings(created_at);

-- Payment indexes
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_payment_method ON payments(payment_method);
CREATE INDEX idx_payments_created_at ON payments(created_at);

-- Notification indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_channel ON notifications(channel);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Session indexes
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);

-- Support ticket indexes
CREATE INDEX idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);
CREATE INDEX idx_support_tickets_category ON support_tickets(category);
CREATE INDEX idx_support_tickets_assigned_to ON support_tickets(assigned_to);
CREATE INDEX idx_support_tickets_created_at ON support_tickets(created_at);

-- System log indexes
CREATE INDEX idx_system_logs_user_id ON system_logs(user_id);
CREATE INDEX idx_system_logs_log_level ON system_logs(log_level);
CREATE INDEX idx_system_logs_log_category ON system_logs(log_category);
CREATE INDEX idx_system_logs_created_at ON system_logs(created_at);

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Function to update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trips_updated_at 
    BEFORE UPDATE ON trips 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicles_updated_at 
    BEFORE UPDATE ON vehicles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trip_reviews_updated_at 
    BEFORE UPDATE ON trip_reviews 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_support_tickets_updated_at 
    BEFORE UPDATE ON support_tickets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_faq_items_updated_at 
    BEFORE UPDATE ON faq_items 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_templates_updated_at 
    BEFORE UPDATE ON notification_templates 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update user credit balance
CREATE OR REPLACE FUNCTION update_user_credit_balance()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users 
    SET credit_balance = NEW.balance_after 
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update user credit balance
CREATE TRIGGER update_credit_balance_trigger 
    AFTER INSERT ON credit_transactions 
    FOR EACH ROW EXECUTE FUNCTION update_user_credit_balance();

-- Function to update user ratings
CREATE OR REPLACE FUNCTION update_user_ratings()
RETURNS TRIGGER AS $$
DECLARE
    avg_driver_rating DECIMAL(3,2);
    avg_passenger_rating DECIMAL(3,2);
    driver_trip_count INTEGER;
    passenger_trip_count INTEGER;
BEGIN
    -- Update driver rating
    SELECT 
        COALESCE(AVG(rating), 0),
        COUNT(*)
    INTO avg_driver_rating, driver_trip_count
    FROM trip_reviews tr
    JOIN trips t ON tr.trip_id = t.id
    WHERE t.driver_id = NEW.reviewee_id;
    
    -- Update passenger rating
    SELECT 
        COALESCE(AVG(rating), 0),
        COUNT(*)
    INTO avg_passenger_rating, passenger_trip_count
    FROM trip_reviews tr
    JOIN bookings b ON tr.booking_id = b.id
    WHERE b.passenger_id = NEW.reviewee_id;
    
    -- Update user record
    UPDATE users 
    SET 
        avg_rating_as_driver = avg_driver_rating,
        avg_rating_as_passenger = avg_passenger_rating,
        total_trips_as_driver = driver_trip_count,
        total_trips_as_passenger = passenger_trip_count
    WHERE id = NEW.reviewee_id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update user ratings
CREATE TRIGGER update_ratings_trigger 
    AFTER INSERT OR UPDATE ON trip_reviews 
    FOR EACH ROW EXECUTE FUNCTION update_user_ratings();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- View for active trips with driver information
CREATE VIEW active_trips_view AS
SELECT 
    t.id,
    t.origin_city,
    t.destination_city,
    t.departure_time,
    t.price_per_seat,
    t.available_seats,
    t.status,
    u.first_name AS driver_first_name,
    u.last_name AS driver_last_name,
    u.avg_rating_as_driver,
    u.total_trips_as_driver,
    v.make AS vehicle_make,
    v.model AS vehicle_model,
    v.color AS vehicle_color
FROM trips t
JOIN users u ON t.driver_id = u.id
LEFT JOIN vehicles v ON t.vehicle_id = v.id
WHERE t.status = 'active' 
    AND t.departure_time > CURRENT_TIMESTAMP
    AND t.available_seats > 0;

-- View for user booking history
CREATE VIEW user_booking_history AS
SELECT 
    b.id AS booking_id,
    b.passenger_id,
    b.status AS booking_status,
    b.total_price,
    b.created_at AS booking_date,
    t.origin_city,
    t.destination_city,
    t.departure_time,
    d.first_name AS driver_first_name,
    d.last_name AS driver_last_name,
    d.avg_rating_as_driver
FROM bookings b
JOIN trips t ON b.trip_id = t.id
JOIN users d ON t.driver_id = d.id;

-- View for driver trip history
CREATE VIEW driver_trip_history AS
SELECT 
    t.id AS trip_id,
    t.driver_id,
    t.origin_city,
    t.destination_city,
    t.departure_time,
    t.status,
    t.total_seats,
    t.available_seats,
    COUNT(b.id) AS total_bookings,
    SUM(b.total_price) AS total_earnings
FROM trips t
LEFT JOIN bookings b ON t.id = b.trip_id AND b.status = 'confirmed'
GROUP BY t.id, t.driver_id, t.origin_city, t.destination_city, 
         t.departure_time, t.status, t.total_seats, t.available_seats;

-- =============================================================================
-- INITIAL DATA SETUP
-- =============================================================================

-- Insert default admin roles
INSERT INTO admin_roles (role_name, description, permissions) VALUES
('super_admin', 'Full system access', '{"users": "full", "trips": "full", "payments": "full", "support": "full", "system": "full"}'),
('support_agent', 'Customer support access', '{"users": "read", "trips": "read", "support": "full", "payments": "read"}'),
('moderator', 'Content moderation access', '{"users": "moderate", "trips": "moderate", "reviews": "full"}');

-- Insert default FAQ categories
INSERT INTO faq_categories (name, description, display_order, language) VALUES
('Generelt', 'Generelle spørsmål om BlablaBil', 1, 'nb'),
('Booking', 'Spørsmål om booking av turer', 2, 'nb'),
('Betaling', 'Spørsmål om betaling og refundering', 3, 'nb'),
('Sikkerhet', 'Spørsmål om sikkerhet og verifisering', 4, 'nb'),
('General', 'General questions about BlablaBil', 1, 'en'),
('Booking', 'Questions about booking trips', 2, 'en'),
('Payment', 'Questions about payment and refunds', 3, 'en'),
('Safety', 'Questions about safety and verification', 4, 'en');

-- Insert default notification templates
INSERT INTO notification_templates (template_name, template_type, subject_template, body_template, language) VALUES
('booking_confirmation', 'email', 'Booking bekreftet - {trip_route}', 'Din booking fra {origin} til {destination} den {date} er bekreftet.', 'nb'),
('trip_reminder', 'sms', '', 'Påminnelse: Din tur fra {origin} til {destination} starter om {hours} timer.', 'nb'),
('payment_received', 'push', 'Betaling mottatt', 'Vi har mottatt din betaling på {amount} NOK.', 'nb'),
('booking_confirmation', 'email', 'Booking confirmed - {trip_route}', 'Your booking from {origin} to {destination} on {date} is confirmed.', 'en'),
('trip_reminder', 'sms', '', 'Reminder: Your trip from {origin} to {destination} starts in {hours} hours.', 'en'),
('payment_received', 'push', 'Payment received', 'We have received your payment of {amount} NOK.', 'en');

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON DATABASE blablabil_database IS 'BlablaBil Carpooling Platform Database - Norwegian carpooling service similar to BlaBlaCar';
=======

COMMENT ON TABLE users IS 'Core user information including personal data, verification status, and preferences';
COMMENT ON TABLE trips IS 'Trip postings by drivers with route, timing, and pricing information';
COMMENT ON TABLE bookings IS 'Passenger bookings for trips with payment and status tracking';
COMMENT ON TABLE payments IS 'Payment transactions supporting Vipps, cash, and credit payments';
COMMENT ON TABLE notifications IS 'System notifications sent via email, SMS, or push notifications';
COMMENT ON TABLE support_tickets IS 'Customer support tickets with message threading';
COMMENT ON TABLE system_logs IS 'Audit trail for system activities and changes';
COMMENT ON TABLE gdpr_data_logs IS 'GDPR compliance tracking for data processing requests';

-- =============================================================================
-- DATABASE OPTIMIZATION AND MAINTENANCE
-- =============================================================================

-- Set up automatic statistics collection
ALTER TABLE users SET (autovacuum_analyze_scale_factor = 0.02);
ALTER TABLE trips SET (autovacuum_analyze_scale_factor = 0.02);
ALTER TABLE bookings SET (autovacuum_analyze_scale_factor = 0.02);
ALTER TABLE payments SET (autovacuum_analyze_scale_factor = 0.02);

-- Enable row-level security (RLS) for enhanced security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (basic examples - would need refinement based on application logic)
CREATE POLICY users_own_data ON users 
    FOR ALL TO public 
    USING (id = current_setting('app.current_user_id')::uuid);

CREATE POLICY trips_public_read ON trips 
    FOR SELECT TO public 
    USING (status = 'active');

CREATE POLICY bookings_own_data ON bookings 
    FOR ALL TO public 
    USING (passenger_id = current_setting('app.current_user_id')::uuid 
           OR trip_id IN (SELECT id FROM trips WHERE driver_id = current_setting('app.current_user_id')::uuid));

-- =============================================================================
-- SCHEMA VERSIONING
-- =============================================================================

CREATE TABLE schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

INSERT INTO schema_migrations (version, description) VALUES 
('1.0.0', 'Initial BlablaBil database schema with all core functionality');

-- =============================================================================
-- SCHEMA COMPLETE
-- =============================================================================

-- Grant necessary permissions to application user
GRANT USAGE ON SCHEMA public TO appuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO appuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO appuser;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO appuser;

-- Success message
SELECT 'BlablaBil database schema created successfully!' AS status;
