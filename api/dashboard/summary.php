<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST, GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

include_once('../../config/database.php');
include_once('../../models/patient.php');
include_once('../../models/payment.php');
include_once('../../models/appointment.php');

$database = new Database();
$db = $database->connect();

$patient = new Patient($db);

$payment = new Payment($db);
$appointment = new Appointment($db);

$data = json_decode(file_get_contents("php://input"));

function sendResponse($statusCode, $message, $body = null)
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message' => $message,
        'body' => $body
    ]);
}

$parentId = $data->parentId ?? $data->doctorId ?? $_GET['parentId'] ?? $_GET['doctorId'] ?? null;

if ($parentId) {

    try {

        $paymentSummary = $payment->getSummaryByParentId($parentId);

        // Appointment stats are isolated: a failure there degrades that one tile
        // to zero rather than taking the whole summary response down with it.
        $appointmentStats = ['appointments_today' => 0, 'appointments_upcoming_total' => 0];
        try {
            $appointmentStats = $appointment->getStatsByDoctorId($parentId);
        } catch (Exception $e) {
            // leave the defaults in place
        }

        sendResponse(
            200,
            'Dashboard summary loaded successfully',
            [
                'patients_total' => $patient->countPatients($parentId),
                'appointments_today' => (int)($appointmentStats['appointments_today'] ?? 0),
                'appointments_upcoming_total' => (int)($appointmentStats['appointments_upcoming_total'] ?? 0),
                'total_earnings' => $paymentSummary['total_earnings'],
                'pending_payments_count' => $paymentSummary['pending_payments_count'],
            ]
        );

    } catch (Exception $e) {

        sendResponse(
            500,
            'Error loading dashboard summary',
            [
                'error' => $e->getMessage()
            ]
        );

    }

} else {

    sendResponse(
        400,
        'Invalid request: parentId is required'
    );

}
