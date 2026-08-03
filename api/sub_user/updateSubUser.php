<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

Header('Access-Control-Allow-Origin: *');
Header('Content-Type: application/json');
Header('Access-Control-Allow-Methods: POST');

// Include required files
include_once('../../config/database.php');
include_once('../../models/user.php');

// Connection with db
$database = new Database();
$db = $database->connect();

$existingUser = new Users($db);
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
        $result = $existingUser->updateSubUser($data->parentEmail, $data->id, $data->email, $data->password);

        if ($result) {
            sendResponse(200, 'User updated successfully');
        }
    } catch (Exception $e) {
        // Handle duplicate entry specifically
        if (strpos($e->getMessage(), 'Duplicate entry') !== false) {
            sendResponse(409, 'Duplicate Entry', ['error' => $e->getMessage()]);
        } else {
            sendResponse(500, 'Error in user update', ['error' => $e->getMessage()]);
        }
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
