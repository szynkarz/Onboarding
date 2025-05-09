<?php
// Set header
header('Content-Type: text/html; charset=utf-8');

// Basic environment check function
function checkEnvironment() {
    $checks = [
        'PHP Version' => phpversion(),
        'Server Software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
        'Database Connected' => checkDatabaseConnection() ? 'Yes' : 'No',
        'Operating System' => PHP_OS,
        'Server Time' => date('Y-m-d H:i:s'),
        'Server Timezone' => date_default_timezone_get(),
        'Server IP' => $_SERVER['SERVER_ADDR'] ?? 'Unknown',
        'Client IP' => $_SERVER['REMOTE_ADDR'] ?? 'Unknown',
        'Memory Limit' => ini_get('memory_limit'),
        'Post Max Size' => ini_get('post_max_size'),
        'Upload Max Filesize' => ini_get('upload_max_filesize'),
    ];
    
    return $checks;
}

// Check if we can connect to the database
function checkDatabaseConnection() {
    $host = getenv('DB_HOST');
    $username = getenv('DB_USER');
    $password = getenv('DB_PASSWORD');
    $dbname = getenv('DB_NAME');
    
    if (!$host || !$username || !$password || !$dbname) {
        return false;
    }
    
    try {
        $conn = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        // Simple query to test connection
        $stmt = $conn->query('SELECT 1');
        return true;
    } catch (PDOException $e) {
        return false;
    }
}

// Get system resource usage
function getSystemInfo() {
    $memInfo = [];
    
    if (function_exists('sys_getloadavg')) {
        $memInfo['Load Average'] = implode(', ', sys_getloadavg());
    }
    
    if (function_exists('memory_get_usage')) {
        $memInfo['Memory Usage'] = formatBytes(memory_get_usage());
    }
    
    if (function_exists('memory_get_peak_usage')) {
        $memInfo['Peak Memory Usage'] = formatBytes(memory_get_peak_usage());
    }
    
    return $memInfo;
}

// Format bytes to human-readable format
function formatBytes($bytes, $precision = 2) {
    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
    
    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($units) - 1);
    
    $bytes /= pow(1024, $pow);
    
    return round($bytes, $precision) . ' ' . $units[$pow];
}

// Get environment variables (filtering sensitive ones)
function getEnvironmentVariables() {
    $env = [];
    foreach ($_ENV as $key => $value) {
        // Skip sensitive environment variables
        if (!preg_match('/(password|key|secret|token)/i', $key)) {
            $env[$key] = $value;
        }
    }
    
    foreach ($_SERVER as $key => $value) {
        if (strpos($key, 'AWS_') === 0 || strpos($key, 'EB_') === 0) {
            if (!preg_match('/(password|key|secret|token)/i', $key)) {
                $env[$key] = $value;
            }
        }
    }
    
    return $env;
}

// Get installed extensions
function getExtensions() {
    return implode(', ', get_loaded_extensions());
}


// Main execution
$envChecks = checkEnvironment();
$sysInfo = getSystemInfo();
$envVars = getEnvironmentVariables();
$extensions = getExtensions();
$dbTest = checkDatabaseConnection();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP on AWS Elastic Beanstalk</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        header {
            background-color: #232f3e;
            color: white;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        h1 {
            margin: 0;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 3px;
            color: white;
            font-weight: bold;
        }
        .status-ok {
            background-color: #2ecc71;
        }
        .status-warning {
            background-color: #f39c12;
        }
        .status-error {
            background-color: #e74c3c;
        }
        .card {
            background-color: #f9f9f9;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        footer {
            margin-top: 30px;
            text-align: center;
            color: #777;
            font-size: 0.8em;
        }
    </style>
</head>
<body>
    <header>
        <h1>PHP on AWS Elastic Beanstalk</h1>
        <p>A simple status page to verify your PHP application is running</p>
    </header>
    
    <div class="card">
        <h2>Environment Status</h2>
        <p>
            <?php if (checkDatabaseConnection()): ?>
                <span class="status-badge status-ok">All Systems Operational</span>
            <?php else: ?>
                <span class="status-badge status-warning">Database Connection Issue</span>
            <?php endif; ?>
        </p>
        <table>
            <tr>
                <th>Check</th>
                <th>Value</th>
            </tr>
            <?php foreach ($envChecks as $check => $value): ?>
            <tr>
                <td><?= htmlspecialchars($check) ?></td>
                <td><?= htmlspecialchars($value) ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
    
    <div class="card">
        <h2>System Resources</h2>
        <table>
            <tr>
                <th>Metric</th>
                <th>Value</th>
            </tr>
            <?php foreach ($sysInfo as $metric => $value): ?>
            <tr>
                <td><?= htmlspecialchars($metric) ?></td>
                <td><?= htmlspecialchars($value) ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
    
    <div class="card">
        <h2>Database Test</h2>
        <p><?= htmlspecialchars($dbTest) ?></p>
    </div>
    
    <div class="card">
        <h2>PHP Extensions</h2>
        <p><?= htmlspecialchars($extensions) ?></p>
    </div>
    
    <div class="card">
        <h2>Environment Variables</h2>
        <table>
            <tr>
                <th>Variable</th>
                <th>Value</th>
            </tr>
            <?php foreach ($envVars as $name => $value): ?>
            <tr>
                <td><?= htmlspecialchars($name) ?></td>
                <td><?= htmlspecialchars($value) ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
    
    <footer>
        <p>PHP Version: <?= phpversion() ?> | Generated at: <?= date('Y-m-d H:i:s') ?></p>
        <p>Running on AWS Elastic Beanstalk</p>
    </footer>
</body>
</html>