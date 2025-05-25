<?php
/**
 * GDPR Admin Dashboard for OBINexus
 * 
 * This page allows administrators to:
 * - View pending GDPR requests
 * - Monitor compliance status
 * - Generate compliance reports
 * - Manually process special requests
 */

// Start session and include config
session_start();
require_once 'config/database.php';

// Check if user is admin
if (!isset($_SESSION['user_id']) || !isset($_SESSION['is_admin']) || $_SESSION['is_admin'] !== true) {
    header('Location: login.php?redirect=admin/gdpr-admin.php');
    exit;
}

$message = '';
$status_filter = isset($_GET['status']) ? $_GET['status'] : 'all';
$date_from = isset($_GET['date_from']) ? $_GET['date_from'] : date('Y-m-d', strtotime('-30 days'));
$date_to = isset($_GET['date_to']) ? $_GET['date_to'] : date('Y-m-d');

// Process actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['process_request'])) {
        $request_id = $_POST['request_id'];
        $action = $_POST['action'];
        
        try {
            $central_conn = connect_to_db($central_db);
            
            if ($action === 'approve_deletion') {
                // Manually trigger deletion process
                $stmt = $central_conn->prepare("
                    UPDATE Users
                    SET data_deletion_requested = TRUE, 
                        data_deletion_date = NOW()
                    WHERE user_id = (
                        SELECT user_id FROM DataAccessRequests WHERE request_id = ?
                    )
                ");
                $stmt->bindParam(1, $request_id, PDO::PARAM_INT);
                $stmt->execute();
                
                // Update request status
                $stmt = $central_conn->prepare("
                    UPDATE DataAccessRequests
                    SET status = 'processing', 
                        fulfilled_date = NOW()
                    WHERE request_id = ?
                ");
                $stmt->bindParam(1, $request_id, PDO::PARAM_INT);
                $stmt->execute();
                
                $message = "Deletion request approved and scheduled for processing.";
                
            } elseif ($action === 'fulfill_access') {
                // Mark access request as fulfilled
                $stmt = $central_conn->prepare("
                    UPDATE DataAccessRequests
                    SET status = 'fulfilled', 
                        fulfilled_date = NOW()
                    WHERE request_id = ?
                ");
                $stmt->bindParam(1, $request_id, PDO::PARAM_INT);
                $stmt->execute();
                
                $message = "Access request marked as fulfilled.";
                
            } elseif ($action === 'deny_request') {
                // Deny the request
                $stmt = $central_conn->prepare("
                    UPDATE DataAccessRequests
                    SET status = 'denied', 
                        fulfilled_date = NOW()
                    WHERE request_id = ?
                ");
                $stmt->bindParam(1, $request_id, PDO::PARAM_INT);
                $stmt->execute();
                
                $message = "Request has been denied.";
            }
            
        } catch (PDOException $e) {
            $message = "Error processing request: " . $e->getMessage();
        }
    }
    
    // Generate compliance report
    if (isset($_POST['generate_report'])) {
        $report_type = $_POST['report_type'];
        $date_range = $_POST['date_range'];
        
        // Redirect to report generator
        header("Location: admin/gdpr-report.php?type={$report_type}&range={$date_range}");
        exit;
    }
}

// Get GDPR requests
try {
    $central_conn = connect_to_db($central_db);
    
    // Build query based on filters
    $query = "
        SELECT dar.request_id, dar.user_id, u.email, u.username, 
               dar.request_date, dar.fulfilled_date, dar.status, dar.services
        FROM DataAccessRequests dar
        JOIN Users u ON dar.user_id = u.user_id
        WHERE 1=1
    ";
    
    $params = [];
    
    if ($status_filter !== 'all') {
        $query .= " AND dar.status = ?";
        $params[] = $status_filter;
    }
    
    $query .= " AND dar.request_date BETWEEN ? AND ?";
    $params[] = $date_from . ' 00:00:00';
    $params[] = $date_to . ' 23:59:59';
    
    $query .= " ORDER BY dar.request_date DESC";
    
    $stmt = $central_conn->prepare($query);
    
    // Bind parameters
    for ($i = 0; $i < count($params); $i++) {
        $stmt->bindParam($i + 1, $params[$i]);
    }
    
    $stmt->execute();
    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get deletion requests
    $deletion_stmt = $central_conn->prepare("
        SELECT u.user_id, u.email, u.username, u.data_deletion_date
        FROM Users u
        WHERE u.data_deletion_requested = TRUE
        ORDER BY u.data_deletion_date DESC
    ");
    $deletion_stmt->execute();
    $deletion_requests = $deletion_stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get compliance statistics
    $stats = getComplianceStats($central_conn, $date_from, $date_to);
    
} catch (PDOException $e) {
    $message = "Database error: " . $e->getMessage();
    $requests = [];
    $deletion_requests = [];
    $stats = [];
}

/**
 * Get GDPR compliance statistics
 */
function getComplianceStats($conn, $date_from, $date_to) {
    // Create stats array
    $stats = [
        'total_requests' => 0,
        'pending_requests' => 0,
        'fulfilled_requests' => 0,
        'deletion_requests' => 0,
        'access_requests' => 0,
        'avg_response_time' => 0,
        'service_breakdown' => [
            'computing' => 0,
            'uchennamdi' => 0,
            'publishing' => 0,
            'all' => 0
        ]
    ];
    
    try {
        // Total requests
        $stmt = $conn->prepare("
            SELECT COUNT(*) FROM DataAccessRequests
            WHERE request_date BETWEEN ? AND ?
        ");
        $stmt->bindParam(1, $date_from . ' 00:00:00');
        $stmt->bindParam(2, $date_to . ' 23:59:59');
        $stmt->execute();
        $stats['total_requests'] = $stmt->fetchColumn();
        
        // Pending requests
        $stmt = $conn->prepare("
            SELECT COUNT(*) FROM DataAccessRequests
            WHERE status IN ('pending', 'processing')
            AND request_date BETWEEN ? AND ?
        ");
        $stmt->bindParam(1, $date_from . ' 00:00:00');
        $stmt->bindParam(2, $date_to . ' 23:59:59');
        $stmt->execute();
        $stats['pending_requests'] = $stmt->fetchColumn();
        
        // Fulfilled requests
        $stmt = $conn->prepare("
            SELECT COUNT(*) FROM DataAccessRequests
            WHERE status = 'fulfilled'
            AND request_date BETWEEN ? AND ?
        ");
        $stmt->bindParam(1, $date_from . ' 00:00:00');
        $stmt->bindParam(2, $date_to . ' 23:59:59');
        $stmt->execute();
        $stats['fulfilled_requests'] = $stmt->fetchColumn();
        
        // Deletion requests
        $stmt = $conn->prepare("
            SELECT COUNT(*) FROM Users
            WHERE data_deletion_requested = TRUE
            AND data_deletion_date BETWEEN ? AND ?
        ");
        $stmt->bindParam(1, $date_from . ' 00:00:00');
        $stmt->bindParam(2, $date_to . ' 23:59:59');
        $stmt->execute();
        $stats['deletion_requests'] = $stmt->fetchColumn();
        
        // Average response time
        $stmt = $conn->prepare("
            SELECT AVG(TIMESTAMPDIFF(HOUR, request_date, fulfilled_date)) 
            FROM DataAccessRequests
            WHERE status = 'fulfilled'
            AND request_date BETWEEN ? AND ?
            AND fulfilled_date IS NOT NULL
        ");
        $stmt->bindParam(1, $date_from . ' 00:00:00');
        $stmt->bindParam(2, $date_to . ' 23:59:59');
        $stmt->execute();
        $avg_hours = $stmt->fetchColumn();
        $stats['avg_response_time'] = $avg_hours ? round($avg_hours, 2) : 0;
        
        // Service breakdown
        $stmt = $conn->prepare("
            SELECT services, COUNT(*) as count
            FROM DataAccessRequests
            WHERE request_date BETWEEN ? AND ?
            GROUP BY services
        ");
        $stmt->bindParam(1, $date_from . ' 00:00:00');
        $stmt->bindParam(2, $date_to . ' 23:59:59');
        $stmt->execute();
        $service_breakdown = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($service_breakdown as $item) {
            if ($item['services'] === 'computing') {
                $stats['service_breakdown']['computing'] = $item['count'];
            } elseif ($item['services'] === 'uchennamdi') {
                $stats['service_breakdown']['uchennamdi'] = $item['count'];
            } elseif ($item['services'] === 'publishing') {
                $stats['service_breakdown']['publishing'] = $item['count'];
            } elseif ($item['services'] === 'all') {
                $stats['service_breakdown']['all'] = $item['count'];
            }
        }
        
        return $stats;
        
    } catch (PDOException $e) {
        return $stats;
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OBINexus - GDPR Admin Dashboard</title>
    <link rel="stylesheet" href="../assets/css/admin.css">
</head>
<body>
    <?php include('../includes/admin-header.php'); ?>
    
    <main class="container">
        <h1>GDPR Compliance Dashboard</h1>
        
        <?php if (!empty($message)): ?>
            <div class="alert <?php echo (strpos($message, 'Error') !== false) ? 'alert-danger' : 'alert-success'; ?>">
                <?php echo $message; ?>
            </div>
        <?php endif; ?>
        
        <section class="dashboard-summary">
            <h2>Compliance Summary</h2>
            
            <div class="summary-cards">
                <div class="card">
                    <h3>Total Requests</h3>
                    <p class="big-number"><?php echo $stats['total_requests']; ?></p>
                </div>
                
                <div class="card">
                    <h3>Pending Requests</h3>
                    <p class="big-number"><?php echo $stats['pending_requests']; ?></p>
                </div>
                
                <div class="card">
                    <h3>Deletion Requests</h3>
                    <p class="big-number"><?php echo $stats['deletion_requests']; ?></p>
                </div>
                
                <div class="card">
                    <h3>Avg. Response Time</h3>
                    <p class="big-number"><?php echo $stats['avg_response_time']; ?> hrs</p>
                </div>
            </div>
        </section>
        
        <section class="filters">
            <h2>Filter Requests</h2>
            
            <form method="get" action="" class="filter-form">
                <div class="form-group">
                    <label for="status">Status:</label>
                    <select name="status" id="status">
                        <option value="all" <?php echo $status_filter === 'all' ? 'selected' : ''; ?>>All</option>
                        <option value="pending" <?php echo $status_filter === 'pending' ? 'selected' : ''; ?>>Pending</option>
                        <option value="processing" <?php echo $status_filter === 'processing' ? 'selected' : ''; ?>>Processing</option>
                        <option value="fulfilled" <?php echo $status_filter === 'fulfilled' ? 'selected' : ''; ?>>Fulfilled</option>
                        <option value="denied" <?php echo $status_filter === 'denied' ? 'selected' : ''; ?>>Denied</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="date_from">From:</label>
                    <input type="date" name="date_from" id="date_from" value="<?php echo $date_from; ?>">
                </div>
                
                <div class="form-group">
                    <label for="date_to">To:</label>
                    <input type="date" name="date_to" id="date_to" value="<?php echo $date_to; ?>">
                </div>
                
                <button type="submit" class="btn btn-primary">Apply Filters</button>
            </form>
        </section>
        
        <section class="pending-requests">
            <h2>Data Access Requests</h2>
            
            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>User</th>
                        <th>Email</th>
                        <th>Request Date</th>
                        <th>Services</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($requests)): ?>
                        <tr>
                            <td colspan="7" class="text-center">No requests found matching your criteria.</td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($requests as $request): ?>
                            <tr>
                                <td><?php echo $request['request_id']; ?></td>
                                <td><?php echo htmlspecialchars($request['username']); ?></td>
                                <td><?php echo htmlspecialchars($request['email']); ?></td>
                                <td><?php echo date('Y-m-d H:i', strtotime($request['request_date'])); ?></td>
                                <td><?php echo htmlspecialchars($request['services']); ?></td>
                                <td>
                                    <span class="status-badge status-<?php echo strtolower($request['status']); ?>">
                                        <?php echo ucfirst($request['status']); ?>
                                    </span>
                                </td>
                                <td>
                                    <?php if ($request['status'] === 'pending'): ?>
                                        <form method="post" action="" class="inline-form">
                                            <input type="hidden" name="request_id" value="<?php echo $request['request_id']; ?>">
                                            <input type="hidden" name="action" value="fulfill_access">
                                            <button type="submit" name="process_request" class="btn btn-sm btn-success">Fulfill</button>
                                        </form>
                                        
                                        <form method="post" action="" class="inline-form">
                                            <input type="hidden" name="request_id" value="<?php echo $request['request_id']; ?>">
                                            <input type="hidden" name="action" value="deny_request">
                                            <button type="submit" name="process_request" class="btn btn-sm btn-danger">Deny</button>
                                        </form>
                                    <?php else: ?>
                                        <a href="gdpr-request-details.php?id=<?php echo $request['request_id']; ?>" class="btn btn-sm btn-primary">View Details</a>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </section>
        
        <section class="deletion-requests">
            <h2>Account Deletion Requests</h2>
            
            <table class="data-table">
                <thead>
                    <tr>
                        <th>User ID</th>
                        <th>Username</th>
                        <th>Email</th>
                        <th>Requested On</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($deletion_requests)): ?>
                        <tr>
                            <td colspan="5" class="text-center">No deletion requests found.</td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($deletion_requests as $request): ?>
                            <tr>
                                <td><?php echo $request['user_id']; ?></td>
                                <td><?php echo htmlspecialchars($request['username']); ?></td>
                                <td><?php echo htmlspecialchars($request['email']); ?></td>
                                <td><?php echo date('Y-m-d H:i', strtotime($request['data_deletion_date'])); ?></td>
                                <td>
                                    <?php 
                                    $now = new DateTime();
                                    $deletion_date = new DateTime($request['data_deletion_date']);
                                    $interval = $now->diff($deletion_date);
                                    $days_ago = $interval->days;
                                    
                                    if ($days_ago < 1) {
                                        echo '<span class="status-badge status-pending">Scheduled</span>';
                                    } elseif ($days_ago < 7) {
                                        echo '<span class="status-badge status-processing">Processing</span>';
                                    } else {
                                        echo '<span class="status-badge status-fulfilled">Completed</span>';
                                    }
                                    ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </section>
        
        <section class="compliance-reporting">
            <h2>Compliance Reporting</h2>
            
            <form method="post" action="" class="report-form">
                <div class="form-group">
                    <label for="report_type">Report Type:</label>
                    <select name="report_type" id="report_type">
                        <option value="summary">Compliance Summary</option>
                        <option value="detailed">Detailed Request Log</option>
                        <option value="deletion">Deletion Audit Log</option>
                        <option value="response_times">Response Time Analysis</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="date_range">Date Range:</label>
                    <select name="date_range" id="date_range">
                        <option value="7">Last 7 Days</option>
                        <option value="30" selected>Last 30 Days</option>
                        <option value="90">Last 90 Days</option>
                        <option value="365">Last Year</option>
                    </select>
                </div>
                
                <button type="submit" name="generate_report" class="btn btn-primary">Generate Report</button>
            </form>
        </section>
    </main>
    
    <?php include('../includes/admin-footer.php'); ?>
    
    <script src="../assets/js/admin.js"></script>
</body>
</html>
