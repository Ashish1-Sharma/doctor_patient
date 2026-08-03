<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

class Patient
{
    // Patient Fields

    public $id;
    public $parentId;
    public $patientCode;
    public $profileImage;
    public $fullName;
    public $age;
    public $gender;
    public $dateOfBirth;
    public $phone;
    public $email;
    public $address;
    public $medicalConditions;
    public $emergencyContactName;
    public $emergencyContactPhone;
    public $totalVisits;
    public $lastVisitDate;
    public $createdBy;
    public $status;
    public $createdAt;
    public $updatedAt;

    // Database

    private $connection;
    private $table = "patients";

    public function __construct($db)
    {
        $this->connection = $db;
    }

    /**
     * Create Patient
     */
    public function createPatient($params)
    {
        try {

            $query = "INSERT INTO {$this->table}
            SET
                parentId = :parentId,
                patient_code = :patientCode,
                profile_image = :profileImage,
                full_name = :fullName,
                age = :age,
                gender = :gender,
                date_of_birth = :dateOfBirth,
                phone = :phone,
                email = :email,
                address = :address,
                medical_conditions = :medicalConditions,
                emergency_contact_name = :emergencyContactName,
                emergency_contact_phone = :emergencyContactPhone,
                total_visits = :totalVisits,
                last_visit_date = :lastVisitDate,
                created_by = :createdBy,
                status = :status";

            $stmt = $this->connection->prepare($query);

            $stmt->bindValue(":parentId", $params["parentId"]);
            $stmt->bindValue(":patientCode", $params["patientCode"]);
            $stmt->bindValue(":profileImage", $params["profileImage"]);
            $stmt->bindValue(":fullName", $params["fullName"]);
            $stmt->bindValue(":age", $params["age"]);
            $stmt->bindValue(":gender", $params["gender"]);
            $stmt->bindValue(":dateOfBirth", $params["dateOfBirth"]);
            $stmt->bindValue(":phone", $params["phone"]);
            $stmt->bindValue(":email", $params["email"]);
            $stmt->bindValue(":address", $params["address"]);
            $stmt->bindValue(":medicalConditions", $params["medicalConditions"]);
            $stmt->bindValue(":emergencyContactName", $params["emergencyContactName"]);
            $stmt->bindValue(":emergencyContactPhone", $params["emergencyContactPhone"]);
            $stmt->bindValue(":totalVisits", $params["totalVisits"]);
            $stmt->bindValue(":lastVisitDate", $params["lastVisitDate"]);
            $stmt->bindValue(":createdBy", $params["createdBy"]);
            $stmt->bindValue(":status", $params["status"]);

            if ($stmt->execute()) {
                return $this->connection->lastInsertId();
            }

            return 0;

        } catch (PDOException $e) {
            throw new Exception("Error creating patient: " . $e->getMessage());
        }
    }

    /**
     * Update Patient
     */
    public function updatePatient($params)
    {
        try {

            $query = "UPDATE {$this->table}
            SET
                profile_image = :profileImage,
                full_name = :fullName,
                age = :age,
                gender = :gender,
                date_of_birth = :dateOfBirth,
                phone = :phone,
                email = :email,
                address = :address,
                medical_conditions = :medicalConditions,
                emergency_contact_name = :emergencyContactName,
                emergency_contact_phone = :emergencyContactPhone,
                status = :status
            WHERE id = :id
            AND parentId = :parentId";

            $stmt = $this->connection->prepare($query);

            $stmt->bindValue(":profileImage", $params["profileImage"]);
            $stmt->bindValue(":fullName", $params["fullName"]);
            $stmt->bindValue(":age", $params["age"]);
            $stmt->bindValue(":gender", $params["gender"]);
            $stmt->bindValue(":dateOfBirth", $params["dateOfBirth"]);
            $stmt->bindValue(":phone", $params["phone"]);
            $stmt->bindValue(":email", $params["email"]);
            $stmt->bindValue(":address", $params["address"]);
            $stmt->bindValue(":medicalConditions", $params["medicalConditions"]);
            $stmt->bindValue(":emergencyContactName", $params["emergencyContactName"]);
            $stmt->bindValue(":emergencyContactPhone", $params["emergencyContactPhone"]);
            $stmt->bindValue(":status", $params["status"]);
            $stmt->bindValue(":id", $params["id"]);
            $stmt->bindValue(":parentId", $params["parentId"]);

            return $stmt->execute();

        } catch (PDOException $e) {
            throw new Exception("Error updating patient: " . $e->getMessage());
        }
    }

    /**
     * Get Patient By ID
     */
    public function getPatientById($id, $parentId)
    {
        $query = "SELECT * FROM {$this->table}
                  WHERE id = ?
                  AND parentId = ?
                  LIMIT 1";

        $stmt = $this->connection->prepare($query);
        $stmt->execute([$id, $parentId]);

        return $stmt;
    }

    /**
     * Search Patients
     */
    public function searchPatients($parentId, $keyword)
    {
        $query = "SELECT *
                  FROM {$this->table}
                  WHERE parentId = ?
                  AND (
                        full_name LIKE ?
                        OR phone LIKE ?
                        OR patient_code LIKE ?
                  )
                  ORDER BY full_name ASC";

        $search = "%{$keyword}%";

        $stmt = $this->connection->prepare($query);
        $stmt->execute([
            $parentId,
            $search,
            $search,
            $search
        ]);

        return $stmt;
    }

    /**
     * Get All Patients
     */
    public function getPatients($parentId)
    {
        $query = "SELECT *
                  FROM {$this->table}
                  WHERE parentId = ?
                  ORDER BY created_at DESC";

        $stmt = $this->connection->prepare($query);
        $stmt->execute([$parentId]);

        return $stmt;
    }

    /**
     * Delete Patient (Soft Delete)
     */
    public function changeStatus($id, $parentId, $status)
    {
        $query = "UPDATE {$this->table}
                  SET status = ?
                  WHERE id = ?
                  AND parentId = ?";

        $stmt = $this->connection->prepare($query);

        return $stmt->execute([
            $status,
            $id,
            $parentId
        ]);
    }
}