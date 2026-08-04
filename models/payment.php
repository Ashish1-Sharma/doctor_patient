<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

class Payment
{
    public $id;
    public $parentId;
    public $visitId;
    public $patientId;
    public $invoiceNo;
    public $subtotal;
    public $discount;
    public $totalAmount;
    public $paidAmount;
    public $pendingAmount;
    public $paymentMethod;
    public $paymentStatus;
    public $paymentDate;
    public $remarks;
    public $createdBy;
    public $createdAt;
    public $updatedAt;

    private $connection;
    private $table = "payments";

    public function __construct($db)
    {
        $this->connection = $db;
    }

    /**
     * Create Payment
     */
    public function create($params)
    {
        try {
            $query = "INSERT INTO {$this->table}
            SET
                parentId = :parentId,
                visit_id = :visitId,
                patient_id = :patientId,
                invoice_no = :invoiceNo,
                subtotal = :subtotal,
                discount = :discount,
                total_amount = :totalAmount,
                paid_amount = :paidAmount,
                pending_amount = :pendingAmount,
                payment_method = :paymentMethod,
                payment_status = :paymentStatus,
                payment_date = :paymentDate,
                remarks = :remarks,
                created_by = :createdBy";

            $stmt = $this->connection->prepare($query);

            $stmt->bindValue(":parentId", $params["parentId"]);
            $stmt->bindValue(":visitId", $params["visitId"]);
            $stmt->bindValue(":patientId", $params["patientId"]);
            $stmt->bindValue(":invoiceNo", $params["invoiceNo"]);
            $stmt->bindValue(":subtotal", $params["subtotal"]);
            $stmt->bindValue(":discount", $params["discount"]);
            $stmt->bindValue(":totalAmount", $params["totalAmount"]);
            $stmt->bindValue(":paidAmount", $params["paidAmount"]);
            $stmt->bindValue(":pendingAmount", $params["pendingAmount"]);
            $stmt->bindValue(":paymentMethod", $params["paymentMethod"]);
            $stmt->bindValue(":paymentStatus", $params["paymentStatus"]);
            $stmt->bindValue(":paymentDate", $params["paymentDate"]);
            $stmt->bindValue(":remarks", $params["remarks"]);
            $stmt->bindValue(":createdBy", $params["createdBy"]);

            if ($stmt->execute()) {
                return $this->connection->lastInsertId();
            }
            return 0;
        } catch (PDOException $e) {
            throw new Exception("Error creating payment: " . $e->getMessage());
        }
    }

    /**
     * Get Payments List by Parent ID
     */
    public function getListByParentId($parentId)
    {
        try {
            $query = "SELECT * FROM {$this->table} 
                      WHERE parentId = :parentId 
                      ORDER BY updated_at DESC";
            $stmt = $this->connection->prepare($query);
            $stmt->bindValue(":parentId", $parentId, PDO::PARAM_INT);
            $stmt->execute();
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            throw new Exception("Error fetching payments: " . $e->getMessage());
        }
    }

    /**
     * Get Payment by Visit ID
     */
    public function getByVisitId($visitId)
    {
        try {
            $query = "SELECT * FROM {$this->table} 
                      WHERE visit_id = :visitId LIMIT 1";
            $stmt = $this->connection->prepare($query);
            $stmt->bindValue(":visitId", $visitId, PDO::PARAM_INT);
            $stmt->execute();
            return $stmt->fetch(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            throw new Exception("Error fetching payment: " . $e->getMessage());
        }
    }

    /**
     * Update Payment Status & Amount
     */
    public function update($id, $paidAmount, $pendingAmount, $paymentStatus, $remarks)
    {
        try {
            $query = "UPDATE {$this->table} 
                      SET 
                          paid_amount = :paidAmount,
                          pending_amount = :pendingAmount,
                          payment_status = :paymentStatus,
                          remarks = :remarks
                      WHERE id = :id";
            $stmt = $this->connection->prepare($query);
            $stmt->bindValue(":paidAmount", $paidAmount);
            $stmt->bindValue(":pendingAmount", $pendingAmount);
            $stmt->bindValue(":paymentStatus", $paymentStatus);
            $stmt->bindValue(":remarks", $remarks);
            $stmt->bindValue(":id", $id, PDO::PARAM_INT);
            return $stmt->execute();
        } catch (PDOException $e) {
            throw new Exception("Error updating payment: " . $e->getMessage());
        }
    }
}
