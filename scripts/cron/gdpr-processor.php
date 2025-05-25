<?php
/**
 * OBINexus GDPR Data Processor
 * 
 * This script processes GDPR data requests (access and deletion)
 * Runs as a cron job daily to handle pending requests within the 30-day time limit
 */

// Set error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

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

// Get pending data access requests
log_message("Checking for pending data access requests...");
$stmt = $central_conn->query("
    SELECT request_id, user_id, services, status 
    FROM DataAccessRequests 
    WHERE status IN ('pending', 'processing')
");
$requests = $stmt->fetchAll(PDO::FETCH_ASSOC);

log_message("Found " . count($requests) . " pending requests");

// Process each request
foreach ($requests as $request) {
    log_message("Processing request ID: " . $request['request_id'] . " for user ID: " . $request['user_id']);
    
    // Update request status to processing
    $update_stmt = $central_conn->prepare("
        UPDATE DataAccessRequests 
        SET status = 'processing' 
        WHERE request_id = ? AND status = 'pending'
    ");
    $update_stmt->execute([$request['request_id']]);
    
    // Create export directory if it doesn't exist
    $export_dir = __DIR__ . '/../../data/exports/user_' . $request['user_id'];
    if (!file_exists($export_dir)) {
        mkdir($export_dir, 0755, true);
    }
    
    // Process services
    $services = explode(',', $request['services']);
    $exported_files = [];
    
    // Export user data from central database
    log_message("Exporting central user data");
    $user_stmt = $central_conn->prepare("
        SELECT * FROM Users WHERE user_id = ?
    ");
    $user_stmt->execute([$request['user_id']]);
    $user_data = $user_stmt->fetch(PDO::FETCH_ASSOC);
    
    // Remove sensitive data
    if (isset($user_data['password'])) {
        unset($user_data['password']);
    }
    
    // Save user data
    $user_file = $export_dir . '/user_profile.json';
    file_put_contents($user_file, json_encode($user_data, JSON_PRETTY_PRINT));
    $exported_files[] = $user_file;
    
    // Export licenses
    $license_stmt = $central_conn->prepare("
        SELECT * FROM Licenses WHERE user_id = ?
    ");
    $license_stmt->execute([$request['user_id']]);
    $license_data = $license_stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $license_file = $export_dir . '/user_licenses.json';
    file_put_contents($license_file, json_encode($license_data, JSON_PRETTY_PRINT));
    $exported_files[] = $license_file;
    
    // Process service-specific data
    foreach ($services as $service) {
        $service = trim($service);
        log_message("Processing service: $service");
        
        switch ($service) {
            case 'computing':
                $conn = connect_to_db($computing_db);
                if ($conn) {
                    // Export computing data using the view
                    $stmt = $conn->prepare("
                        SELECT * FROM ComputingUserData WHERE user_id = ?
                    ");
                    $stmt->execute([$request['user_id']]);
                    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    $file = $export_dir . '/computing_data.json';
                    file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT));
                    $exported_files[] = $file;
                }
                break;
                
            case 'uchennamdi':
                $conn = connect_to_db($uchennamdi_db);
                if ($conn) {
                    // Export fashion data using the view
                    $stmt = $conn->prepare("
                        SELECT * FROM UchennamdiUserData WHERE user_id = ?
                    ");
                    $stmt->execute([$request['user_id']]);
                    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    $file = $export_dir . '/uchennamdi_data.json';
                    file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT));
                    $exported_files[] = $file;
                }
                break;
                
            case 'publishing':
                $conn = connect_to_db($publishing_db);
                if ($conn) {
                    // Export publishing data using the view
                    $stmt = $conn->prepare("
                        SELECT * FROM PublishingUserData WHERE user_id = ?
                    ");
                    $stmt->execute([$request['user_id']]);
                    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    $file = $export_dir . '/publishing_data.json';
                    file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT));
                    $exported_files[] = $file;
                }
                break;
                
            default:
                log_message("Unknown service: $service - skipping");
        }
    }
    
    // Create zip archive of all exported files
    $zip_file = $export_dir . '/gdpr_export.zip';
    $zip = new ZipArchive();
    if ($zip->open($zip_file, ZipArchive::CREATE | ZipArchive::OVERWRITE) === TRUE) {
        foreach ($exported_files as $file) {
            $zip->addFile($file, basename($file));
        }
        $zip->close();
        log_message("Created zip archive: $zip_file");
        
        // Update request status to fulfilled
        $update_stmt = $central_conn->prepare("
            UPDATE DataAccessRequests 
            SET status = 'fulfilled', 
                fulfilled_date = NOW() 
            WHERE request_id = ?
        ");
        $update_stmt->execute([$request['request_id']]);
        
        log_message("Request ID: " . $request['request_id'] . " marked as fulfilled");
    } else {
        log_message("Failed to create zip archive");
    }
}

// Check for data deletion requests
log_message("Checking for data deletion requests...");
$stmt = $central_conn->query("
    SELECT user_id 
    FROM Users 
    WHERE data_deletion_requested = TRUE 
    AND data_deletion_date IS NOT NULL
");
$deletion_requests = $stmt->fetchAll(PDO::FETCH_ASSOC);

log_message("Found " . count($deletion_requests) . " deletion requests");

// Process each deletion request
foreach ($deletion_requests as $request) {
    $user_id = $request['user_id'];
    log_message("Processing deletion request for user ID: $user_id");
    
    // Delete from computing database
    $computing_conn = connect_to_db($computing_db);
    if ($computing_conn) {
        // Delete from related tables
        $tables = ['ComputingUsageLogs', 'ComputingSupport', 'ComputingProjects'];
        foreach ($tables as $table) {
            $stmt = $computing_conn->prepare("DELETE FROM $table WHERE user_id = ?");
            $stmt->execute([$user_id]);
            $count = $stmt->rowCount();
            log_message("Deleted $count records from $table");
        }
    }
    
    // Delete from uchennamdi database
    $uchennamdi_conn = connect_to_db($uchennamdi_db);
    if ($uchennamdi_conn) {
        // Delete order items first due to foreign key constraints
        $order_stmt = $uchennamdi_conn->prepare("
            SELECT order_id FROM FashionOrders WHERE user_id = ?
        ");
        $order_stmt->execute([$user_id]);
        $orders = $order_stmt->fetchAll(PDO::FETCH_COLUMN);
        
        foreach ($orders as $order_id) {
            $stmt = $uchennamdi_conn->prepare("DELETE FROM OrderItems WHERE order_id = ?");
            $stmt->execute([$order_id]);
        }
        
        // Delete from other tables
        $tables = ['FashionOrders', 'CustomerDetails', 'FashionProjects'];
        foreach ($tables as $table) {
            $stmt = $uchennamdi_conn->prepare("DELETE FROM $table WHERE user_id = ?");
            $stmt->execute([$user_id]);
            $count = $stmt->rowCount();
            log_message("Deleted $count records from $table");
        }
    }
    
    // Delete from publishing database
    $publishing_conn = connect_to_db($publishing_db);
    if ($publishing_conn) {
        // Delete content metrics first due to foreign key constraints
        $pub_stmt = $publishing_conn->prepare("
            SELECT publication_id FROM Publications WHERE user_id = ?
        ");
        $pub_stmt->execute([$user_id]);
        $publications = $pub_stmt->fetchAll(PDO::FETCH_COLUMN);
        
        foreach ($publications as $pub_id) {
            $stmt = $publishing_conn->prepare("DELETE FROM ContentMetrics WHERE publication_id = ?");
            $stmt->execute([$pub_id]);
        }
        
        // Delete from other tables
        $tables = ['Publications', 'PublishingProjects', 'PublishingSupport'];
        foreach ($tables as $table) {
            $stmt = $publishing_conn->prepare("DELETE FROM $table WHERE user_id = ?");
            $stmt->execute([$user_id]);
            $count = $stmt->rowCount();
            log_message("Deleted $count records from $table");
        }
    }
    
    // Delete from central database last
    // First delete from Licenses due to foreign key
    $license_stmt = $central_conn->prepare("DELETE FROM Licenses WHERE user_id = ?");
    $license_stmt->execute([$user_id]);
    $count = $license_stmt->rowCount();
    log_message("Deleted $count licenses from central database");
    
    // Delete access requests
    $request_stmt = $central_conn->prepare("DELETE FROM DataAccessRequests WHERE user_id = ?");
    $request_stmt->execute([$user_id]);
    $count = $request_stmt->rowCount();
    log_message("Deleted $count data access requests from central database");
    
    // Finally delete the user
    $user_stmt = $central_conn->prepare("DELETE FROM Users WHERE user_id = ?");
    $user_stmt->execute([$user_id]);
    $count = $user_stmt->rowCount();
    log_message("Deleted user ID: $user_id from central database");
}

log_message("GDPR Processor completed successfully");

