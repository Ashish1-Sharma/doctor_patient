<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

class Appointment
{
    public $id;
    public $visitId;
    public $patientId;
    public $doctorId;
    public $appointmentDate;
    public $procedureText;
    public $status;
    public $createdAt;
    public $updatedAt;

    private $connection;
    private $table = "appointments";

    public function __construct($db)
    {
        $this->connection = $db;
    }

    /**
     * Create Appointment
     */
    public function create($params)
    {
        try {
            $query = "INSERT INTO {$this->table}
            SET
                visit_id = :visitId,
                patient_id = :patientId,
                doctor_id = :doctorId,
                appointment_date = :appointmentDate,
                procedure_text = :procedureText,
                status = :status";

            $stmt = $this->connection->prepare($query);

            $stmt->bindValue(":visitId", $params["visitId"]);
            $stmt->bindValue(":patientId", $params["patientId"]);
            $stmt->bindValue(":doctorId", $params["doctorId"]);
            $stmt->bindValue(":appointmentDate", $params["appointmentDate"]);
            $stmt->bindValue(":procedureText", $params["procedureText"]);
            $stmt->bindValue(":status", $params["status"] ?? 'Pending');

            if ($stmt->execute()) {
                return $this->connection->lastInsertId();
            }
            return 0;
        } catch (PDOException $e) {
            throw new Exception("Error creating appointment: " . $e->getMessage());
        }
    }

    /**
     * Get Appointments by Doctor ID
     */
    public function getByDoctorId($doctorId)
    {
        try {
            $query = "SELECT * FROM {$this->table} 
                      WHERE doctor_id = :doctorId 
                      ORDER BY appointment_date ASC";
            $stmt = $this->connection->prepare($query);
            $stmt->bindValue(":doctorId", $doctorId, PDO::PARAM_INT);
            $stmt->execute();
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            throw new Exception("Error fetching appointments: " . $e->getMessage());
        }
    }

    /**
     * Update Appointment details (rescheduling)
     */
    public function update($id, $params)
    {
        try {
            $query = "UPDATE {$this->table}
                      SET
                          appointment_date = :appointmentDate,
                          procedure_text = :procedureText,
                          status = :status
                      WHERE id = :id";

            $stmt = $this->connection->prepare($query);

            $stmt->bindValue(":appointmentDate", $params["appointmentDate"]);
            $stmt->bindValue(":procedureText", $params["procedureText"]);
            $stmt->bindValue(":status", $params["status"]);
            $stmt->bindValue(":id", $id, PDO::PARAM_INT);

            return $stmt->execute();
        } catch (PDOException $e) {
            throw new Exception("Error updating appointment: " . $e->getMessage());
        }
    }

    /**
     * Delete Appointment
     */
    public function delete($id)
    {
        try {
            $query = "DELETE FROM {$this->table} WHERE id = :id";
            $stmt = $this->connection->prepare($query);
            $stmt->bindValue(":id", $id, PDO::PARAM_INT);
            return $stmt->execute();
        } catch (PDOException $e) {
            throw new Exception("Error deleting appointment: " . $e->getMessage());
        }
    }
}

