#!/bin/bash
# OBINexus GDPR Test Data Creation Script
# This script creates sample data for testing the GDPR processor

# Stop on any error
set -e

# Base directories
BASE_DIR="$HOME/projects/obinexus"
SCRIPTS_DIR="$BASE_DIR/scripts"
DB_DIR="$BASE_DIR/db"

# Timestamp for logging
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="$SCRIPTS_DIR/test-data-log-$(date +"%Y%m%d").log"

# Log function
log() {
    echo "[$TIMESTAMP] $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Create test data script for central database
create_central_test_data() {
    log "Creating test data for central database..."
    
    cat > "$DB_DIR/central/test_data.sql" << EOF
-- Insert test users
INSERT INTO Users (username, email, first_name, last_name, country, gdpr_consent, gdpr_consent_date, marketing_consent)
VALUES 
('test_user1', 'test1@example.com', 'John', 'Doe', 'UK', TRUE, NOW(), TRUE),
('test_user2', 'test2@example.com', 'Jane', 'Smith', 'Germany', TRUE, NOW(), FALSE),
('test_user3', 'test3@example.com', 'Alice', 'Johnson', 'France', TRUE, NOW(), TRUE);

-- Get the inserted user IDs
SET @user1_id = LAST_INSERT_ID();
SET @user2_id = @user1_id + 1;
SET @user3_id = @user1_id + 2;

-- Insert partnership tiers if not exists
INSERT IGNORE INTO PartnershipTiers (tier_name, tier_type, description, level, focus_area)
VALUES
('Knowledge King Tier 1', 'uche_eze', 'Partnership focused on knowledge projects - level 1', 1, 'project'),
('Heart King Tier 1', 'obi_eze', 'Partnership focused on operational change - level 1', 1, 'operation');

-- Get the tier IDs
SELECT @kk_tier_id := tier_id FROM PartnershipTiers WHERE tier_name = 'Knowledge King Tier 1' LIMIT 1;
SELECT @hk_tier_id := tier_id FROM PartnershipTiers WHERE tier_name = 'Heart King Tier 1' LIMIT 1;

-- Insert licenses
INSERT INTO Licenses (user_id, service, tier, partnership_tier_id, start_date, expiry_date, active)
VALUES
(@user1_id, 'computing', 'community', NULL, NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR), TRUE),
(@user2_id, 'publishing', 'partnership', @kk_tier_id, NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR), TRUE),
(@user3_id, 'uchennamdi', 'partnership', @hk_tier_id, NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR), TRUE);

-- Create GDPR deletion requests
-- User 1: Request made 28 days ago (urgent)
-- User 2: Request made 15 days ago (high priority)
-- User 3: Request made 5 days ago (normal priority)
UPDATE Users 
SET data_deletion_requested = TRUE,
    data_deletion_date = DATE_SUB(NOW(), INTERVAL 28 DAY)
WHERE user_id = @user1_id;

UPDATE Users 
SET data_deletion_requested = TRUE,
    data_deletion_date = DATE_SUB(NOW(), INTERVAL 15 DAY)
WHERE user_id = @user2_id;

UPDATE Users 
SET data_deletion_requested = TRUE,
    data_deletion_date = DATE_SUB(NOW(), INTERVAL 5 DAY)
WHERE user_id = @user3_id;

-- Insert data access requests
INSERT INTO DataAccessRequests (user_id, request_date, status, services)
VALUES
(@user1_id, DATE_SUB(NOW(), INTERVAL 25 DAY), 'pending', 'all'),
(@user2_id, DATE_SUB(NOW(), INTERVAL 10 DAY), 'pending', 'publishing'),
(@user3_id, DATE_SUB(NOW(), INTERVAL 2 DAY), 'pending', 'uchennamdi,computing');
EOF

    log "Test data for central database created successfully."
}

