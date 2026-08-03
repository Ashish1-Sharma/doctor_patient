<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    Header('Access-Control-Allow-Origin: *');
    Header('Access-Control-Allow-Methods: POST, OPTIONS');
    Header('Access-Control-Allow-Headers: Content-Type, Authorization');
    exit(0);
}

Header("Access-Control-Allow-Origin: *");
Header("Content-Type: application/json");
Header("Access-Control-Allow-Methods: POST");
Header('Access-Control-Allow-Headers: Content-Type, Authorization');

include_once("../../config/database.php");
include_once("../../models/Dashboard.php");

$database = new Database();
$db       = $database->connect();
$dashboard = new Dashboard($db);
$data     = json_decode(file_get_contents("php://input"));

function sendResponse($statusCode, $message, $body = null)
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message'    => $message,
        'body'       => $body
    ]);
}

if (!isset($data)) {
    sendResponse(400, 'Invalid request: No data received');
    return;
}

if (!isset($data->user_id)) {
    sendResponse(400, "User ID is required");
    return;
}

if (!isset($data->from_date) || !isset($data->to_date)) {
    sendResponse(400, "from_date and to_date are required");
    return;
}

try {
    $result = $dashboard->getSummary($data->user_id, $data->from_date, $data->to_date);

    if ($result) {
        sendResponse(200, "P&L summary fetched successfully", $result);
    } else {
        sendResponse(404, "No data found for the given period");
    }
} catch (Exception $e) {
    sendResponse(500, "Error fetching P&L summary", ['error' => $e->getMessage()]);
}
