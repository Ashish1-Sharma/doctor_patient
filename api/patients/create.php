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

if (isset($data)) {

    $params = [

        'parentId' => $data->parentId,
        'patientCode' => $data->patientCode,
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
        'totalVisits' => 0,
        'lastVisitDate' => null,
        'createdBy' => $data->createdBy,
        'status' => 1

    ];

    try {

        $id = $patient->createPatient($params);

        if ($id > 0) {

            $responseBody = [

                'id' => $id,
                'parentId' => $params['parentId'],
                'patientCode' => $params['patientCode'],
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
                'totalVisits' => 0,
                'lastVisitDate' => null,
                'createdBy' => $params['createdBy'],
                'status' => 1

            ];

            sendResponse(201, 'Patient created successfully', $responseBody);

        } else {

            sendResponse(400, 'Unable to create patient');

        }

    } catch (Exception $e) {

        sendResponse(500, 'Error creating patient', [
            'error' => $e->getMessage()
        ]);

    }

} else {

    sendResponse(400, 'Invalid request: No data received');

}