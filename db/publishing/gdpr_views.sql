-- Create or replace the GDPR data view for Publishing service
CREATE OR REPLACE VIEW PublishingUserData AS
SELECT 
    p.publication_id, p.user_id, p.title, p.content, p.category, p.tags,
    p.publish_date, p.last_updated, p.status, p.access_level,
    pp.project_id, pp.title AS project_title, pp.description, pp.type AS project_type,
    pp.start_date, pp.end_date, pp.status AS project_status,
    ps.ticket_id, ps.subject, ps.description AS ticket_description
FROM Publications p
LEFT JOIN PublishingProjects pp ON p.user_id = pp.user_id
LEFT JOIN PublishingSupport ps ON p.user_id = ps.user_id;
