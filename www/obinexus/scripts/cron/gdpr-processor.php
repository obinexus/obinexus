<?php
/**
 * OBINexus GDPR Data Processor
 * 
 * This script processes GDPR data requests (access and deletion)
 * Runs as a cron job daily to handle pending requests
 */

// Set error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set timezone
date_default_timezone_set('UTC');

// Log function
function log_message($message) {
    echo date('Y-m-d H:i:s') . " - $message\n";
}

log_message("GDPR Processor started");

// Database connection configurations
$central_db = [
    'host' => 'db5017799522.hosting.data.io',
    'username' => 'dbu5547458',
    'password' => 'your_password',
    'dbname' => 'obinexus_central',
    'port' => 3306
];

$computing_db = [
    'host' => 'db5017799522.hosting.data.io',
    'username' => 'dbu5547458',
    'password' => 'your_password',
    'dbname' => 'obinexus_computing',
    'port' => 3306
];

$uchennamdi_db = [
    'host' => 'db5017799522.hosting.data.io',
    'username' => 'dbu5547458',
    'password' => 'your_password',
    'dbname' => 'obinexus_uchennamdi',
    'port' => 3306
];

$publishing_db = [
    'host' => 'db5017799522.hosting.data.io',
    'username' => 'dbu5547458',
    'password' => 'your_password',
    'dbname' => 'obinexus_publishing',
    'port' => 3306
];

// Connect to database function
function connect_to_db($db_config) {
    try {
        $conn = new PDO(
            "mysql:host={$db_config['host']};dbname={$db_config['dbname']};port={$db_config['port']}", 
            $db_config['username'], 
            $db_config['password']
        );
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $conn;
    } catch(PDOException $e) {
        log_message("Connection failed: " . $e->getMessage());
        return null;
    }
}

// Connect to central database
$central_conn = connect_to_db($central_db);
if (!$central_conn) {
    log_message("Failed to connect to central database. Exiting.");
    exit(1);
}

