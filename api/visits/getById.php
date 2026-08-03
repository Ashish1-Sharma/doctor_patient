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

if (isset($data->parentId) && isset($data->visitId)) {

    try {

        $result = $visit->getVisitById(
            $data->parentId,
            $data->visitId
        );

        if ($result->rowCount() > 0) {

            $row = $result->fetch(PDO::FETCH_ASSOC);

            $row['chief_complaint_images'] = !empty($row['chief_complaint_images'])
                ? json_decode($row['chief_complaint_images'], true)
                : [];

            $row['clinical_findings_images'] = !empty($row['clinical_findings_images'])
                ? json_decode($row['clinical_findings_images'], true)
                : [];

            $row['lab_images'] = !empty($row['lab_images'])
                ? json_decode($row['lab_images'], true)
                : [];

            $row['advised_treatment_images'] = !empty($row['advised_treatment_images'])
                ? json_decode($row['advised_treatment_images'], true)
                : [];

            $row['treatment_done_images'] = !empty($row['treatment_done_images'])
                ? json_decode($row['treatment_done_images'], true)
                : [];

            $row['medication_images'] = !empty($row['medication_images'])
                ? json_decode($row['medication_images'], true)
                : [];

            sendResponse(
                200,
                'Visit fetched successfully',
                $row
            );

        } else {

            sendResponse(
                404,
                'Visit not found'
            );

        }

    } catch (Exception $e) {

        sendResponse(
            500,
            'Error fetching visit',
            [
                'error' => $e->getMessage()
            ]
        );

    }

} else {

    sendResponse(
        400,
        'parentId and visitId are required'
    );

}