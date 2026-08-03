<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST");

include_once('../../config/database.php');

$database = new Database();
$db = $database->connect();

function sendResponse($statusCode, $message, $body = null)
{
    http_response_code($statusCode);

    echo json_encode([
        "statusCode" => $statusCode,
        "message" => $message,
        "body" => $body
    ]);
    exit;
}

$data = json_decode(file_get_contents("php://input"));

if (!$data) {
    sendResponse(400, "Invalid request");
}

// Validate request
if (
    !isset($data->userEmailMobile) || trim($data->userEmailMobile) == "" ||
    !isset($data->password) || trim($data->password) == ""
) {
    sendResponse(400, "Email/Mobile and Password are required");
}

try {

    // Search by Email OR Mobile
    $sql = "SELECT
                id,
                userName,
                userEmail,
                userMobile,
                country,
                password,
                reg_date,
                validity,
                purchase_date,
                purchase_id,
                flag,
                parentId,
                status,
                access_key
            FROM registration
            WHERE userEmail = :value
               OR userMobile = :value
            LIMIT 1";

    $stmt = $db->prepare($sql);
    $stmt->bindValue(":value", trim($data->userEmailMobile));
    $stmt->execute();

    if ($stmt->rowCount() == 0) {
        sendResponse(401, "Invalid email/mobile or password");
    }

    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // Compare plain text password
    if ($user['password'] != $data->password) {
        sendResponse(401, "Invalid email/mobile or password");
    }

    // Check account status
    if ($user['status'] != 1) {
        sendResponse(403, "Account is inactive");
    }

    // Remove password before sending response
    unset($user['password']);

    sendResponse(200, "Login successful", $user);

} catch (PDOException $e) {

    sendResponse(500, "Login failed", [
        "error" => $e->getMessage()
    ]);
}