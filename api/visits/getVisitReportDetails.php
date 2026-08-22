<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

include_once('../../config/database.php');

$database = new Database();
$db = $database->connect();

$data = json_decode(file_get_contents("php://input"));

function sendResponse($statusCode, $message, $body = null)
{
    echo json_encode([
        'statusCode' => $statusCode,
        'message' => $message,
        'body' => $body
    ]);
}

if (isset($data->parentId) && isset($data->visitId)) {
    try {
        // 1. Fetch Visit details
        $visitQuery = "SELECT * FROM visits WHERE id = :visitId AND parentId = :parentId LIMIT 0,1";
        $visitStmt = $db->prepare($visitQuery);
        $visitStmt->execute([
            ':visitId' => $data->visitId,
            ':parentId' => $data->parentId
        ]);

        if ($visitStmt->rowCount() > 0) {
            $visitRow = $visitStmt->fetch(PDO::FETCH_ASSOC);

            // Decode visit JSON image fields
            $jsonFields = [
                'chief_complaint_images',
                'clinical_findings_images',
                'lab_images',
                'advised_treatment_images',
                'treatment_done_images',
                'medication_images'
            ];
            foreach ($jsonFields as $field) {
                $visitRow[$field] = !empty($visitRow[$field]) ? json_decode($visitRow[$field], true) : [];
            }

            $patientId = $visitRow['patient_id'];
            $doctorId = $visitRow['doctor_id'];

            // 2. Fetch Patient details
            $patientQuery = "SELECT * FROM patients WHERE id = :patientId LIMIT 0,1";
            $patientStmt = $db->prepare($patientQuery);
            $patientStmt->execute([':patientId' => $patientId]);
            $patientRow = null;
            if ($patientStmt->rowCount() > 0) {
                $patientRow = $patientStmt->fetch(PDO::FETCH_ASSOC);
                // Decode medical conditions JSON
                $patientRow['medical_conditions'] = !empty($patientRow['medical_conditions']) 
                    ? json_decode($patientRow['medical_conditions'], true) 
                    : [];
            }

            // 3. Fetch Company/Clinic details (supports visits created by doctor owner or sub-user/staff)
            $targetClinicId = !empty($visitRow['parentId']) ? $visitRow['parentId'] : ($data->parentId ?? $doctorId);

            $companyQuery = "SELECT * FROM company 
                             WHERE userId = :doctorId 
                                OR userId = :targetClinicId 
                                OR userId = (SELECT parentId FROM registration WHERE id = :doctorId AND parentId IS NOT NULL)
                             ORDER BY CASE WHEN userId = :doctorId THEN 1 ELSE 2 END
                             LIMIT 0,1";
            $companyStmt = $db->prepare($companyQuery);
            $companyStmt->execute([
                ':doctorId' => $doctorId,
                ':targetClinicId' => $targetClinicId
            ]);
            $companyRow = null;
            if ($companyStmt->rowCount() > 0) {
                $companyRow = $companyStmt->fetch(PDO::FETCH_ASSOC);
            }

            // 4. Fetch Payment details
            $paymentQuery = "SELECT * FROM payments WHERE visit_id = :visitId LIMIT 0,1";
            $paymentStmt = $db->prepare($paymentQuery);
            $paymentStmt->execute([':visitId' => $data->visitId]);
            $paymentRow = null;
            if ($paymentStmt->rowCount() > 0) {
                $paymentRow = $paymentStmt->fetch(PDO::FETCH_ASSOC);
            }

            // Consolidate response payload
            $reportData = [
                'visit' => $visitRow,
                'patient' => $patientRow,
                'clinic' => $companyRow,
                'payment' => $paymentRow
            ];

            sendResponse(
                200,
                'Visit report details fetched successfully',
                $reportData
            );

        } else {
            sendResponse(
                404,
                'Visit not found'
            );
        }

    } catch (Exception $e) {
        sendResponse(
            500,
            'Error fetching report details',
            [
                'error' => $e->getMessage()
            ]
        );
    }

} else {
    sendResponse(
        400,
        'parentId and visitId are required'
    );
}
