<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

class Visit
{
    // Visit Fields

    public $id;
    public $parentId;
    public $patientId;
    public $doctorId;
    public $visitNo;
    public $visitDate;

    public $chiefComplaintText;
    public $chiefComplaintImages;

    public $clinicalFindingsText;
    public $clinicalFindingsImages;

    public $labText;
    public $labImages;

    public $advisedTreatmentText;
    public $advisedTreatmentImages;

    public $treatmentDoneText;
    public $treatmentDoneImages;

    public $medicationText;
    public $medicationImages;

    public $nextAppointmentDate;

    public $notes;

    public $status;

    public $createdAt;
    public $updatedAt;

    // Database

    private $connection;
    private $table = "visits";

    public function __construct($db)
    {
        $this->connection = $db;
    }

    /**
     * Create Visit
     */
    public function createVisit($params)
    {
        try {

            $query = "INSERT INTO {$this->table}
            SET
                parentId=:parentId,
                patient_id=:patientId,
                doctor_id=:doctorId,
                visit_no=:visitNo,
                visit_date=:visitDate,

                chief_complaint_text=:chiefComplaintText,
                chief_complaint_images=:chiefComplaintImages,

                clinical_findings_text=:clinicalFindingsText,
                clinical_findings_images=:clinicalFindingsImages,

                lab_text=:labText,
                lab_images=:labImages,

                advised_treatment_text=:advisedTreatmentText,
                advised_treatment_images=:advisedTreatmentImages,

                treatment_done_text=:treatmentDoneText,
                treatment_done_images=:treatmentDoneImages,

                medication_text=:medicationText,
                medication_images=:medicationImages,

                next_appointment_date=:nextAppointmentDate,

                notes=:notes,

                status=:status";

            $stmt = $this->connection->prepare($query);

            $stmt->execute([

                ':parentId' => $params['parentId'],
                ':patientId' => $params['patientId'],
                ':doctorId' => $params['doctorId'],
                ':visitNo' => $params['visitNo'],
                ':visitDate' => $params['visitDate'],

                ':chiefComplaintText' => $params['chiefComplaintText'],
                ':chiefComplaintImages' => $params['chiefComplaintImages'],

                ':clinicalFindingsText' => $params['clinicalFindingsText'],
                ':clinicalFindingsImages' => $params['clinicalFindingsImages'],

                ':labText' => $params['labText'],
                ':labImages' => $params['labImages'],

                ':advisedTreatmentText' => $params['advisedTreatmentText'],
                ':advisedTreatmentImages' => $params['advisedTreatmentImages'],

                ':treatmentDoneText' => $params['treatmentDoneText'],
                ':treatmentDoneImages' => $params['treatmentDoneImages'],

                ':medicationText' => $params['medicationText'],
                ':medicationImages' => $params['medicationImages'],

                ':nextAppointmentDate' => $params['nextAppointmentDate'],

                ':notes' => $params['notes'],

                ':status' => $params['status']

            ]);

            return $this->connection->lastInsertId();

        } catch (PDOException $e) {
            throw new Exception("Error creating visit: " . $e->getMessage());
        }
    }

    /**
     * Update Visit
     */
    public function updateVisit($params)
    {
        try {

            $query = "UPDATE {$this->table}
            SET

                chief_complaint_text=:chiefComplaintText,
                chief_complaint_images=:chiefComplaintImages,

                clinical_findings_text=:clinicalFindingsText,
                clinical_findings_images=:clinicalFindingsImages,

                lab_text=:labText,
                lab_images=:labImages,

                advised_treatment_text=:advisedTreatmentText,
                advised_treatment_images=:advisedTreatmentImages,

                treatment_done_text=:treatmentDoneText,
                treatment_done_images=:treatmentDoneImages,

                medication_text=:medicationText,
                medication_images=:medicationImages,

                next_appointment_date=:nextAppointmentDate,

                notes=:notes,

                status=:status

            WHERE id=:id
            AND parentId=:parentId";

            $stmt = $this->connection->prepare($query);

            return $stmt->execute([

                ':chiefComplaintText' => $params['chiefComplaintText'],
                ':chiefComplaintImages' => $params['chiefComplaintImages'],

                ':clinicalFindingsText' => $params['clinicalFindingsText'],
                ':clinicalFindingsImages' => $params['clinicalFindingsImages'],

                ':labText' => $params['labText'],
                ':labImages' => $params['labImages'],

                ':advisedTreatmentText' => $params['advisedTreatmentText'],
                ':advisedTreatmentImages' => $params['advisedTreatmentImages'],

                ':treatmentDoneText' => $params['treatmentDoneText'],
                ':treatmentDoneImages' => $params['treatmentDoneImages'],

                ':medicationText' => $params['medicationText'],
                ':medicationImages' => $params['medicationImages'],

                ':nextAppointmentDate' => $params['nextAppointmentDate'],

                ':notes' => $params['notes'],

                ':status' => $params['status'],

                ':id' => $params['id'],
                ':parentId' => $params['parentId']

            ]);

        } catch (PDOException $e) {
            throw new Exception("Error updating visit: " . $e->getMessage());
        }
    }

    /**
     * Get Visits
     */
    public function getVisits($parentId, $patientId)
{
    $query = "SELECT
                id,
                visit_no,
                visit_date,
                treatment_done_text,
                next_appointment_date,
                status
              FROM {$this->table}
              WHERE parentId = ?
              AND patient_id = ?
              ORDER BY visit_date DESC";

    $stmt = $this->connection->prepare($query);
    $stmt->execute([
        $parentId,
        $patientId
    ]);

    return $stmt;
}
    /**
     * Change Status
     */
    public function changeStatus($id, $parentId, $status)
    {
        $query = "UPDATE {$this->table}
                  SET status=?
                  WHERE id=?
                  AND parentId=?";

        $stmt = $this->connection->prepare($query);

        return $stmt->execute([
            $status,
            $id,
            $parentId
        ]);
    }
public function getVisitById($parentId, $visitId)
{
    $query = "SELECT *
              FROM {$this->table}
              WHERE parentId = ?
              AND id = ?
              LIMIT 1";

    $stmt = $this->connection->prepare($query);
    $stmt->execute([
        $parentId,
        $visitId
    ]);

    return $stmt;
}
}