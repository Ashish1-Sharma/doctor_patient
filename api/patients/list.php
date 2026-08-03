<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

include_once('../../config/database.php');
include_once('../../models/patient.php');

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

if (isset($data->parentId)) {

    try {

        $result = $patient->getPatients($data->parentId);

        if ($result->rowCount() > 0) {

            $patients = [];

            while ($row = $result->fetch(PDO::FETCH_ASSOC)) {

                $row['medical_conditions'] = !empty($row['medical_conditions'])
                    ? json_decode($row['medical_conditions'], true)
                    : [];

                $patients[] = $row;
            }

            sendResponse(200, 'Patients fetched successfully', $patients);

        } else {

            sendResponse(200, 'No patients found', []);

        }

    } catch (Exception $e) {

        sendResponse(500, 'Error fetching patients', [
            'error' => $e->getMessage()
        ]);

    }

} else {

    sendResponse(400, 'parentId is required');

}