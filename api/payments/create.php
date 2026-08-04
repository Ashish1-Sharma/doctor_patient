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

if (isset($data)) {
    $params = [
        'parentId' => $data->parentId,
        'visitId' => $data->visitId,
        'patientId' => $data->patientId,
        'invoiceNo' => $data->invoiceNo,
        'subtotal' => $data->subtotal ?? 0.0,
        'discount' => $data->discount ?? 0.0,
        'totalAmount' => $data->totalAmount,
        'paidAmount' => $data->paidAmount ?? 0.0,
        'pendingAmount' => $data->pendingAmount ?? 0.0,
        'paymentMethod' => $data->paymentMethod ?? 'Cash',
        'paymentStatus' => $data->paymentStatus ?? 'Pending',
        'paymentDate' => $data->paymentDate ?? date('Y-m-d H:i:s'),
        'remarks' => $data->remarks ?? '',
        'createdBy' => $data->createdBy
    ];

    try {
        $id = $payment->create($params);
        if ($id > 0) {
            $params['id'] = $id;
            sendResponse(201, 'Payment recorded successfully', $params);
        } else {
            sendResponse(400, 'Unable to record payment');
        }
    } catch (Exception $e) {
        sendResponse(500, 'Error recording payment', [
            'error' => $e->getMessage()
        ]);
    }
} else {
    sendResponse(400, 'Invalid request: No data received');
}
