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

if (isset($data) && isset($data->id)) {
    $params = [
        'appointmentDate' => $data->appointmentDate,
        'procedureText' => $data->procedureText ?? 'General Checkup',
        'status' => $data->status ?? 'Pending'
    ];

    try {
        $result = $appointment->update($data->id, $params);
        if ($result) {
            sendResponse(200, 'Appointment updated successfully');
        } else {
            sendResponse(400, 'Unable to update appointment');
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error updating appointment', [
            'error' => $e->getMessage()
        ]);
    }
} else {
    sendResponse(400, 'Invalid request: appointment ID and details are required');
}
