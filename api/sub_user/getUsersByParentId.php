<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');

// Include required files
include_once('../../config/database.php');
include_once('../../models/user.php');

// Connect to the database
$database = new Database();
$db = $database->connect();

// Create an instance of the Users model
$userModel = new Users($db);

// Function to standardize responses
function sendResponse($statusCode, $message, $body = null)
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message'    => $message,
        'body'       => $body
    ]);
}

// Check if 'parentId' parameter is provided
if (isset($_GET['parentId'])) {
    $params = ['parentId' => $_GET['parentId']];

    try {
        // Use the getUsersByParentId method; it returns an array of users or false if none found.
        $users = $userModel->getUsersByParentId($params);

        if ($users !== false) {
            sendResponse(200, 'Users fetched successfully', $users);
        } else {
            sendResponse(404, 'No users found for the given parentId', []);
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error fetching users', ['error' => $e->getMessage()]);
    }
} else {
    sendResponse(400, 'parentId parameter is required');
}
