<?php
/**
 * GDPR Management Page for OBINexus Hub
 * 
 * This page allows users to:
 * - View their profile data
 * - Request a data export (all services)
 * - Request account deletion
 * - Access special tier-based GDPR functions
 */

// Start session and include config
session_start();
require_once 'config/database.php';

// Check if user is logged in
if (!isset($_SESSION['user_id'])) {
    header('Location: login.php?redirect=gdpr.php');
    exit;
}

$user_id = $_SESSION['user_id'];
$message = '';
$tier_access = false;
$tier_type = '';

// Process form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Handle data export request
    if (isset($_POST['export_data'])) {
        try {
            // Connect to central database
            $central_conn = connect_to_db($central_db);
            
            // Call the stored procedure
            $stmt = $central_conn->prepare("CALL ExportUserData(?)");
            $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
            $stmt->execute();
            
            // Get user profile data
            $user_data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            
            // Get license data
            $license_stmt = $central_conn->prepare("SELECT l.*, pt.tier_name, pt.tier_type, pt.focus_area 
                                              FROM Licenses l 
                                              LEFT JOIN PartnershipTiers pt ON l.partnership_tier_id = pt.tier_id 
                                              WHERE l.user_id = ?");
            $license_stmt->bindParam(1, $user_id, PDO::PARAM_INT);
            $license_stmt->execute();
            $license_data = $license_stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Connect to service-specific databases and get data from views
            $computing_data = get_computing_data($user_id);
            $uchennamdi_data = get_uchennamdi_data($user_id);
            $publishing_data = get_publishing_data($user_id);
            
            // Combine all data
            $export_data = [
                'user_profile' => $user_data,
                'licenses' => $license_data,
                'computing_data' => $computing_data,
                'uchennamdi_data' => $uchennamdi_data,
                'publishing_data' => $publishing_data
            ];
            
            // Convert to JSON
            $json_data = json_encode($export_data, JSON_PRETTY_PRINT);
            
            // Set headers for download
            header('Content-Disposition: attachment; filename="obinexus_data_export_' . date('Y-m-d') . '.json"');
            header('Content-Type: application/json');
            header('Content-Length: ' . strlen($json_data));
            header('Connection: close');
            
            // Output the data and end the script
            echo $json_data;
            exit;
            
        } catch (PDOException $e) {
            $message = "Error exporting data: " . $e->getMessage();
        }
    }
    
    // Handle deletion request
    if (isset($_POST['request_deletion'])) {
        try {
            // Connect to central database
            $central_conn = connect_to_db($central_db);
            
            // Call the stored procedure
            $stmt = $central_conn->prepare("CALL RequestDataDeletion(?)");
            $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
            $stmt->execute();
            
            $message = "Your account deletion request has been submitted. Your data will be processed for deletion according to our privacy policy.";
            
        } catch (PDOException $e) {
            $message = "Error requesting deletion: " . $e->getMessage();
        }
    }
}

