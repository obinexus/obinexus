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
