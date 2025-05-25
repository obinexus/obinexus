-- Create or replace the GDPR data view for Computing service
CREATE OR REPLACE VIEW ComputingUserData AS
SELECT 
    cp.project_id, cp.user_id, cp.title, cp.description, cp.type,
    cp.start_date, cp.end_date, cp.status, cp.outcome,
    cs.ticket_id, cs.subject, cs.description AS ticket_description,
    cs.created_at AS ticket_created, cs.resolved_at, cs.status AS ticket_status,
    cul.log_id, cul.activity_type, cul.timestamp AS activity_time
FROM ComputingProjects cp
LEFT JOIN ComputingSupport cs ON cp.user_id = cs.user_id
LEFT JOIN ComputingUsageLogs cul ON cp.user_id = cul.user_id;