# Create test data script for computing database
create_computing_test_data() {
    log "Creating test data for computing database..."
    
    cat > "$DB_DIR/computing/test_data.sql" << EOF
-- Insert test computing tools
INSERT INTO ComputingTools (tool_name, description, version, release_date)
VALUES
('OBINexus Analyzer', 'Data analysis tool', '1.0.2', NOW()),
('OBINexus Predictor', 'Prediction algorithm tool', '2.1.0', NOW());

-- Get the tool IDs
SET @tool1_id = LAST_INSERT_ID();
SET @tool2_id = @tool1_id + 1;

-- Insert computing projects
INSERT INTO ComputingProjects (user_id, title, description, type, tier_level, start_date, status)
VALUES
(1, 'Data Analysis Project', 'Comprehensive data analysis project', 'project', 'community', NOW(), 'active'),
(2, 'Prediction Model', 'Economic prediction model development', 'project', 'partnership', NOW(), 'planning'),
(3, 'System Optimization', 'IT system optimization operation', 'operation', 'partnership', NOW(), 'active');

-- Insert computing usage logs
INSERT INTO ComputingUsageLogs (user_id, tool_id, activity_type, timestamp, ip_address, session_id)
VALUES
(1, @tool1_id, 'login', DATE_SUB(NOW(), INTERVAL 10 DAY), '192.168.1.1', 'sess_123456'),
(1, @tool1_id, 'analysis', DATE_SUB(NOW(), INTERVAL 10 DAY), '192.168.1.1', 'sess_123456'),
(2, @tool2_id, 'login', DATE_SUB(NOW(), INTERVAL 5 DAY), '192.168.1.2', 'sess_789012'),
(3, @tool1_id, 'login', DATE_SUB(NOW(), INTERVAL 2 DAY), '192.168.1.3', 'sess_345678');

-- Insert support tickets
INSERT INTO ComputingSupport (user_id, tier_level, subject, description, created_at, status)
VALUES
(1, 'community', 'Issue with analysis tool', 'Cannot run complex analysis', DATE_SUB(NOW(), INTERVAL 15 DAY), 'in-progress'),
(2, 'partnership', 'Feature request', 'Need additional prediction algorithms', DATE_SUB(NOW(), INTERVAL 7 DAY), 'new'),
(3, 'partnership', 'System access', 'Cannot access optimization tool', DATE_SUB(NOW(), INTERVAL 3 DAY), 'resolved');
EOF

    log "Test data for computing database created successfully."
}

# Create test data script for publishing database
create_publishing_test_data() {
    log "Creating test data for publishing database..."
    
    cat > "$DB_DIR/publishing/test_data.sql" << EOF
-- Insert publications
INSERT INTO Publications (user_id, title, content, category, tags, status, access_level)
VALUES
(1, 'Introduction to OBINexus', 'Content about OBINexus platform...', 'Technology', 'intro,tech,platform', 'published', 'public'),
(2, 'Advanced OBINexus Techniques', 'Content about advanced techniques...', 'Technology', 'advanced,techniques', 'published', 'tier2'),
(3, 'OBINexus for Businesses', 'Content about business applications...', 'Business', 'business,enterprise', 'draft', 'tier1');

-- Get publication IDs
SET @pub1_id = LAST_INSERT_ID();
SET @pub2_id = @pub1_id + 1;
SET @pub3_id = @pub1_id + 2;

-- Insert content metrics
INSERT INTO ContentMetrics (publication_id, views, likes, shares, comments)
VALUES
(@pub1_id, 1250, 45, 12, 8),
(@pub2_id, 350, 22, 5, 3),
(@pub3_id, 0, 0, 0, 0);

-- Insert publishing projects
INSERT INTO PublishingProjects (user_id, title, description, type, tier_level, start_date, status)
VALUES
(1, 'Blog Series', 'Series of blog posts about technology', 'project', 'community', NOW(), 'active'),
(2, 'Technical Documentation', 'Comprehensive technical documentation', 'project', 'partnership', NOW(), 'active'),
(3, 'Business Guide', 'Guide for business implementations', 'operation', 'partnership', NOW(), 'planning');

-- Insert support tickets
INSERT INTO PublishingSupport (user_id, tier_level, subject, description, created_at, status)
VALUES
(1, 'community', 'Publishing issue', 'Cannot publish new content', DATE_SUB(NOW(), INTERVAL 12 DAY), 'resolved'),
(2, 'partnership', 'Access control', 'Need to change access levels', DATE_SUB(NOW(), INTERVAL 6 DAY), 'in-progress'),
(3, 'partnership', 'Draft recovery', 'Lost draft of business guide', DATE_SUB(NOW(), INTERVAL 2 DAY), 'new');
EOF

    log "Test data for publishing database created successfully."
}

