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

// Required fields
$required = [
    'userName',
    'userEmail',
    'country',
    'countryCode',
    'userMobile',
    'password',
    'reg_date',
    'validity',
    'purchase_date',
    'purchase_id'
];

foreach ($required as $field) {
    if (!isset($data->$field) || trim($data->$field) == "") {
        sendResponse(400, "$field is required");
    }
}

// Append country code
$userMobile = $data->countryCode . " " . $data->userMobile;

// Check duplicate email
$check = $db->prepare("SELECT id FROM registration WHERE userEmail = ?");
$check->execute([$data->userEmail]);

if ($check->rowCount() > 0) {
    sendResponse(409, "Email already registered");
}

// Check duplicate mobile
$check = $db->prepare("SELECT id FROM registration WHERE userMobile = ?");
$check->execute([$userMobile]);

if ($check->rowCount() > 0) {
    sendResponse(409, "Mobile already registered");
}

try {

    $sql = "INSERT INTO registration
    (
        userName,
        userEmail,
        userMobile,
        country,
        password,
        reg_date,
        validity,
        purchase_date,
        purchase_id,
        flag
    )
    VALUES
    (
        :userName,
        :userEmail,
        :userMobile,
        :country,
        :password,
        :reg_date,
        :validity,
        :purchase_date,
        :purchase_id,
        :flag
    )";

    $stmt = $db->prepare($sql);

    $stmt->execute([
        ":userName"       => $data->userName,
        ":userEmail"      => $data->userEmail,
        ":userMobile"     => $userMobile,
        ":country"        => $data->country,
        ":password"       => $data->password, // No hashing
        ":reg_date"       => $data->reg_date,
        ":validity"       => $data->validity,
        ":purchase_date"  => $data->purchase_date,
        ":purchase_id"    => $data->purchase_id,
        ":flag"           => isset($data->flag) ? $data->flag : 0
    ]);

    $id = $db->lastInsertId();

    sendResponse(201, "User registered successfully", [
        "id" => $id,
        "userName" => $data->userName,
        "userEmail" => $data->userEmail,
        "country" => $data->country,
        "userMobile" => $userMobile,
        "validity" => $data->validity,
        "purchase_id" => $data->purchase_id
    ]);

} catch (PDOException $e) {

    sendResponse(500, "Registration failed", [
        "error" => $e->getMessage()
    ]);
}