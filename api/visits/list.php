<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

include_once('../../config/database.php');
include_once('../../models/visit.php');

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

if (isset($data->parentId) && isset($data->patientId)) {

    try {

        $result = $visit->getVisits(
            $data->parentId,
            $data->patientId
        );

        if ($result->rowCount() > 0) {

            $visits = [];

            while ($row = $result->fetch(PDO::FETCH_ASSOC)) {

                $visits[] = [
                    'id' => $row['id'],
                    'visitNo' => $row['visit_no'],
                    'visitDate' => $row['visit_date'],
                    'treatmentDone' => $row['treatment_done_text'],
                    'nextAppointmentDate' => $row['next_appointment_date'],
                    'status' => $row['status']
                ];

            }

            sendResponse(
                200,
                'Visits fetched successfully',
                $visits
            );

        } else {

            sendResponse(
                200,
                'No visits found',
                []
            );

        }

    } catch (Exception $e) {

        sendResponse(
            500,
            'Error fetching visits',
            [
                'error' => $e->getMessage()
            ]
        );

    }

} else {

    sendResponse(
        400,
        'parentId and patientId are required'
    );

}