#!/bin/bash
# OBINexus GDPR Implementation Script
# This script reorganizes the directory structure and sets up GDPR components
# for the non-monolithic OBINexus system.

# Stop on any error
set -e

# Base directories
BASE_DIR="$HOME/projects/obinexus"
WWW_DIR="$BASE_DIR/www"
SCRIPTS_DIR="$BASE_DIR/scripts"
DATA_DIR="$BASE_DIR/data"
DB_DIR="$BASE_DIR/db"

# Timestamp for logging
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="$SCRIPTS_DIR/setup-log-$(date +"%Y%m%d").log"

# Log function
log() {
    echo "[$TIMESTAMP] $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Create directory structure if it doesn't exist
create_directories() {
    log "Creating directory structure..."
    
    # Create main directories
    mkdir -p "$SCRIPTS_DIR/cron/logs"
    mkdir -p "$SCRIPTS_DIR/shared/mailer"
    mkdir -p "$DATA_DIR/exports"
    
    # Create web directories
    mkdir -p "$WWW_DIR/obinexus.org/config"
    mkdir -p "$WWW_DIR/obinexus.org/includes"
    mkdir -p "$WWW_DIR/obinexus.org/public"
    mkdir -p "$WWW_DIR/obinexus.org/admin"
    
    # Create database directories
    mkdir -p "$DB_DIR/central"
    mkdir -p "$DB_DIR/computing"
    mkdir -p "$DB_DIR/publishing"
    mkdir -p "$DB_DIR/uchennamdi"
    
    log "Directory structure created successfully."
}

# Move GDPR files to their appropriate locations
move_gdpr_files() {
    log "Moving GDPR files to appropriate locations..."
    
    # Check if files exist in root directory
    if [ -f "$WWW_DIR/gdpr.php" ]; then
        log "Moving gdpr.php to public directory..."
        mv "$WWW_DIR/gdpr.php" "$WWW_DIR/obinexus.org/public/gdpr.php"
    elif [ -f "$WWW_DIR/obinexus.org/gdpr.php" ]; then
        log "Moving gdpr.php from obinexus.org to public directory..."
        mv "$WWW_DIR/obinexus.org/gdpr.php" "$WWW_DIR/obinexus.org/public/gdpr.php"
    else
        log "Warning: gdpr.php not found. Skipping..."
    fi
    
    if [ -f "$WWW_DIR/gdpr-admin.php" ]; then
        log "Moving gdpr-admin.php to admin directory..."
        mv "$WWW_DIR/gdpr-admin.php" "$WWW_DIR/obinexus.org/admin/gdpr-admin.php"
    elif [ -f "$WWW_DIR/obinexus.org/gdpr-admin.php" ]; then
        log "Moving gdpr-admin.php from obinexus.org to admin directory..."
        mv "$WWW_DIR/obinexus.org/gdpr-admin.php" "$WWW_DIR/obinexus.org/admin/gdpr-admin.php"
    else
        log "Warning: gdpr-admin.php not found. Skipping..."
    fi
    
    if [ -f "$WWW_DIR/gdpr-processor.php" ]; then
        log "Moving gdpr-processor.php to cron directory..."
        mv "$WWW_DIR/gdpr-processor.php" "$SCRIPTS_DIR/cron/gdpr-processor.php"
    elif [ -f "$WWW_DIR/obinexus.org/gdpr-processor.php" ]; then
        log "Moving gdpr-processor.php from obinexus.org to cron directory..."
        mv "$WWW_DIR/obinexus.org/gdpr-processor.php" "$SCRIPTS_DIR/cron/gdpr-processor.php"
    else
        log "Warning: gdpr-processor.php not found. Skipping..."
    fi
    
    log "GDPR files moved successfully."
}

# Update file paths in GDPR processor
update_file_paths() {
    log "Updating file paths in GDPR processor..."
    
    PROCESSOR_FILE="$SCRIPTS_DIR/cron/gdpr-processor.php"
    
    if [ -f "$PROCESSOR_FILE" ]; then
        # Create backup
        cp "$PROCESSOR_FILE" "${PROCESSOR_FILE}.bak"
        
        # Update require_once paths if needed
        if grep -q "require_once __DIR__ . '/../../www/obinexus.org/config/database.php'" "$PROCESSOR_FILE"; then
            log "Paths are already correct. No changes needed."
        else
            log "Updating paths in gdpr-processor.php..."
            
            # Create a temporary file with the updated paths
            cat "$PROCESSOR_FILE" | sed 's|require_once .*database.php|require_once __DIR__ . "/../../www/obinexus.org/config/database.php"|g' \
                | sed 's|require_once .*logger.php|require_once __DIR__ . "/../../www/obinexus.org/includes/logger.php"|g' \
                | sed 's|require_once .*mailer.php|require_once __DIR__ . "/../../www/obinexus.org/includes/mailer.php"|g' > "${PROCESSOR_FILE}.tmp"
            
            # Replace the original file with the modified one
            mv "${PROCESSOR_FILE}.tmp" "$PROCESSOR_FILE"
            log "Paths updated successfully."
        fi
    else
        log "Error: gdpr-processor.php not found at $PROCESSOR_FILE."
    fi
}

# Create MySQL alter scripts for GDPR fields
create_db_scripts() {
    log "Creating database alter scripts..."
    
    # Central database alter script
    cat > "$DB_DIR/central/gdpr_fields.sql" << EOF
-- Add GDPR-related fields to Users table
ALTER TABLE Users
ADD COLUMN IF NOT EXISTS data_deletion_processed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS data_deletion_completed_date TIMESTAMP NULL;

-- Create compliance log table if it doesn't exist
CREATE TABLE IF NOT EXISTS GDPRComplianceLog (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    action VARCHAR(50) NOT NULL,
    user_id INT,
    email VARCHAR(100),
    details TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create audit trail table if it doesn't exist
CREATE TABLE IF NOT EXISTS GDPRAuditTrail (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    timestamp TIMESTAMP NOT NULL,
    action VARCHAR(50) NOT NULL,
    user_id INT,
    details TEXT,
    processor_run_id VARCHAR(36) NOT NULL
);
EOF
    
    log "Database scripts created successfully."
}

# Set permissions
set_permissions() {
    log "Setting file permissions..."
    
    # Set executable permission for the GDPR processor
    chmod 700 "$SCRIPTS_DIR/cron/gdpr-processor.php"
    
    # Set directory permissions
    chmod 755 "$SCRIPTS_DIR/cron"
    chmod 755 "$SCRIPTS_DIR/cron/logs"
    
    # Set restricted permissions for exports directory (contains sensitive data)
    chmod 700 "$DATA_DIR/exports"
    
    log "Permissions set successfully."
}

# Set up cron job
setup_cron_job() {
    log "Setting up GDPR cron job..."
    
    # Remove any existing GDPR processor cron jobs
    (crontab -l 2>/dev/null | grep -v "gdpr-processor.php") > /tmp/crontab.tmp
    
    # Add the new GDPR processor cron job (runs daily at 2:00 AM)
    echo "0 2 * * * php $SCRIPTS_DIR/cron/gdpr-processor.php > $SCRIPTS_DIR/cron/logs/gdpr-processor-\$(date +\%Y\%m\%d).log 2>&1" >> /tmp/crontab.tmp
    
    # Install the new crontab
    crontab /tmp/crontab.tmp
    rm /tmp/crontab.tmp
    
    log "Cron job set up successfully."
}

# Create a sample database configuration file
create_config_files() {
    log "Creating sample configuration files..."
    
    cat > "$WWW_DIR/obinexus.org/config/database.php" << EOF
<?php
/**
 * OBINexus Distributed Database Configuration
 * 
 * This file contains database connection information for all services
 */

// Central database connection
\$central_db = [
    'host' => 'db5017799522.hosting.data.io',
    'username' => 'dbu5547458',
    'password' => 'your_password',  // Replace with actual password in production
    'dbname' => 'obinexus_central',
    'port' => 3306
];

// Service-specific database connections
\$computing_db = [
    'host' => 'db5017799522.hosting.data.io',
    'username' => 'dbu5547458',
    'password' => 'your_password',  // Replace with actual password in production
    'dbname' => 'obinexus_computing',
    'port' => 3306
];

\$uchennamdi_db = [
    'host' => 'db5017799522.hosting.data.io',
    'username' => 'dbu5547458',
    'password' => 'your_password',  // Replace with actual password in production
    'dbname' => 'obinexus_uchennamdi',
    'port' => 3306
];

\$publishing_db = [
    'host' => 'db5017799522.hosting.data.io',
    'username' => 'dbu5547458',
    'password' => 'your_password',  // Replace with actual password in production
    'dbname' => 'obinexus_publishing',
    'port' => 3306
];

/**
 * Connect to a database
 * 
 * @param array \$db_config Database configuration
 * @return PDO|null Connection object or null on failure
 */
function connect_to_db(\$db_config) {
    try {
        \$conn = new PDO(
            "mysql:host={\$db_config['host']};dbname={\$db_config['dbname']};port={\$db_config['port']}", 
            \$db_config['username'], 
            \$db_config['password']
        );
        \$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return \$conn;
    } catch(PDOException \$e) {
        error_log("Connection failed: " . \$e->getMessage());
        return null;
    }
}
EOF

    # Create sample logger.php
    cat > "$WWW_DIR/obinexus.org/includes/logger.php" << EOF
<?php
/**
 * Simple logging class for OBINexus
 */
class Logger {
    private \$logName;
    private \$logDir;
    
    public function __construct(\$name) {
        \$this->logName = \$name;
        \$this->logDir = __DIR__ . '/../../logs';
        
        // Create log directory if it doesn't exist
        if (!is_dir(\$this->logDir)) {
            mkdir(\$this->logDir, 0755, true);
        }
    }
    
    public function info(\$message) {
        \$this->writeLog('INFO', \$message);
    }
    
    public function error(\$message) {
        \$this->writeLog('ERROR', \$message);
    }
    
    public function warning(\$message) {
        \$this->writeLog('WARNING', \$message);
    }
    
    private function writeLog(\$level, \$message) {
        \$date = date('Y-m-d H:i:s');
        \$logFile = \$this->logDir . '/' . \$this->logName . '-' . date('Y-m-d') . '.log';
        \$logMessage = "[\$date] [\$level] \$message\n";
        
        file_put_contents(\$logFile, \$logMessage, FILE_APPEND);
    }
}
EOF

    # Create sample mailer.php
    cat > "$WWW_DIR/obinexus.org/includes/mailer.php" << EOF
<?php
/**
 * Mailer class for OBINexus
 */
class Mailer {
    private \$adminEmail = 'admin@obinexus.org';
    private \$fromEmail = 'gdpr@obinexus.org';
    
    /**
     * Send data export notification to user
     */
    public function sendDataExportNotification(\$userEmail, \$requestId, \$filePath) {
        \$subject = 'Your OBINexus Data Export';
        \$message = "Your requested data export (ID: \$requestId) is now available. ";
        \$message .= "You can download your data from your GDPR dashboard.";
        
        \$this->sendEmail(\$userEmail, \$subject, \$message);
    }
    
    /**
     * Send deletion confirmation to user
     */
    public function sendDeletionConfirmation(\$userEmail) {
        \$subject = 'OBINexus Account Deletion Confirmation';
        \$message = "Your account and related data have been deleted from our systems. ";
        \$message .= "Thank you for using OBINexus.";
        
        \$this->sendEmail(\$userEmail, \$subject, \$message);
    }
    
    /**
     * Send admin alert
     */
    public function sendAdminAlert(\$subject, \$message) {
        \$this->sendEmail(\$this->adminEmail, \$subject, \$message);
    }
    
    /**
     * Send email
     */
    private function sendEmail(\$to, \$subject, \$message) {
        \$headers = "From: \$this->fromEmail\r\n";
        \$headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
        
        // In production, replace with proper email sending
        // For now, just log the email
        \$logger = new Logger('mailer');
        \$logger->info("Email to: \$to, Subject: \$subject, Message: \$message");
        
        // Uncomment in production
        // mail(\$to, \$subject, \$message, \$headers);
    }
}
EOF

    log "Configuration files created successfully."
}

# Create a test script for the GDPR processor
create_test_script() {
    log "Creating test script for GDPR processor..."
    
    cat > "$SCRIPTS_DIR/cron/test-gdpr-processor.sh" << EOF
#!/bin/bash
# Test script for GDPR processor

SCRIPT_DIR="\$(dirname "\$(readlink -f "\$0")")"
LOG_FILE="\$SCRIPT_DIR/logs/gdpr-processor-test-\$(date +%Y%m%d-%H%M%S).log"

echo "Running GDPR processor test..."
echo "Log will be written to: \$LOG_FILE"

php "\$SCRIPT_DIR/gdpr-processor.php" > "\$LOG_FILE" 2>&1

if [ \$? -eq 0 ]; then
    echo "Test completed successfully"
    echo "Last 10 lines of log:"
    tail -n 10 "\$LOG_FILE"
else
    echo "Test failed with error code \$?"
    echo "Full log:"
    cat "\$LOG_FILE"
fi
EOF
    
    # Make the test script executable
    chmod +x "$SCRIPTS_DIR/cron/test-gdpr-processor.sh"
    
    log "Test script created successfully."
}

# Main execution
main() {
    # Create script directory for logging
    mkdir -p "$SCRIPTS_DIR"
    
    log "Starting OBINexus GDPR Implementation..."
    
    create_directories
    move_gdpr_files
    update_file_paths
    create_db_scripts
    set_permissions
    setup_cron_job
    create_config_files
    create_test_script
    
    log "OBINexus GDPR Implementation completed successfully."
    
    echo ""
    echo "=========================================================="
    echo "OBINexus GDPR Implementation completed successfully."
    echo ""
    echo "GDPR files have been reorganized:"
    echo "  - User interface: $WWW_DIR/obinexus.org/public/gdpr.php"
    echo "  - Admin interface: $WWW_DIR/obinexus.org/admin/gdpr-admin.php"
    echo "  - Processor script: $SCRIPTS_DIR/cron/gdpr-processor.php"
    echo ""
    echo "A cron job has been set up to run the GDPR processor daily at 2:00 AM."
    echo ""
    echo "Database scripts have been created at:"
    echo "  - $DB_DIR/central/gdpr_fields.sql"
    echo ""
    echo "To test the GDPR processor, run:"
    echo "  $SCRIPTS_DIR/cron/test-gdpr-processor.sh"
    echo ""
    echo "Log file: $LOG_FILE"
    echo "=========================================================="
}

# Execute main function
main
