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
