-- Published content
CREATE TABLE IF NOT EXISTS Publications (
    publication_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    category VARCHAR(50),
    tags TEXT,
    publish_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    access_level ENUM('public', 'tier1', 'tier2', 'tier3') DEFAULT 'public'
);

-- Create GDPR data view for easy access
CREATE OR REPLACE VIEW PublishingUserData AS
SELECT 
    user_id, 
    title, 
    category, 
    publish_date, 
    status, 
    access_level
FROM 
    Publications;
