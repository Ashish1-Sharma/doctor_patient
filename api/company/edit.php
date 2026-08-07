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
function sendResponse($statusCode, $message, $body = null)
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message' => $message,
        'body' => $body
    ]);
}

if (isset($data)) {
    // Ensure the required field 'id' is provided for the update
    if (!isset($data->id)) {
        sendResponse(400, "Invalid request: Missing company ID");
        exit;
    }

    // Collect fields from the request
    $params = [
        "userId" => $data->userId,
        "companyName" => $data->companyName,
        "companyAddress" => $data->companyAddress,
        "clinic_reg_no" => isset($data->clinic_reg_no) && !empty($data->clinic_reg_no) ? $data->clinic_reg_no : null,
        "pollution_control_cert" => isset($data->pollution_control_cert) && !empty($data->pollution_control_cert) ? $data->pollution_control_cert : null,
        "trade_license" => isset($data->trade_license) && !empty($data->trade_license) ? $data->trade_license : null,
        "municipality_noc" => isset($data->municipality_noc) && !empty($data->municipality_noc) ? $data->municipality_noc : null,
        "doctor_reg_cert" => isset($data->doctor_reg_cert) && !empty($data->doctor_reg_cert) ? $data->doctor_reg_cert : null,
        "terms" => isset($data->terms) && !empty($data->terms) ? $data->terms : null
    ];

    try {
        // Call the update method from the Company model
        $isUpdated = $company->update($data->id, $params);

        if ($isUpdated) {
            sendResponse(200, "Company updated successfully");
        } else {
            sendResponse(500, "Failed to update company");
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error processing request', ['error' => $e->getMessage()]);
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
