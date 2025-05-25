-- Insert publications
INSERT INTO Publications (user_id, title, content, category, tags, status, access_level)
VALUES
(1, 'Introduction to OBINexus', 'Content about OBINexus platform...', 'Technology', 'intro,tech,platform', 'published', 'public'),
(2, 'Advanced OBINexus Techniques', 'Content about advanced techniques...', 'Technology', 'advanced,techniques', 'published', 'tier2'),
(3, 'OBINexus for Businesses', 'Content about business applications...', 'Business', 'business,enterprise', 'draft', 'tier1');

-- Get publication IDs
SET @pub1_id = LAST_INSERT_ID();
SET @pub2_id = @pub1_id + 1;
SET @pub3_id = @pub1_id + 2;

-- Insert content metrics
INSERT INTO ContentMetrics (publication_id, views, likes, shares, comments)
VALUES
(@pub1_id, 1250, 45, 12, 8),
(@pub2_id, 350, 22, 5, 3),
(@pub3_id, 0, 0, 0, 0);

-- Insert publishing projects
INSERT INTO PublishingProjects (user_id, title, description, type, tier_level, start_date, status)
VALUES
(1, 'Blog Series', 'Series of blog posts about technology', 'project', 'community', NOW(), 'active'),
(2, 'Technical Documentation', 'Comprehensive technical documentation', 'project', 'partnership', NOW(), 'active'),
(3, 'Business Guide', 'Guide for business implementations', 'operation', 'partnership', NOW(), 'planning');

-- Insert support tickets
INSERT INTO PublishingSupport (user_id, tier_level, subject, description, created_at, status)
VALUES
(1, 'community', 'Publishing issue', 'Cannot publish new content', DATE_SUB(NOW(), INTERVAL 12 DAY), 'resolved'),
(2, 'partnership', 'Access control', 'Need to change access levels', DATE_SUB(NOW(), INTERVAL 6 DAY), 'in-progress'),
(3, 'partnership', 'Draft recovery', 'Lost draft of business guide', DATE_SUB(NOW(), INTERVAL 2 DAY), 'new');