# Create test data script for uchennamdi database
create_uchennamdi_test_data() {
    log "Creating test data for uchennamdi database..."
    
    cat > "$DB_DIR/uchennamdi/test_data.sql" << EOF
-- Insert fashion products
INSERT INTO FashionProducts (product_name, description, category, price, stock)
VALUES
('Classic T-Shirt', 'Premium cotton t-shirt', 'Clothing', 29.99, 100),
('Designer Jeans', 'High-quality designer jeans', 'Clothing', 89.99, 50),
('Leather Bag', 'Handcrafted leather bag', 'Accessories', 129.99, 25);

-- Get product IDs
SET @prod1_id = LAST_INSERT_ID();
SET @prod2_id = @prod1_id + 1;
SET @prod3_id = @prod1_id + 2;

-- Insert customer details
INSERT INTO CustomerDetails (user_id, bust_cm, waist_cm, hip_cm, height_cm, inseam_cm, sleeve_length_cm, color_preferences, style_preferences)
VALUES
(1, 92.5, 76.2, 97.8, 175.3, 81.2, 63.5, 'blue,green,black', 'casual,minimalist'),
(2, 88.9, 72.4, 94.0, 168.2, 78.7, 61.0, 'red,purple,black', 'bohemian,vintage'),
(3, 95.3, 79.5, 101.6, 180.3, 83.8, 65.2, 'earth tones,white', 'professional,classic');

-- Insert fashion orders
INSERT INTO FashionOrders (user_id, order_date, total_amount, status, shipping_address, payment_method)
VALUES
(1, DATE_SUB(NOW(), INTERVAL 20 DAY), 59.98, 'delivered', '123 Main St, London, UK', 'credit_card'),
(2, DATE_SUB(NOW(), INTERVAL 10 DAY), 219.97, 'shipped', '456 High St, Berlin, Germany', 'paypal'),
(3, DATE_SUB(NOW(), INTERVAL 5 DAY), 129.99, 'processing', '789 Rue de Paris, Paris, France', 'credit_card');

-- Get order IDs
SET @order1_id = LAST_INSERT_ID();
SET @order2_id = @order1_id + 1;
SET @order3_id = @order1_id + 2;

-- Insert order items
INSERT INTO OrderItems (order_id, product_id, quantity, price_per_unit)
VALUES
(@order1_id, @prod1_id, 2, 29.99),
(@order2_id, @prod1_id, 1, 29.99),
(@order2_id, @prod2_id, 1, 89.99),
(@order2_id, @prod3_id, 1, 129.99),
(@order3_id, @prod3_id, 1, 129.99);

-- Insert fashion projects
INSERT INTO FashionProjects (user_id, title, description, type, tier_level, start_date, status)
VALUES
(1, 'Custom T-Shirt Design', 'Creating custom-designed t-shirts', 'project', 'community', NOW(), 'planning'),
(2, 'Fashion Catalog', 'Development of seasonal fashion catalog', 'project', 'partnership', NOW(), 'active'),
(3, 'Retail Integration', 'Integrating systems with retail partners', 'operation', 'partnership', NOW(), 'active');
EOF

    log "Test data for uchennamdi database created successfully."
}

