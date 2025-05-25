-- Customer measurements and preferences
CREATE TABLE IF NOT EXISTS CustomerDetails (
    detail_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    bust_cm DECIMAL(5,2),
    waist_cm DECIMAL(5,2),
    hip_cm DECIMAL(5,2),
    height_cm DECIMAL(5,2),
    inseam_cm DECIMAL(5,2),
    sleeve_length_cm DECIMAL(5,2),
    color_preferences TEXT,
    style_preferences TEXT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    consent_for_data BOOLEAN DEFAULT TRUE,
    data_retention_period INT COMMENT 'Retention period in days'
);

-- Create GDPR data view for easy access
CREATE OR REPLACE VIEW UchennamdiUserData AS
SELECT 
    user_id, 
    bust_cm, 
    waist_cm, 
    hip_cm, 
    color_preferences, 
    style_preferences
FROM 
    CustomerDetails;
