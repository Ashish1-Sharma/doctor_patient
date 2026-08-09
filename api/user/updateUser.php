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
        $password = (isset($data->password) && trim($data->password) !== '') ? $data->password : null; // Check if password is provided

        $userResult = $user->updateUser($data->id, $data->name, $data->email, $data->mobile, $data->country, $password);

        if ($userResult['success']) {
            $updatedUser = $user->getUserById($data->id);
            if ($updatedUser) {
                $responseBody = [
                    'id' => $updatedUser['id'],
                    'userEmail' => $updatedUser['userEmail'],
                    'country' => $updatedUser['country'] ?? null,
                    'userName' => $updatedUser['userName'],
                    'userMobile' => $updatedUser['userMobile'],
                    'reg_date' => $updatedUser['reg_date'],
                    'password' => $updatedUser['password'],
                    'validity' => $updatedUser['validity'],
                    'purchase_date' => $updatedUser['purchase_date'],
                    'purchase_id' => $updatedUser['purchase_id'],
                    'parentId' => $updatedUser['parentId'],
                    'access_key' => $updatedUser['access_key'],
                    'flag' => $updatedUser['flag']
                ];
                sendResponse(200, $userResult['message'], $responseBody);
            } else {
                sendResponse(200, $userResult['message']);
            }
        } else {
            sendResponse(400, $userResult['message']);
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error updating user', ['error' => $e->getMessage()]);
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
