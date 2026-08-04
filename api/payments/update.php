<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

include_once('../../config/database.php');
include_once('../../models/payment.php');

$database = new Database();
$db = $database->connect();

$payment = new Payment($db);
$data = json_decode(file_get_contents("php://input"));

function sendResponse($statusCode, $message, $body = null)
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message' => $message,
        'body' => $body
    ]);
}

if (isset($data) && isset($data->id)) {
    $id = $data->id;
    $paidAmount = $data->paidAmount;
    $pendingAmount = $data->pendingAmount;
    $paymentStatus = $data->paymentStatus;
    $remarks = $data->remarks ?? '';

    try {
        $success = $payment->update($id, $paidAmount, $pendingAmount, $paymentStatus, $remarks);
        if ($success) {
            sendResponse(200, 'Payment details updated successfully');
        } else {
            sendResponse(400, 'Unable to update payment details');
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error updating payment details', [
            'error' => $e->getMessage()
        ]);
    }
} else {
    sendResponse(400, 'Invalid request: id, paidAmount, pendingAmount, and paymentStatus are required');
}
