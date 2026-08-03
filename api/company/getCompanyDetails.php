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
include_once("../../models/company.php");

// Connection with database
$database = new Database();
$db = $database->connect();

$company = new Company($db);
$data = json_decode(file_get_contents("php://input"));

// Function to send a consistent response
function sendResponse($statusCode, $message, $body = [])
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message' => $message,
        'body' => $body
    ]);
}



if (isset($data)) {

    if (!isset($data->userId)) {
        sendResponse(400, "Id is required to fetch company");
        return;
    }

    try {
        $companyItems = $company->getByUserId($data->userId);

        if ($companyItems) {
            sendResponse(200, "company fetched successfully", $companyItems);
        } else {
            sendResponse(404, "No company found for the user");
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error fetching company', ['error' => $e->getMessage()]);
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
