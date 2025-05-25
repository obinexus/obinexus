#!/bin/bash
# OBINexus GDPR Database Updates Script
# This script applies necessary database changes for GDPR compliance
# across all OBINexus services

# Stop on any error
set -e

# Base directories
BASE_DIR="$HOME/projects/obinexus"
DB_DIR="$BASE_DIR/db"
SCRIPTS_DIR="$BASE_DIR/scripts"

# Database connection info
DB_HOST="db5017799522.hosting.data.io"
DB_USER="dbu5547458"
DB_PORT="3306"

# Timestamp for logging
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="$SCRIPTS_DIR/db-update-log-$(date +"%Y%m%d").log"

# Log function
log() {
    echo "[$TIMESTAMP] $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Create MySQL scripts for each database
create_db_scripts() {
    log "Creating database scripts for GDPR compliance..."
    
    # Central database - main tables and GDPR tracking
    cat > "$DB_DIR/central/gdpr_tables.sql" << EOF
-- Add GDPR-related fields to Users table if they don't exist
ALTER TABLE Users
ADD COLUMN IF NOT EXISTS data_deletion_processed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS data_deletion_completed_date TIMESTAMP NULL;

-- Create GDPR compliance log table
CREATE TABLE IF NOT EXISTS GDPRComplianceLog (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    action VARCHAR(50) NOT NULL,
    user_id INT,
    email VARCHAR(100),
    details TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (user_id),
    INDEX (action),
    INDEX (timestamp)
);

-- Create GDPR audit trail table
CREATE TABLE IF NOT EXISTS GDPRAuditTrail (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    timestamp TIMESTAMP NOT NULL,
    action VARCHAR(50) NOT NULL,
    user_id INT,
    details TEXT,
    processor_run_id VARCHAR(36) NOT NULL,
    INDEX (user_id),
    INDEX (action),
    INDEX (timestamp),
    INDEX (processor_run_id)
);

-- Data Access Requests table
CREATE TABLE IF NOT EXISTS DataAccessRequests (
    request_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fulfilled_date TIMESTAMP NULL,
    status ENUM('pending', 'processing', 'fulfilled', 'denied', 'error') DEFAULT 'pending',
    services VARCHAR(255) COMMENT 'Comma-separated list of services',
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    INDEX (status),
    INDEX (request_date)
);
EOF

    # Computing database - views for GDPR data access
    cat > "$DB_DIR/computing/gdpr_views.sql" << EOF
-- Create or replace the GDPR data view for Computing service
CREATE OR REPLACE VIEW ComputingUserData AS
SELECT 
    cp.project_id, cp.user_id, cp.title, cp.description, cp.type,
    cp.start_date, cp.end_date, cp.status, cp.outcome,
    cs.ticket_id, cs.subject, cs.description AS ticket_description,
    cs.created_at AS ticket_created, cs.resolved_at, cs.status AS ticket_status,
    cul.log_id, cul.activity_type, cul.timestamp AS activity_time
FROM ComputingProjects cp
LEFT JOIN ComputingSupport cs ON cp.user_id = cs.user_id
LEFT JOIN ComputingUsageLogs cul ON cp.user_id = cul.user_id;
EOF

    # Publishing database - views for GDPR data access
    cat > "$DB_DIR/publishing/gdpr_views.sql" << EOF
-- Create or replace the GDPR data view for Publishing service
CREATE OR REPLACE VIEW PublishingUserData AS
SELECT 
    p.publication_id, p.user_id, p.title, p.content, p.category, p.tags,
    p.publish_date, p.last_updated, p.status, p.access_level,
    pp.project_id, pp.title AS project_title, pp.description, pp.type AS project_type,
    pp.start_date, pp.end_date, pp.status AS project_status,
    ps.ticket_id, ps.subject, ps.description AS ticket_description
FROM Publications p
LEFT JOIN PublishingProjects pp ON p.user_id = pp.user_id
LEFT JOIN PublishingSupport ps ON p.user_id = ps.user_id;
EOF

    # Uchennamdi database - views for GDPR data access
    cat > "$DB_DIR/uchennamdi/gdpr_views.sql" << EOF
-- Create or replace the GDPR data view for Uchennamdi service
CREATE OR REPLACE VIEW UchennamdiUserData AS
SELECT 
    cd.user_id, cd.bust_cm, cd.waist_cm, cd.hip_cm, cd.height_cm, 
    cd.inseam_cm, cd.sleeve_length_cm, cd.color_preferences, cd.style_preferences,
    fo.order_id, fo.order_date, fo.total_amount, fo.status AS order_status,
    fp.project_id, fp.title, fp.description, fp.type AS project_type,
    fp.start_date, fp.end_date, fp.status AS project_status
FROM CustomerDetails cd
LEFT JOIN FashionOrders fo ON cd.user_id = fo.user_id
LEFT JOIN FashionProjects fp ON cd.user_id = fp.user_id;
EOF

    log "Database scripts created successfully."
}

# Apply database changes with interactive prompts
apply_db_changes() {
    log "Preparing to apply database changes..."
    
    # Prompt for database password
    echo "Enter the database password for user $DB_USER:"
    read -s DB_PASS
    echo ""
    
    # Function to run a SQL script on a database
    run_sql_script() {
        local db_name=$1
        local script_file=$2
        
        log "Applying changes to $db_name database..."
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -P "$DB_PORT" "$db_name" < "$script_file" 2>> "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            log "Changes applied successfully to $db_name database."
            return 0
        else
            log "Error applying changes to $db_name database. Check $LOG_FILE for details."
            return 1
        fi
    }
    
    # Central database
    echo "Do you want to apply changes to the obinexus_central database? (y/n)"
    read answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        run_sql_script "obinexus_central" "$DB_DIR/central/gdpr_tables.sql"
    else
        log "Skipping obinexus_central database updates."
    fi
    
    # Computing database
    echo "Do you want to apply changes to the obinexus_computing database? (y/n)"
    read answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        run_sql_script "obinexus_computing" "$DB_DIR/computing/gdpr_views.sql"
    else
        log "Skipping obinexus_computing database updates."
    fi
    
    # Publishing database
    echo "Do you want to apply changes to the obinexus_publishing database? (y/n)"
    read answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        run_sql_script "obinexus_publishing" "$DB_DIR/publishing/gdpr_views.sql"
    else
        log "Skipping obinexus_publishing database updates."
    fi
    
    # Uchennamdi database
    echo "Do you want to apply changes to the obinexus_uchennamdi database? (y/n)"
    read answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        run_sql_script "obinexus_uchennamdi" "$DB_DIR/uchennamdi/gdpr_views.sql"
    else
        log "Skipping obinexus_uchennamdi database updates."
    fi
    
    log "Database update process completed."
}

# Create a verification script
create_verification_script() {
    log "Creating database verification script..."
    
    cat > "$DB_DIR/verify_gdpr_setup.sql" << EOF
-- Verification queries for GDPR setup
-- Run this on each database to verify the setup

-- Central database verification
USE obinexus_central;
SHOW COLUMNS FROM Users LIKE 'data_deletion%';
SHOW TABLES LIKE 'GDPRCompliance%';
SHOW TABLES LIKE 'GDPRAudit%';
SHOW TABLES LIKE 'DataAccess%';

-- Computing database verification
USE obinexus_computing;
SHOW FULL TABLES WHERE Table_type = 'VIEW' AND Tables_in_obinexus_computing LIKE '%UserData%';

-- Publishing database verification
USE obinexus_publishing;
SHOW FULL TABLES WHERE Table_type = 'VIEW' AND Tables_in_obinexus_publishing LIKE '%UserData%';

-- Uchennamdi database verification
USE obinexus_uchennamdi;
SHOW FULL TABLES WHERE Table_type = 'VIEW' AND Tables_in_obinexus_uchennamdi LIKE '%UserData%';
EOF

    # Create a shell script to run the verification
    cat > "$SCRIPTS_DIR/verify-gdpr-db.sh" << EOF
#!/bin/bash
# Script to verify GDPR database setup

DB_HOST="db5017799522.hosting.data.io"
DB_USER="dbu5547458"
DB_PORT="3306"

echo "Enter the database password for user \$DB_USER:"
read -s DB_PASS
echo ""

echo "Running verification queries..."
mysql -h "\$DB_HOST" -u "\$DB_USER" -p"\$DB_PASS" -P "\$DB_PORT" < "$DB_DIR/verify_gdpr_setup.sql"

if [ \$? -eq 0 ]; then
    echo "Verification completed successfully."
else
    echo "Verification failed. Check database connection and permissions."
fi
EOF

    chmod +x "$SCRIPTS_DIR/verify-gdpr-db.sh"
    
    log "Verification script created successfully."
}

# Main execution
main() {
    # Create script directory for logging
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$DB_DIR/central"
    mkdir -p "$DB_DIR/computing"
    mkdir -p "$DB_DIR/publishing"
    mkdir -p "$DB_DIR/uchennamdi"
    
    log "Starting OBINexus GDPR Database Updates..."
    
    create_db_scripts
    create_verification_script
    
    echo ""
    echo "=========================================================="
    echo "OBINexus GDPR Database Scripts Created"
    echo ""
    echo "The following database scripts have been created:"
    echo "  - Central DB:      $DB_DIR/central/gdpr_tables.sql"
    echo "  - Computing DB:    $DB_DIR/computing/gdpr_views.sql"
    echo "  - Publishing DB:   $DB_DIR/publishing/gdpr_views.sql"
    echo "  - Uchennamdi DB:   $DB_DIR/uchennamdi/gdpr_views.sql"
    echo ""
    echo "Do you want to apply these changes to the databases now?"
    echo "  (This will require your database password)"
    echo ""
    echo "  1) Yes, apply changes now"
    echo "  2) No, I'll apply them manually later"
    echo ""
    echo -n "Enter your choice (1 or 2): "
    read choice
    
    if [[ "$choice" == "1" ]]; then
        apply_db_changes
        echo ""
        echo "Database changes have been applied."
        echo "To verify the changes, run: $SCRIPTS_DIR/verify-gdpr-db.sh"
    else
        echo ""
        echo "You can apply the changes manually later using:"
        echo "  mysql -h $DB_HOST -u $DB_USER -p -P $DB_PORT obinexus_central < $DB_DIR/central/gdpr_tables.sql"
        echo "  mysql -h $DB_HOST -u $DB_USER -p -P $DB_PORT obinexus_computing < $DB_DIR/computing/gdpr_views.sql"
        echo "  mysql -h $DB_HOST -u $DB_USER -p -P $DB_PORT obinexus_publishing < $DB_DIR/publishing/gdpr_views.sql"
        echo "  mysql -h $DB_HOST -u $DB_USER -p -P $DB_PORT obinexus_uchennamdi < $DB_DIR/uchennamdi/gdpr_views.sql"
    fi
    
    echo ""
    echo "Log file: $LOG_FILE"
    echo "=========================================================="
}

# Execute main function
main
