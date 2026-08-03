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
include_once("../../config/database.php");
include_once("../../models/settings.php");

// Connection with database
$database = new Database();
$db = $database->connect();

$settings = new Settings($db);
$data = json_decode(file_get_contents("php://input"));

// Function to send a consistent response
function sendResponse($statusCode, $message, $body = null)
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message' => $message,
        'body' => $body
    ]);
}



if (isset($data)) {

    if (!isset($data->id)) {
        sendResponse(400, "Settings ID is required for updating");
        return;
    }

    $params = [
        "id" => $data->id,
        "userId" => $data->userId,
        "months" => $data->months,
        "count" => $data->count,
 	"gst" => $data->gst
    ];

    try {
        $updated = $settings->updateRecord($data->id, $params);

        if ($updated) {
            sendResponse(200, "Stock item updated successfully");
        } else {
            sendResponse(500, "Failed to update stock item");
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error updating stock', ['error' => $e->getMessage()]);
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