# Function to apply test data to databases
apply_test_data() {
    log "Preparing to apply test data to databases..."
    
    # Prompt for database password
    echo "Enter the database password for user dbu5547458:"
    read -s DB_PASS
    echo ""
    
    # Function to run a SQL script on a database
    run_sql_script() {
        local db_name=$1
        local script_file=$2
        
        log "Applying test data to $db_name database..."
        mysql -h "db5017799522.hosting.data.io" -u "dbu5547458" -p"$DB_PASS" -P "3306" "$db_name" < "$script_file" 2>> "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            log "Test data applied successfully to $db_name database."
            return 0
        else
            log "Error applying test data to $db_name database. Check $LOG_FILE for details."
            return 1
        fi
    }
    
    # Apply test data to each database
    run_sql_script "obinexus_central" "$DB_DIR/central/test_data.sql"
    run_sql_script "obinexus_computing" "$DB_DIR/computing/test_data.sql"
    run_sql_script "obinexus_publishing" "$DB_DIR/publishing/test_data.sql"
    run_sql_script "obinexus_uchennamdi" "$DB_DIR/uchennamdi/test_data.sql"
    
    log "Test data applied successfully to all databases."
}

# Main execution
main() {
    # Create script directory for logging
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$DB_DIR/central"
    mkdir -p "$DB_DIR/computing"
    mkdir -p "$DB_DIR/publishing"
    mkdir -p "$DB_DIR/uchennamdi"
    
    log "Starting OBINexus GDPR Test Data Creation..."
    
    create_central_test_data
    create_computing_test_data
    create_publishing_test_data
    create_uchennamdi_test_data
    
    echo ""
    echo "=========================================================="
    echo "OBINexus GDPR Test Data Created"
    echo ""
    echo "The following test data scripts have been created:"
    echo "  - Central DB:      $DB_DIR/central/test_data.sql"
    echo "  - Computing DB:    $DB_DIR/computing/test_data.sql"
    echo "  - Publishing DB:   $DB_DIR/publishing/test_data.sql"
    echo "  - Uchennamdi DB:   $DB_DIR/uchennamdi/test_data.sql"
    echo ""
    echo "This data includes:"
    echo "  - 3 test users with different GDPR deletion request dates"
    echo "  - Data access requests with different timeframes"
    echo "  - Sample data across all services"
    echo ""
    echo "Do you want to apply this test data to the databases now?"
    echo "  (This will require your database password)"
    echo ""
    echo "  1) Yes, apply test data now"
    echo "  2) No, I'll apply it manually later"
    echo ""
    echo -n "Enter your choice (1 or 2): "
    read choice
    
    if [[ "$choice" == "1" ]]; then
        apply_test_data
        echo ""
        echo "Test data has been applied to all databases."
        echo "You can now run the GDPR processor to test the functionality:"
        echo "  $SCRIPTS_DIR/cron/test-gdpr-processor.sh"
    else
        echo ""
        echo "You can apply the test data manually later using:"
        echo "  mysql -h db5017799522.hosting.data.io -u dbu5547458 -p -P 3306 obinexus_central < $DB_DIR/central/test_data.sql"
        echo "  mysql -h db5017799522.hosting.data.io -u dbu5547458 -p -P 3306 obinexus_computing < $DB_DIR/computing/test_data.sql"
        echo "  mysql -h db5017799522.hosting.data.io -u dbu5547458 -p -P 3306 obinexus_publishing < $DB_DIR/publishing/test_data.sql"
        echo "  mysql -h db5017799522.hosting.data.io -u dbu5547458 -p -P 3306 obinexus_uchennamdi < $DB_DIR/uchennamdi/test_data.sql"
    fi
    
    echo ""
    echo "Log file: $LOG_FILE"
    echo "=========================================================="
}

# Execute main function
main
