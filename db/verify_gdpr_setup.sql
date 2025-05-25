-- Verification queries for GDPR setup
-- Run this on each database to verify the setup

-- Central database verification
USE obinexus_central;
SHOW COLUMNS FROM Users LIKE 'data_deletion%';
SHOW TABLES LIKE 'GDPRCompliance%';
SHOW TABLES LIKE 'GDPRAudit%';
SHOW TABLES LIKE 'DataAccess%';

-- Computing database verification
USE obinexus_computing;
SHOW FULL TABLES WHERE Table_type = 'VIEW' AND Tables_in_obinexus_computing LIKE '%UserData%';

-- Publishing database verification
USE obinexus_publishing;
SHOW FULL TABLES WHERE Table_type = 'VIEW' AND Tables_in_obinexus_publishing LIKE '%UserData%';

-- Uchennamdi database verification
USE obinexus_uchennamdi;
SHOW FULL TABLES WHERE Table_type = 'VIEW' AND Tables_in_obinexus_uchennamdi LIKE '%UserData%';