// Process GDPR data access requests
function process_data_access_requests($central_conn, $db_configs) {
    log_message("Processing data access requests...");
    
    // Get pending requests
    $stmt = $central_conn->prepare("
        SELECT request_id, user_id, services 
        FROM DataAccessRequests 
        WHERE status = 'pending'
    ");
    $stmt->execute();
    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    log_message("Found " . count($requests) . " pending data access requests");
    
    foreach ($requests as $request) {
        $request_id = $request['request_id'];
        $user_id = $request['user_id'];
        $services = explode(',', $request['services']);
        
        log_message("Processing request ID: $request_id for user ID: $user_id");
        
        // Update request status to processing
        $update_stmt = $central_conn->prepare("
            UPDATE DataAccessRequests 
            SET status = 'processing' 
            WHERE request_id = ?
        ");
        $update_stmt->execute([$request_id]);
        
        // Create export directory
        $export_dir = __DIR__ . '/../../data/exports/user_' . $user_id;
        if (!is_dir($export_dir)) {
            mkdir($export_dir, 0755, true);
        }
        
        $exported_files = [];
        
        // Export central user data
        $user_data = export_central_user_data($central_conn, $user_id, $export_dir);
        if ($user_data) {
            $exported_files = array_merge($exported_files, $user_data);
        }
        
        // Export service-specific data
        foreach ($services as $service) {
            $service = trim($service);
            if (empty($service)) continue;
            
            log_message("Exporting data for service: $service");
            
            switch ($service) {
                case 'computing':
                    $files = export_computing_data($db_configs['computing'], $user_id, $export_dir);
                    if ($files) {
                        $exported_files = array_merge($exported_files, $files);
                    }
                    break;
                    
                case 'uchennamdi':
                    $files = export_uchennamdi_data($db_configs['uchennamdi'], $user_id, $export_dir);
                    if ($files) {
                        $exported_files = array_merge($exported_files, $files);
                    }
                    break;
                    
                case 'publishing':
                    $files = export_publishing_data($db_configs['publishing'], $user_id, $export_dir);
                    if ($files) {
                        $exported_files = array_merge($exported_files, $files);
                    }
                    break;
                    
                default:
                    log_message("Unknown service: $service");
            }
        }
        
        // Create zip archive
        if (count($exported_files) > 0) {
            $zip_file = $export_dir . '/gdpr_export.zip';
            create_zip_archive($exported_files, $zip_file);
            
            // Update request status
            $update_stmt = $central_conn->prepare("
                UPDATE DataAccessRequests 
                SET status = 'fulfilled', 
                    fulfilled_date = NOW() 
                WHERE request_id = ?
            ");
            $update_stmt->execute([$request_id]);
            
            log_message("Request ID: $request_id fulfilled. Export saved to: $zip_file");
        } else {
            log_message("No data exported for request ID: $request_id");
            
            // Update request status
            $update_stmt = $central_conn->prepare("
                UPDATE DataAccessRequests 
                SET status = 'fulfilled', 
                    fulfilled_date = NOW() 
                WHERE request_id = ?
            ");
            $update_stmt->execute([$request_id]);
        }
    }
}

// Process data deletion requests
function process_data_deletion_requests($central_conn, $db_configs) {
    log_message("Processing data deletion requests...");
    
    // Get users marked for deletion
    $stmt = $central_conn->prepare("
        SELECT user_id 
        FROM Users 
        WHERE data_deletion_requested = TRUE 
        AND data_deletion_date IS NOT NULL
    ");
    $stmt->execute();
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    log_message("Found " . count($users) . " users marked for deletion");
    
    foreach ($users as $user) {
        $user_id = $user['user_id'];
        log_message("Processing deletion for user ID: $user_id");
        
        // Delete from computing service
        $computing_conn = connect_to_db($db_configs['computing']);
        if ($computing_conn) {
            $stmt = $computing_conn->prepare("DELETE FROM ComputingProjects WHERE user_id = ?");
            $stmt->execute([$user_id]);
            log_message("Deleted computing data for user ID: $user_id");
        }
        
        // Delete from fashion service
        $uchennamdi_conn = connect_to_db($db_configs['uchennamdi']);
        if ($uchennamdi_conn) {
            $stmt = $uchennamdi_conn->prepare("DELETE FROM CustomerDetails WHERE user_id = ?");
            $stmt->execute([$user_id]);
            log_message("Deleted fashion data for user ID: $user_id");
        }
        
        // Delete from publishing service
        $publishing_conn = connect_to_db($db_configs['publishing']);
        if ($publishing_conn) {
            $stmt = $publishing_conn->prepare("DELETE FROM Publications WHERE user_id = ?");
            $stmt->execute([$user_id]);
            log_message("Deleted publishing data for user ID: $user_id");
        }
        
        // Delete licenses first due to foreign key constraints
        $stmt = $central_conn->prepare("DELETE FROM Licenses WHERE user_id = ?");
        $stmt->execute([$user_id]);
        
        // Delete access requests
        $stmt = $central_conn->prepare("DELETE FROM DataAccessRequests WHERE user_id = ?");
        $stmt->execute([$user_id]);
        
        // Finally delete the user
        $stmt = $central_conn->prepare("DELETE FROM Users WHERE user_id = ?");
        $stmt->execute([$user_id]);
        
        log_message("User ID: $user_id deleted completely from all systems");
    }
}

// Export central user data
function export_central_user_data($conn, $user_id, $export_dir) {
    log_message("Exporting central user data for user ID: $user_id");
    
    $exported_files = [];
    
    // Export user profile
    $stmt = $conn->prepare("SELECT * FROM Users WHERE user_id = ?");
    $stmt->execute([$user_id]);
    $user_data = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user_data) {
        // Remove sensitive data
        unset($user_data['password']);
        
        $file = $export_dir . '/user_profile.json';
        file_put_contents($file, json_encode($user_data, JSON_PRETTY_PRINT));
        $exported_files[] = $file;
    }
    
    // Export licenses
    $stmt = $conn->prepare("SELECT * FROM Licenses WHERE user_id = ?");
    $stmt->execute([$user_id]);
    $licenses = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($licenses) > 0) {
        $file = $export_dir . '/user_licenses.json';
        file_put_contents($file, json_encode($licenses, JSON_PRETTY_PRINT));
        $exported_files[] = $file;
    }
    
    return $exported_files;
}

// Export computing data
function export_computing_data($db_config, $user_id, $export_dir) {
    $conn = connect_to_db($db_config);
    if (!$conn) {
        return false;
    }
    
    log_message("Exporting computing data for user ID: $user_id");
    
    $stmt = $conn->prepare("SELECT * FROM ComputingUserData WHERE user_id = ?");
    $stmt->execute([$user_id]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($data) > 0) {
        $file = $export_dir . '/computing_data.json';
        file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT));
        return [$file];
    }
    
    return [];
}

// Export uchennamdi data
function export_uchennamdi_data($db_config, $user_id, $export_dir) {
    $conn = connect_to_db($db_config);
    if (!$conn) {
        return false;
    }
    
    log_message("Exporting fashion data for user ID: $user_id");
    
    $stmt = $conn->prepare("SELECT * FROM UchennamdiUserData WHERE user_id = ?");
    $stmt->execute([$user_id]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($data) > 0) {
        $file = $export_dir . '/uchennamdi_data.json';
        file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT));
        return [$file];
    }
    
    return [];
}

// Export publishing data
function export_publishing_data($db_config, $user_id, $export_dir) {
    $conn = connect_to_db($db_config);
    if (!$conn) {
        return false;
    }
    
    log_message("Exporting publishing data for user ID: $user_id");
    
    $stmt = $conn->prepare("SELECT * FROM PublishingUserData WHERE user_id = ?");
    $stmt->execute([$user_id]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($data) > 0) {
        $file = $export_dir . '/publishing_data.json';
        file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT));
        return [$file];
    }
    
    return [];
}

// Create zip archive
function create_zip_archive($files, $zip_file) {
    log_message("Creating zip archive: $zip_file");
    
    $zip = new ZipArchive();
    if ($zip->open($zip_file, ZipArchive::CREATE | ZipArchive::OVERWRITE) === TRUE) {
        foreach ($files as $file) {
            $zip->addFile($file, basename($file));
        }
        $zip->close();
        log_message("Zip archive created successfully");
        return true;
    } else {
        log_message("Failed to create zip archive");
        return false;
    }
}

// Process requests
process_data_access_requests($central_conn, [
    'computing' => $computing_db,
    'uchennamdi' => $uchennamdi_db,
    'publishing' => $publishing_db
]);

process_data_deletion_requests($central_conn, [
    'computing' => $computing_db,
    'uchennamdi' => $uchennamdi_db,
    'publishing' => $publishing_db
]);

log_message("GDPR Processor completed successfully");