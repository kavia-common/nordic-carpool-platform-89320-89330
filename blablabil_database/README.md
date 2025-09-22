# BlablaBil Database

This directory contains the PostgreSQL database setup and schema for the BlablaBil carpooling platform.

## Database Overview

The `blablabil_database` is a comprehensive PostgreSQL database designed to support a full-featured carpooling platform similar to BlaBlaCar, specifically tailored for the Norwegian market.

## Quick Start

1. **Start the database:**
   ```bash
   ./startup.sh
   ```

2. **Initialize the schema:**
   ```bash
   ./init_schema.sh
   ```

3. **Connect to the database:**
   ```bash
   psql postgresql://appuser:dbuser123@localhost:5000/blablabil_database
   ```

## Database Configuration

- **Database Name:** `blablabil_database`
- **User:** `appuser`
- **Password:** `dbuser123`
- **Port:** `5000`
- **Host:** `localhost`

## Schema Features

### Core Functionality

#### 1. Users and Authentication
- **users**: Core user profiles with Norwegian ID verification
- **user_sessions**: Session management for authentication
- **password_reset_tokens**: Secure password reset functionality

#### 2. Trips and Bookings
- **trips**: Driver trip postings with route and pricing
- **trip_waypoints**: Intermediate stops for trips
- **bookings**: Passenger booking management
- **vehicles**: User vehicle information

#### 3. Payment System
- **payments**: Transaction processing (Vipps, cash, credit)
- **credit_transactions**: Credit-based payment system
- **subscriptions**: Premium subscription management

#### 4. Ratings and Reviews
- **trip_reviews**: Trip ratings and feedback system

#### 5. Notifications
- **notifications**: Multi-channel notification system
- **notification_templates**: Localized notification templates

#### 6. Support System
- **support_tickets**: Customer support ticket system
- **support_ticket_messages**: Threaded support conversations
- **faq_categories** & **faq_items**: Multilingual FAQ system

#### 7. Administration
- **admin_roles** & **admin_users**: Role-based admin access
- **system_logs**: Comprehensive audit trail
- **user_activity_logs**: User activity tracking

#### 8. GDPR Compliance
- **gdpr_data_logs**: Data processing request tracking
- Row-level security policies
- Data retention and anonymization support

### Key Features

#### Norwegian Market Specific
- Norwegian phone number format validation
- Norwegian national ID (11-digit) support
- Multi-language support (Norwegian Bokmål, Nynorsk, English)
- Vipps payment integration support

#### Payment Methods
- Vipps (Norwegian mobile payment)
- Cash payments
- Credit-based payments
- Bank transfers

#### Security & Compliance
- UUID primary keys for enhanced security
- Password hashing support
- Session management
- GDPR compliance features
- Row-level security policies
- Comprehensive audit logging

#### Performance Optimization
- Strategic indexes for common queries
- Optimized views for frequent operations
- Automatic statistics collection
- Trigger-based data consistency

## Database Scripts

### Core Scripts
- `startup.sh` - Starts PostgreSQL and creates the database
- `init_schema.sh` - Applies the database schema
- `schema.sql` - Complete database schema definition

### Maintenance Scripts
- `backup_db.sh` - Creates database backups
- `restore_db.sh` - Restores database from backups

### Monitoring
- `db_visualizer/` - Web-based database viewer
- Navigate to the database visualizer URL to browse tables and data

## Schema Details

### Main Tables

#### Users Table
Stores comprehensive user information including:
- Personal details and contact information
- Norwegian ID verification status
- Driver license information
- Rating and reputation data
- Subscription and credit information
- GDPR consent tracking

#### Trips Table
Manages trip postings with:
- Route information (origin/destination)
- Timing and availability
- Pricing and seat management
- Trip preferences and restrictions
- Status tracking

#### Bookings Table
Handles passenger bookings including:
- Seat reservations
- Pickup/dropoff locations
- Payment status
- Booking lifecycle management

#### Payments Table
Comprehensive payment processing:
- Multiple payment methods
- Transaction status tracking
- External payment service integration
- Refund management

### Views and Functions

#### Performance Views
- `active_trips_view` - Currently available trips with driver info
- `user_booking_history` - User's booking history
- `driver_trip_history` - Driver's trip statistics

#### Automated Functions
- Automatic timestamp updates
- Credit balance maintenance
- User rating calculations
- Data consistency triggers

### Indexes

Strategic indexes are created for:
- User lookups (email, phone, Norwegian ID)
- Trip searches (route, time, status)
- Booking queries
- Payment tracking
- Notification delivery
- Support ticket management

## Environment Variables

The following environment variables are used:
- `POSTGRES_URL` - Full connection URL
- `POSTGRES_USER` - Database user
- `POSTGRES_PASSWORD` - Database password
- `POSTGRES_DB` - Database name
- `POSTGRES_PORT` - Database port

## GDPR Compliance

The schema includes comprehensive GDPR compliance features:

### Data Processing Tracking
- All data processing activities are logged
- Consent management for marketing and data processing
- Data retention period tracking

### User Rights Support
- Data export functionality
- Data anonymization capabilities
- Account deletion with proper data handling

### Privacy by Design
- Minimal data collection principles
- Purpose-specific data storage
- Secure data handling practices

## Backup and Recovery

### Automated Backups
Use the provided backup script:
```bash
./backup_db.sh
```

This creates backups in the appropriate format (SQL dump for PostgreSQL).

### Recovery
To restore from backup:
```bash
./restore_db.sh
```

### Manual Operations
```bash
# Manual backup
pg_dump -h localhost -p 5000 -U appuser -d blablabil_database > backup.sql

# Manual restore
psql -h localhost -p 5000 -U appuser -d blablabil_database < backup.sql
```

## Development Notes

### Schema Versioning
The schema includes a `schema_migrations` table to track version changes:
- Current version: 1.0.0
- Supports future migration tracking

### Data Consistency
Triggers ensure:
- Automatic timestamp updates
- Credit balance synchronization
- User rating calculations
- Related data integrity

### Performance Considerations
- Appropriate indexes for common queries
- Optimized for Norwegian text sorting
- Prepared for geographic data (PostGIS ready)
- Scalable design for multi-country expansion

## Troubleshooting

### Common Issues

1. **Database won't start**
   - Check if port 5000 is available
   - Verify PostgreSQL installation
   - Check disk space

2. **Schema application fails**
   - Ensure database is running
   - Check user permissions
   - Verify schema.sql syntax

3. **Connection issues**
   - Verify connection string in db_connection.txt
   - Check firewall settings
   - Ensure user has proper permissions

### Logs and Monitoring
- Check PostgreSQL logs for detailed error information
- Use the db_visualizer for visual database inspection
- Monitor system_logs table for application-level issues

## Future Enhancements

The schema is designed to support future features:
- Geographic/mapping integrations (PostGIS ready)
- Multi-country expansion
- Advanced analytics and reporting
- Mobile app specific features
- Integration with external services

## Contact

For database-related issues or questions, refer to the BlablaBil development team documentation or create a support ticket through the application.
