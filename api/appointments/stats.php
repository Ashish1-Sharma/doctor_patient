<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST, GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

include_once('../../config/database.php');
include_once('../../models/appointment.php');

$database = new Database();
$db = $database->connect();

$appointment = new Appointment($db);
$data = json_decode(file_get_contents("php://input"));

function sendResponse($statusCode, $message, $body = null)
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message' => $message,
        'body' => $body
    ]);
}

$doctorId = $data->doctorId ?? $data->parentId ?? $_GET['doctorId'] ?? $_GET['parentId'] ?? null;

if ($doctorId) {
    try {
        $stats = $appointment->getStatsByDoctorId($doctorId);
        sendResponse(200, 'Appointment stats loaded successfully', $stats);
    } catch (Exception $e) {
        sendResponse(500, 'Error loading appointment stats', [
            'error' => $e->getMessage()
        ]);
    }
} else {
    sendResponse(400, 'Invalid request: doctorId or parentId is required');
}
