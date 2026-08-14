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

if (isset($data) && isset($data->id) && isset($data->parentId)) {

    $params = [
        'id' => $data->id,
        'parentId' => $data->parentId,

        'chiefComplaintText' => $data->chiefComplaintText ?? '',
        'chiefComplaintImages' => json_encode($data->chiefComplaintImages ?? []),

        'clinicalFindingsText' => $data->clinicalFindingsText ?? '',
        'clinicalFindingsImages' => json_encode($data->clinicalFindingsImages ?? []),

        'labText' => $data->labText ?? '',
        'labImages' => json_encode($data->labImages ?? []),

        'advisedTreatmentText' => $data->advisedTreatmentText ?? '',
        'advisedTreatmentImages' => json_encode($data->advisedTreatmentImages ?? []),

        'treatmentDoneText' => $data->treatmentDoneText ?? '',
        'treatmentDoneImages' => json_encode($data->treatmentDoneImages ?? []),

        'medicationText' => $data->medicationText ?? '',
        'medicationImages' => json_encode($data->medicationImages ?? []),

        'nextAppointmentDate' => $data->nextAppointmentDate ?? null,
        'notes' => $data->notes ?? '',

        'status' => $data->status ?? 1
    ];

    try {

        $success = $visit->updateVisit($params);

        if ($success) {

            sendResponse(
                200,
                'Visit updated successfully',
                [
                    'id' => $params['id'],
                    'parentId' => $params['parentId']
                ]
            );

        } else {

            sendResponse(400, 'Unable to update visit');

        }

    } catch (Exception $e) {

        sendResponse(
            500,
            'Error updating visit',
            [
                'error' => $e->getMessage()
            ]
        );

    }

} else {

    sendResponse(400, 'Invalid request: id and parentId are required');

}
