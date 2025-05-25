-- Computing projects
CREATE TABLE IF NOT EXISTS ComputingProjects (
    project_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(100),
    description TEXT,
    type ENUM('project', 'operation') NOT NULL,
    tier_level ENUM('community', 'business', 'partnership') NOT NULL,
    partnership_type VARCHAR(50),
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP,
    status ENUM('planning', 'active', 'completed', 'on-hold') DEFAULT 'planning',
    outcome TEXT,
    data_retention_period INT COMMENT 'Retention period in days'
);

-- Create GDPR data view for easy access
CREATE OR REPLACE VIEW ComputingUserData AS
SELECT 
    user_id, 
    title, 
    description, 
    type, 
    status, 
    start_date, 
    end_date
FROM 
    ComputingProjects;
