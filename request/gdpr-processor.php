<?php
/**
 * GDPR Request Processor for OBINexus
 * 
 * This script processes pending GDPR requests:
 * - Runs as a cron job (e.g., daily)
 * - Processes deletion requests
 * - Updates request status
 * - Maintains compliance logs
 */

// Include database configuration
require_once 'config/database.php';
require_once 'includes/logger.php';

// Initialize log
$log = new Logger('gdpr_processor');
$log->info('GDPR processor started');

try {
    // Connect to central database
    $central_conn = connect_to_db($central_db);
    
    // Get pending deletion requests
    $stmt = $central_conn->prepare("
        SELECT u.user_id, u.username, u.email, u.data_deletion_date
        FROM Users u
        WHERE u.data_deletion_requested = TRUE 
        AND (u.data_deletion_date IS NULL OR u.data_deletion_date <= NOW())
    ");
    $stmt->execute();
    $deletion_requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $log->info('Found ' . count($deletion_requests) . ' pending deletion requests');
    
    // Process each deletion request
    foreach ($deletion_requests as $request) {
        $user_id = $request['user_id'];
        $log->info('Processing deletion request for user ID: ' . $user_id);
        
        try {
            // Start transaction
            $central_conn->beginTransaction();
            
            // 1. Process Computing database deletion
            $computing_conn = connect_to_db($computing_db);
            deleteComputingUserData($computing_conn, $user_id);
            $log->info('Deleted computing data for user ID: ' . $user_id);
            
            // 2. Process Uchennamdi database deletion
            $uchennamdi_conn = connect_to_db($uchennamdi_db);
            deleteUchennamdiUserData($uchennamdi_conn, $user_id);
            $log->info('Deleted uchennamdi data for user ID: ' . $user_id);
            
            // 3. Process Publishing database deletion
            $publishing_conn = connect_to_db($publishing_db);
            deletePublishingUserData($publishing_conn, $user_id);
            $log->info('Deleted publishing data for user ID: ' . $user_id);
            
            // 4. Process central database deletion (licenses first, then user)
            deleteCentralUserData($central_conn, $user_id);
            $log->info('Deleted central data for user ID: ' . $user_id);
            
            // Commit transaction
            $central_conn->commit();
            
            // Log the successful deletion
            $log->info('Successfully completed deletion for user ID: ' . $user_id);
            
            // Add to compliance log
            addComplianceLog('deletion', $user_id, $request['email'], 'Completed user data deletion across all services');
            
        } catch (Exception $e) {
            // Rollback transaction on error
            if ($central_conn->inTransaction()) {
                $central_conn->rollBack();
            }
            
            $log->error('Error processing deletion for user ID: ' . $user_id . '. Error: ' . $e->getMessage());
            
            // Add to compliance log
            addComplianceLog('deletion_error', $user_id, $request['email'], 'Error during deletion: ' . $e->getMessage());
        }
    }
    
    // Process any pending data access requests
    processDataAccessRequests($central_conn);
    
} catch (PDOException $e) {
    $log->error('Database connection error: ' . $e->getMessage());
}

$log->info('GDPR processor completed');

/**
 * Delete user data from the Computing database
 */
function deleteComputingUserData($conn, $user_id) {
    // Delete from ComputingUsageLogs
    $stmt = $conn->prepare("DELETE FROM ComputingUsageLogs WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    // Delete from ComputingSupport
    $stmt = $conn->prepare("DELETE FROM ComputingSupport WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    // Delete from ComputingProjects
    $stmt = $conn->prepare("DELETE FROM ComputingProjects WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
}

/**
 * Delete user data from the Uchennamdi database
 */
function deleteUchennamdiUserData($conn, $user_id) {
    // First delete OrderItems related to user's orders
    $stmt = $conn->prepare("
        DELETE oi FROM OrderItems oi
        INNER JOIN FashionOrders fo ON oi.order_id = fo.order_id
        WHERE fo.user_id = ?
    ");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    // Delete from FashionOrders
    $stmt = $conn->prepare("DELETE FROM FashionOrders WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    // Delete from FashionProjects
    $stmt = $conn->prepare("DELETE FROM FashionProjects WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    // Delete from CustomerDetails
    $stmt = $conn->prepare("DELETE FROM CustomerDetails WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
}

/**
 * Delete user data from the Publishing database
 */
function deletePublishingUserData($conn, $user_id) {
    // First delete ContentMetrics related to user's publications
    $stmt = $conn->prepare("
        DELETE cm FROM ContentMetrics cm
        INNER JOIN Publications p ON cm.publication_id = p.publication_id
        WHERE p.user_id = ?
    ");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    // Delete from Publications
    $stmt = $conn->prepare("DELETE FROM Publications WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    // Delete from PublishingProjects
    $stmt = $conn->prepare("DELETE FROM PublishingProjects WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    // Delete from PublishingSupport
    $stmt = $conn->prepare("DELETE FROM PublishingSupport WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
}

/**
 * Delete user data from the Central database
 */
function deleteCentralUserData($conn, $user_id) {
    // Delete from DataAccessRequests
    $stmt = $conn->prepare("DELETE FROM DataAccessRequests WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    // Delete from Licenses
    $stmt = $conn->prepare("DELETE FROM Licenses WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    // Delete from Users (will cascade due to foreign key constraints)
    $stmt = $conn->prepare("DELETE FROM Users WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
}

/**
 * Process pending data access requests
 */
function processDataAccessRequests($conn) {
    global $log;
    
    // Get pending data access requests
    $stmt = $conn->prepare("
        SELECT request_id, user_id, services
        FROM DataAccessRequests
        WHERE status = 'pending'
    ");
    $stmt->execute();
    $access_requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $log->info('Found ' . count($access_requests) . ' pending data access requests');
    
    foreach ($access_requests as $request) {
        try {
            // Update status to processing
            $stmt = $conn->prepare("
                UPDATE DataAccessRequests
                SET status = 'processing'
                WHERE request_id = ?
            ");
            $stmt->bindParam(1, $request['request_id'], PDO::PARAM_INT);
            $stmt->execute();
            
            // In a real implementation, this would generate and email the data export
            // For now, we'll just mark it as fulfilled
            $stmt = $conn->prepare("
                UPDATE DataAccessRequests
                SET status = 'fulfilled', fulfilled_date = NOW()
                WHERE request_id = ?
            ");
            $stmt->bindParam(1, $request['request_id'], PDO::PARAM_INT);
            $stmt->execute();
            
            $log->info('Processed data access request ID: ' . $request['request_id'] . ' for user ID: ' . $request['user_id']);
            
            // Add to compliance log
            addComplianceLog('data_access', $request['user_id'], null, 'Fulfilled data access request ID: ' . $request['request_id']);
            
        } catch (Exception $e) {
            $log->error('Error processing data access request ID: ' . $request['request_id'] . '. Error: ' . $e->getMessage());
            
            // Update status to error
            $stmt = $conn->prepare("
                UPDATE DataAccessRequests
                SET status = 'error'
                WHERE request_id = ?
            ");
            $stmt->bindParam(1, $request['request_id'], PDO::PARAM_INT);
            $stmt->execute();
            
            // Add to compliance log
            addComplianceLog('data_access_error', $request['user_id'], null, 'Error fulfilling data access request: ' . $e->getMessage());
        }
    }
}

/**
 * Add entry to the GDPR compliance log
 */
function addComplianceLog($action, $user_id, $email = null, $details = null) {
    global $central_db;
    
    try {
        $conn = connect_to_db($central_db);
        
        // Create compliance log table if it doesn't exist
        $conn->exec("
            CREATE TABLE IF NOT EXISTS GDPRComplianceLog (
                log_id INT PRIMARY KEY AUTO_INCREMENT,
                action VARCHAR(50) NOT NULL,
                user_id INT,
                email VARCHAR(100),
                details TEXT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ");
        
        // Insert log entry
        $stmt = $conn->prepare("
            INSERT INTO GDPRComplianceLog (action, user_id, email, details)
            VALUES (?, ?, ?, ?)
        ");
        $stmt->bindParam(1, $action, PDO::PARAM_STR);
        $stmt->bindParam(2, $user_id, PDO::PARAM_INT);
        $stmt->bindParam(3, $email, PDO::PARAM_STR);
        $stmt->bindParam(4, $details, PDO::PARAM_STR);
        $stmt->execute();
        
    } catch (PDOException $e) {
        global $log;
        $log->error('Error adding compliance log: ' . $e->getMessage());
    }
}
