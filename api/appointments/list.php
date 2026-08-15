<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
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

$targetId = $data->doctorId ?? $data->parentId ?? null;

if (isset($data) && $targetId) {
    try {
        $range = $data->range ?? 'all';
        $from = $data->from ?? null;
        $to = $data->to ?? null;

        if ($range === 'all') {
            $list = $appointment->getByDoctorIdAndRange($targetId, 'all');
        } else {
            $list = $appointment->getByDoctorIdAndRange($targetId, $range, $from, $to);
        }

        sendResponse(200, 'Appointments loaded successfully', $list);
    } catch (Exception $e) {
        sendResponse(500, 'Error loading appointments', [
            'error' => $e->getMessage()
        ]);
    }
} else {
    sendResponse(400, 'Invalid request: doctorId or parentId is required');
}
