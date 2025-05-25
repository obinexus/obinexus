-- Create or replace the GDPR data view for Uchennamdi service
CREATE OR REPLACE VIEW UchennamdiUserData AS
SELECT 
    cd.user_id, cd.bust_cm, cd.waist_cm, cd.hip_cm, cd.height_cm, 
    cd.inseam_cm, cd.sleeve_length_cm, cd.color_preferences, cd.style_preferences,
    fo.order_id, fo.order_date, fo.total_amount, fo.status AS order_status,
    fp.project_id, fp.title, fp.description, fp.type AS project_type,
    fp.start_date, fp.end_date, fp.status AS project_status
FROM CustomerDetails cd
LEFT JOIN FashionOrders fo ON cd.user_id = fo.user_id
LEFT JOIN FashionProjects fp ON cd.user_id = fp.user_id;
