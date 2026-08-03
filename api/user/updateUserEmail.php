<?php

error_reporting(E_ALL);
ini_set("display_errors", 1);

// Handle OPTIONS request (CORS Preflight)
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    Header('Access-Control-Allow-Origin: *');  // Or specify the exact origin here
    Header('Access-Control-Allow-Methods: POST, OPTIONS');
    Header('Access-Control-Allow-Headers: Content-Type, Authorization');
    exit(0);  // End preflight request here
}

// CORS headers for other requests
Header("Access-Control-Allow-Origin: *");  // Or specify the exact origin here
Header("Content-Type: application/json");
Header("Access-Control-Allow-Methods: POST");
Header('Access-Control-Allow-Headers: Content-Type, Authorization'); // Allow Content-Type and Authorization headers

// Include required files
include_once('../../config/database.php');
include_once('../../models/user.php');

// Connection with db
$database = new Database();
$db = $database->connect();

$user = new Users($db);
$data = json_decode(file_get_contents("php://input"));

function sendResponse($statusCode, $message, $body = null)
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message' => $message,
        'body' => $body
    ]);
}

if (isset($data)) {
    try {
        $user->updateEmail($data->currentEmail, $data->newEmail);
        sendResponse(200, 'Email updated successfully');
    } catch (Exception $e) {
        sendResponse(400, $e->getMessage());
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
