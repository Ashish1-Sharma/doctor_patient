<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: PUT, POST');
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

if (isset($data)) {

    $params = [

        'id' => $data->id,
        'parentId' => $data->parentId,
        'profileImage' => $data->profileImage,
        'fullName' => $data->fullName,
        'age' => $data->age,
        'gender' => $data->gender,
        'dateOfBirth' => $data->dateOfBirth,
        'phone' => $data->phone,
        'email' => $data->email,
        'address' => $data->address,
        'medicalConditions' => json_encode($data->medicalConditions),
        'emergencyContactName' => $data->emergencyContactName,
        'emergencyContactPhone' => $data->emergencyContactPhone,
        'status' => $data->status

    ];

    try {

        $updated = $patient->updatePatient($params);

        if ($updated) {

            $responseBody = [

                'id' => $params['id'],
                'parentId' => $params['parentId'],
                'profileImage' => $params['profileImage'],
                'fullName' => $params['fullName'],
                'age' => $params['age'],
                'gender' => $params['gender'],
                'dateOfBirth' => $params['dateOfBirth'],
                'phone' => $params['phone'],
                'email' => $params['email'],
                'address' => $params['address'],
                'medicalConditions' => $data->medicalConditions,
                'emergencyContactName' => $params['emergencyContactName'],
                'emergencyContactPhone' => $params['emergencyContactPhone'],
                'status' => $params['status']

            ];

            sendResponse(200, 'Patient updated successfully', $responseBody);

        } else {

            sendResponse(400, 'Unable to update patient');

        }

    } catch (Exception $e) {

        sendResponse(500, 'Error updating patient', [
            'error' => $e->getMessage()
        ]);

    }

} else {

    sendResponse(400, 'Invalid request: No data received');

}