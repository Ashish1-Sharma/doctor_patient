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
    $params = [
        'parentEmail' => $data->parentEmail,
        'childEmail' => $data->childEmail,
        'inputPassword' => $data->inputPassword,
    ];

    try {
        $userResult = $user->subUserLogin($params);

        if ($userResult) {
            // Create a response body
            $responseBody = [
                'id' => $userResult['id'],
                'userEmail' => $userResult['userEmail'],
                'country' => $userResult['country'] ?? null,
                'userName' => $userResult['userName'],
                'userMobile' => $userResult['userMobile'],
                'reg_date' => $userResult['reg_date'],
                'validity' => $userResult['validity'],
                'purchase_date' => $userResult['purchase_date'],
                'purchase_id' => $userResult['purchase_id'],
                'parentId' => $userResult['parentId'],
                'flag' => $userResult['flag']
            ];

            sendResponse(200, 'Login successful', $responseBody);
        } else {
            sendResponse(401, 'Invalid email/mobile or password');
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error during login', ['error' => $e->getMessage()]);
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
