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

$targetParentId = $data->parentId ?? $data->doctorId ?? null;

if ($targetParentId) {

    try {
        // Resolve parentId if a sub-user ID was supplied
        $parentQuery = "SELECT id, parentId FROM registration WHERE id = ? LIMIT 1";
        $parentStmt = $db->prepare($parentQuery);
        $parentStmt->execute([(int)$targetParentId]);
        $userRow = $parentStmt->fetch(PDO::FETCH_ASSOC);
        if ($userRow && !empty($userRow['parentId'])) {
            $targetParentId = (int)$userRow['parentId'];
        }

        $result = $patient->getPatients($targetParentId);

        if ($result->rowCount() > 0) {

            $patients = [];

            while ($row = $result->fetch(PDO::FETCH_ASSOC)) {

                $row['medical_conditions'] = !empty($row['medical_conditions'])
                    ? json_decode($row['medical_conditions'], true)
                    : [];

                // Overlay the live aggregates onto the stale stored columns
                $row['total_visits'] = (int)($row['computed_total_visits'] ?? 0);
                $row['last_visit_date'] = $row['computed_last_visit_date'] ?? '';
                $row['pending_amount'] = (float)($row['computed_pending_amount'] ?? 0);

                unset(
                    $row['computed_total_visits'],
                    $row['computed_last_visit_date'],
                    $row['computed_pending_amount']
                );

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