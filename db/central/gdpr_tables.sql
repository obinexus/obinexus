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
