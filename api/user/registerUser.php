<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

Header('Access-Control-Allow-Origin: *');
Header('Content-Type: application/json');
Header('Access-Control-Allow-Methods: POST');
Header('Access-Control-Allow-Headers: Content-Type, Authorization'); // Allow Content-Type and Authorization headers


// Include required files
include_once('../../config/database.php');
include_once('../../models/user.php');

// Connection with db
$database = new Database();
$db = $database->connect();

$existingUser = new Users($db);
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
    $data->userMobile = $data->countryCode . " " . $data->userMobile;

    $existingUser = $existingUser->getUserByEmailOrMobile($data->userEmail, $data->userMobile);

    if ($existingUser->rowCount()) {
        sendResponse(400, 'User already exists');
    } else {
        $user = new Users($db);

        $params = [
            'userName' => $data->userName,
            'userEmail' => $data->userEmail,
            'country' => $data->country,
            'userMobile' => $data->userMobile,
            'password' => $data->password,
            'reg_date' => $data->reg_date,
            'validity' => $data->validity,
            'purchase_date' => $data->purchase_date,
            'purchase_id' => $data->purchase_id,
            'flag' => $data->flag
        ];

        try {
            $id = $user->registerUser($params);

            $responseBody = [
                'id' => $id,
                'userName' => $data->userName,
                'userEmail' => $data->userEmail,
                'country' => $data->country,
                'userMobile' => $data->userMobile,
                'reg_date' => $data->reg_date,
                'validity' => $data->validity,
              	'password' => $data->password,
		        'purchase_date' => $data->purchase_date,
                'purchase_id' => $data->purchase_id,
                'flag' => $data->flag
            ];

            sendResponse(201, 'User registered successfully', $responseBody);
        } catch (PDOException $e) {
            sendResponse(500, 'Error in user registration', ['error' => $e->getMessage()]);
        }
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
