<?php

error_reporting(E_ALL);
ini_set("display_errors", 1);

// CORS headers
Header("Access-Control-Allow-Origin: http://localhost:5173"); // Replace with your frontend origin
Header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
Header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, sec-ch-ua, sec-ch-ua-mobile, sec-ch-ua-platform");
Header("Access-Control-Allow-Credentials: true"); // Only use if credentials like cookies are sent

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Include required files
include_once("../../config/database.php");
include_once("../../models/company.php");

$database = new Database();
$db = $database->connect();
$company = new Company($db);

$data = json_decode(file_get_contents("php://input"));

// Helper function for response
function sendResponse($statusCode, $message, $body = null) {
    http_response_code($statusCode);
    echo json_encode([
        'statusCode' => $statusCode,
        'message' => $message,
        'body' => $body
    ]);
}

// Validate incoming data
if (isset($data)) {
    $params = [
        "userId" => $data->userId ?? null,
        "companyName" => $data->companyName ?? null,
        "companyAddress" => $data->companyAddress ?? null,
        "clinic_reg_no" => $data->clinic_reg_no ?? null,
        "pollution_control_cert" => $data->pollution_control_cert ?? null,
        "trade_license" => $data->trade_license ?? null,
        "municipality_noc" => $data->municipality_noc ?? null,
        "doctor_reg_cert" => $data->doctor_reg_cert ?? null,
        "terms" => $data->terms ?? null
    ];

    try {
        if (isset($data->id) && !empty($data->id)) {
            $result = $company->update($data->id, $params);
            $message = $result ? "Company updated successfully" : "Failed to update company";
            sendResponse($result ? 200 : 500, $message);
        } else {
            $id = $company->create($params);
            $message = $id ? "Company created successfully" : "Failed to create company";
            sendResponse($id ? 201 : 500, $message, ['id' => $id]);
        }
    } catch (Exception $e) {
        sendResponse(500, "Error processing request", ['error' => $e->getMessage()]);
    }
} else {
    sendResponse(400, "Invalid request: No data received");
}
