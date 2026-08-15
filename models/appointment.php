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

    /**
     * Get Appointment by ID with Patient Details
     */
    public function getById($id)
    {
        try {
            $query = "SELECT a.*, p.full_name as patient_name, p.patient_code, p.phone as patient_phone, p.profile_image as patient_image, p.age as patient_age, p.gender as patient_gender
                      FROM {$this->table} a
                      LEFT JOIN patients p ON a.patient_id = p.id
                      WHERE a.id = :id LIMIT 1";
            $stmt = $this->connection->prepare($query);
            $stmt->bindValue(":id", $id, PDO::PARAM_INT);
            $stmt->execute();
            return $stmt->fetch(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            throw new Exception("Error fetching appointment detail: " . $e->getMessage());
        }
    }

    /**
     * Get Appointments by Doctor ID & Date Range (today, tomorrow, week, custom, all)
     */
    public function getByDoctorIdAndRange($doctorId, $range = 'all', $from = null, $to = null)
    {
        try {
            $whereClause = "WHERE a.doctor_id = :doctorId";
            $params = [':doctorId' => $doctorId];

            switch ($range) {
                case 'today':
                    $whereClause .= " AND DATE(a.appointment_date) = CURDATE()";
                    break;
                case 'tomorrow':
                    $whereClause .= " AND DATE(a.appointment_date) = CURDATE() + INTERVAL 1 DAY";
                    break;
                case 'week':
                    $whereClause .= " AND DATE(a.appointment_date) BETWEEN CURDATE() AND (CURDATE() + INTERVAL 6 DAY)";
                    break;
                case 'custom':
                    if (!empty($from) && !empty($to)) {
                        $whereClause .= " AND DATE(a.appointment_date) BETWEEN :fromDate AND :toDate";
                        $params[':fromDate'] = $from;
                        $params[':toDate'] = $to;
                    }
                    break;
                case 'all':
                default:
                    break;
            }

            $query = "SELECT a.*, p.full_name as patient_name, p.patient_code, p.phone as patient_phone, p.profile_image as patient_image
                      FROM {$this->table} a
                      LEFT JOIN patients p ON a.patient_id = p.id
                      {$whereClause}
                      ORDER BY a.appointment_date ASC";

            $stmt = $this->connection->prepare($query);
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->execute();
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            throw new Exception("Error fetching appointments range: " . $e->getMessage());
        }
    }

    /**
     * Get Stats (Today count & Total Upcoming count) for Doctor
     */
    public function getStatsByDoctorId($doctorId)
    {
        try {
            $queryToday = "SELECT COUNT(*) as today_count FROM {$this->table} 
                           WHERE doctor_id = :doctorId 
                             AND DATE(appointment_date) = CURDATE() 
                             AND (status IS NULL OR LOWER(status) != 'cancelled')";
            $stmtToday = $this->connection->prepare($queryToday);
            $stmtToday->bindValue(":doctorId", $doctorId, PDO::PARAM_INT);
            $stmtToday->execute();
            $todayRow = $stmtToday->fetch(PDO::FETCH_ASSOC);

            $queryUpcoming = "SELECT COUNT(*) as upcoming_count FROM {$this->table} 
                              WHERE doctor_id = :doctorId 
                                AND DATE(appointment_date) >= CURDATE() 
                                AND (status IS NULL OR LOWER(status) != 'cancelled')";
            $stmtUpcoming = $this->connection->prepare($queryUpcoming);
            $stmtUpcoming->bindValue(":doctorId", $doctorId, PDO::PARAM_INT);
            $stmtUpcoming->execute();
            $upcomingRow = $stmtUpcoming->fetch(PDO::FETCH_ASSOC);

            return [
                'appointments_today' => (int)($todayRow['today_count'] ?? 0),
                'appointments_upcoming_total' => (int)($upcomingRow['upcoming_count'] ?? 0),
            ];
        } catch (PDOException $e) {
            throw new Exception("Error fetching appointment stats: " . $e->getMessage());
        }
    }
}

