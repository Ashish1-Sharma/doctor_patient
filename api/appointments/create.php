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

if (isset($data)) {
    $params = [
        'visitId' => $data->visitId ?? null,
        'patientId' => $data->patientId,
        'doctorId' => $data->doctorId,
        'appointmentDate' => $data->appointmentDate,
        'procedureText' => $data->procedureText ?? 'General Checkup',
        'status' => 'Pending'
    ];

    try {
        $id = $appointment->create($params);
        if ($id > 0) {
            $responseBody = [
                'id' => $id,
                'visitId' => $params['visitId'],
                'patientId' => $params['patientId'],
                'doctorId' => $params['doctorId'],
                'appointmentDate' => $params['appointmentDate'],
                'procedureText' => $params['procedureText'],
                'status' => $params['status']
            ];
            sendResponse(201, 'Appointment created successfully', $responseBody);
        } else {
            sendResponse(400, 'Unable to create appointment');
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error creating appointment', [
            'error' => $e->getMessage()
        ]);
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