// Get user data
try {
    // Connect to central database
    $central_conn = connect_to_db($central_db);
    
    // Get user profile
    $stmt = $central_conn->prepare("SELECT * FROM Users WHERE user_id = ?");
    $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $stmt->execute();
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Check if user has special tier access
    $tier_stmt = $central_conn->prepare("
        SELECT pt.tier_name, pt.tier_type 
        FROM Licenses l 
        JOIN PartnershipTiers pt ON l.partnership_tier_id = pt.tier_id 
        WHERE l.user_id = ? AND l.tier = 'partnership'
    ");
    $tier_stmt->bindParam(1, $user_id, PDO::PARAM_INT);
    $tier_stmt->execute();
    $tier_info = $tier_stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($tier_info) {
        $tier_access = true;
        $tier_type = $tier_info['tier_type'];
        $tier_name = $tier_info['tier_name'];
    }
    
} catch (PDOException $e) {
    $message = "Error retrieving user data: " . $e->getMessage();
}

/**
 * Get user data from the Computing service
 */
function get_computing_data($user_id) {
    global $computing_db;
    try {
        $conn = connect_to_db($computing_db);
        $stmt = $conn->prepare("SELECT * FROM ComputingUserData WHERE user_id = ?");
        $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        return ["error" => $e->getMessage()];
    }
}

/**
 * Get user data from the Uchennamdi service
 */
function get_uchennamdi_data($user_id) {
    global $uchennamdi_db;
    try {
        $conn = connect_to_db($uchennamdi_db);
        $stmt = $conn->prepare("SELECT * FROM UchennamdiUserData WHERE user_id = ?");
        $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        return ["error" => $e->getMessage()];
    }
}

/**
 * Get user data from the Publishing service
 */
function get_publishing_data($user_id) {
    global $publishing_db;
    try {
        $conn = connect_to_db($publishing_db);
        $stmt = $conn->prepare("SELECT * FROM PublishingUserData WHERE user_id = ?");
        $stmt->bindParam(1, $user_id, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        return ["error" => $e->getMessage()];
    }
}

?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OBINexus - GDPR Data Management</title>
    <link rel="stylesheet" href="assets/css/styles.css">
</head>
<body>
    <?php include('includes/header.php'); ?>
    
    <main class="container">
        <h1>Your Privacy Rights</h1>
        
        <?php if (!empty($message)): ?>
            <div class="alert <?php echo (strpos($message, 'Error') !== false) ? 'alert-danger' : 'alert-success'; ?>">
                <?php echo $message; ?>
            </div>
        <?php endif; ?>
        
        <section class="user-profile">
            <h2>Your Profile Information</h2>
            <div class="profile-details">
                <p><strong>Username:</strong> <?php echo htmlspecialchars($user['username']); ?></p>
                <p><strong>Email:</strong> <?php echo htmlspecialchars($user['email']); ?></p>
                <p><strong>Name:</strong> <?php echo htmlspecialchars($user['first_name'] . ' ' . $user['last_name']); ?></p>
                <p><strong>Country:</strong> <?php echo htmlspecialchars($user['country']); ?></p>
                <p><strong>Account Created:</strong> <?php echo date('F j, Y', strtotime($user['created_at'])); ?></p>
                <p><strong>GDPR Consent:</strong> <?php echo $user['gdpr_consent'] ? 'Given on ' . date('F j, Y', strtotime($user['gdpr_consent_date'])) : 'Not given'; ?></p>
                <p><strong>Marketing Consent:</strong> <?php echo $user['marketing_consent'] ? 'Yes' : 'No'; ?></p>
            </div>
        </section>
        
        <section class="gdpr-actions">
            <h2>GDPR Data Actions</h2>
            
            <div class="action-buttons">
                <form method="post" action="">
                    <button type="submit" name="export_data" class="btn btn-primary">Export My Data</button>
                    <p class="help-text">Download a complete copy of all your data across all OBINexus services.</p>
                </form>
                
                <form method="post" action="" onsubmit="return confirm('Are you sure you want to request deletion of your account? This action cannot be undone.');">
                    <button type="submit" name="request_deletion" class="btn btn-danger">Request Account Deletion</button>
                    <p class="help-text">Request the deletion of your account and all associated data from our systems.</p>
                </form>
            </div>
            
            <?php if ($tier_access): ?>
                <div class="tier-access">
                    <h3>Special Tier Access - <?php echo htmlspecialchars($tier_name); ?></h3>
                    <?php if ($tier_type == 'uche_eze'): ?>
                        <p>As a Knowledge King tier partner, you have access to extended GDPR project decisions, including:</p>
                        <ul>
                            <li>Direct access to service data views through custom dashboards</li>
                            <li>Ability to manage GDPR compliance for associated projects</li>
                            <li>Delegated rights for data management in your knowledge projects</li>
                        </ul>
                        <a href="dashboard/knowledge-tier.php" class="btn btn-secondary">Access Knowledge King Dashboard</a>
                    <?php elseif ($tier_type == 'obi_eze'): ?>
                        <p>As a Heart King tier partner, you have access to extended GDPR operational controls, including:</p>
                        <ul>
                            <li>Direct access to operational data views through custom dashboards</li>
                            <li>Ability to manage GDPR compliance for associated operations</li>
                            <li>Delegated rights for data management in your operations</li>
                        </ul>
                        <a href="dashboard/heart-tier.php" class="btn btn-secondary">Access Heart King Dashboard</a>
                    <?php endif; ?>
                </div>
            <?php endif; ?>
        </section>
        
        <section class="gdpr-info">
            <h2>About Your Privacy Rights</h2>
            <p>Under the General Data Protection Regulation (GDPR), you have several rights regarding your personal data:</p>
            <ul>
                <li><strong>Right to Access:</strong> You can request a copy of all personal data we hold about you.</li>
                <li><strong>Right to Rectification:</strong> You can request that we correct any inaccurate data.</li>
                <li><strong>Right to Erasure:</strong> You can request that we delete your personal data.</li>
                <li><strong>Right to Restriction:</strong> You can request that we restrict the processing of your data.</li>
                <li><strong>Right to Data Portability:</strong> You can request that we provide your data in a machine-readable format.</li>
                <li><strong>Right to Object:</strong> You can object to the processing of your personal data.</li>
            </ul>
            <p>For more information, please read our <a href="privacy-policy.php">Privacy Policy</a>.</p>
        </section>
    </main>
    
    <?php include('includes/footer.php'); ?>
    
    <script src="assets/js/script.js"></script>
</body>
</html>
