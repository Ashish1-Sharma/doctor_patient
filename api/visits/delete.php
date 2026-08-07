<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

Header('Access-Control-Allow-Origin: *');
Header('Content-Type: application/json');
Header('Access-Control-Allow-Methods: POST');

// Include required files
include_once('../../config/database.php');
include_once('../../models/visit.php');

// Connection with db
$database = new Database();
$db = $database->connect();

$visit = new Visit($db);
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
        $result = $visit->deleteVisit($data->id, $data->parentId);

        if ($result) {
            sendResponse(200, 'Visit and associated records deleted successfully');
        } else {
            sendResponse(500, 'Failed to delete visit');
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error deleting visit', ['error' => $e->getMessage()]);
    }
} else {
    sendResponse(400, 'Invalid request: id and parentId are required');
}
