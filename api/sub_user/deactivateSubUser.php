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
        $userResult = $user->deactivateUser($data->id, $data->status);

        if ($userResult) {

            sendResponse(200, 'Profile successfully updated');
        } else {
            sendResponse(401, 'No data found');
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error ', ['error' => $e->getMessage()]);
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
