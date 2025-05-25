-- OBINexus Central Database GDPR Setup Script

-- Users table with GDPR-related fields
CREATE TABLE IF NOT EXISTS Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    gdpr_consent BOOLEAN DEFAULT FALSE,
    gdpr_consent_date TIMESTAMP,
    data_deletion_requested BOOLEAN DEFAULT FALSE,
    data_deletion_date TIMESTAMP,
    marketing_consent BOOLEAN DEFAULT FALSE,
    UNIQUE KEY (email)
);

-- Partnership tier definitions
CREATE TABLE IF NOT EXISTS PartnershipTiers (
    tier_id INT PRIMARY KEY AUTO_INCREMENT,
    tier_name VARCHAR(50) NOT NULL,
    tier_type ENUM('uche_eze', 'obi_eze') NOT NULL,
    description TEXT,
    level INT NOT NULL,
    focus_area ENUM('project', 'operation') NOT NULL
);

-- User licenses (cross-service)
CREATE TABLE IF NOT EXISTS Licenses (
    license_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    service ENUM('computing', 'uchennamdi', 'publishing') NOT NULL,
    tier ENUM('community', 'business', 'partnership') NOT NULL,
    partnership_tier_id INT,
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (partnership_tier_id) REFERENCES PartnershipTiers(tier_id)
);

-- GDPR data access requests
CREATE TABLE IF NOT EXISTS DataAccessRequests (
    request_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fulfilled_date TIMESTAMP,
    status ENUM('pending', 'processing', 'fulfilled', 'denied') DEFAULT 'pending',
    services VARCHAR(255) COMMENT 'Comma-separated list of services',
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Insert basic partnership tiers if they don't exist
INSERT IGNORE INTO PartnershipTiers (tier_id, tier_name, tier_type, description, level, focus_area) VALUES
(1, 'Knowledge King Tier 1', 'uche_eze', 'Partnership focused on knowledge projects - level 1', 1, 'project'),
(2, 'Knowledge King Tier 2', 'uche_eze', 'Partnership focused on knowledge projects - level 2', 2, 'project'),
(3, 'Heart King Tier 1', 'obi_eze', 'Partnership focused on operational change - level 1', 1, 'operation'),
(4, 'Heart King Tier 2', 'obi_eze', 'Partnership focused on operational change - level 2', 2, 'operation');

-- Create GDPR procedures

-- Get all user licenses across services
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS GetUserLicenses(IN user_id_param INT)
BEGIN
    SELECT 
        l.license_id, 
        l.service, 
        l.tier, 
        pt.tier_name,
        pt.tier_type,
        l.start_date,
        l.expiry_date,
        l.active
    FROM 
        Licenses l
    LEFT JOIN 
        PartnershipTiers pt ON l.partnership_tier_id = pt.tier_id
    WHERE 
        l.user_id = user_id_param;
END //
DELIMITER ;

-- GDPR data export procedure
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS ExportUserData(IN user_id_param INT)
BEGIN
    -- User profile data
    SELECT * FROM Users WHERE user_id = user_id_param;
    
    -- License data
    SELECT * FROM Licenses WHERE user_id = user_id_param;
END //
DELIMITER ;

-- GDPR data deletion procedure
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS RequestDataDeletion(IN user_id_param INT)
BEGIN
    -- Mark user for deletion
    UPDATE Users 
    SET data_deletion_requested = TRUE,
        data_deletion_date = NOW()
    WHERE user_id = user_id_param;
END //
DELIMITER ;

-- Create a consolidated view for tracking GDPR requests
CREATE OR REPLACE VIEW GDPRRequestSummary AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.data_deletion_requested,
    u.data_deletion_date,
    u.gdpr_consent,
    u.gdpr_consent_date,
    dar.request_id,
    dar.request_date,
    dar.fulfilled_date,
    dar.status,
    dar.services
FROM 
    Users u
LEFT JOIN 
    DataAccessRequests dar ON u.user_id = dar.user_id
WHERE 
    u.data_deletion_requested = TRUE OR dar.request_id IS NOT NULL;
