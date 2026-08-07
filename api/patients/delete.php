<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

Header('Access-Control-Allow-Origin: *');
Header('Content-Type: application/json');
Header('Access-Control-Allow-Methods: POST');

// Include required files
include_once('../../config/database.php');
include_once('../../models/patient.php');

// Connection with db
$database = new Database();
$db = $database->connect();

$patient = new Patient($db);
$data = json_decode(file_get_contents("php://input"));

function sendResponse($statusCode, $message, $body = null)
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message' => $message,
        'body' => $body
    ]);
}

if (isset($data) && isset($data->id) && isset($data->parentId)) {
    try {
        // Soft delete: set status = 0
        $result = $patient->changeStatus($data->id, $data->parentId, 0);

        if ($result) {
            sendResponse(200, 'Patient and associated records deleted successfully');
        } else {
            sendResponse(500, 'Failed to delete patient');
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error deleting patient', ['error' => $e->getMessage()]);
    }
} else {
    sendResponse(400, 'Invalid request: id and parentId are required');
}
