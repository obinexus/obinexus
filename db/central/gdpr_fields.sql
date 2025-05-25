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
