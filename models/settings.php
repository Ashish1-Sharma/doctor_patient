<?php

class Settings
{
    // Table fields
    public $id;
    public $userId;
    public $months;
    public $count;
    public $gst;

    // DB fields
    private $connection;
    private $table = 'settings'; // Replace with the actual table name

    public function __construct($db)
    {
        $this->connection = $db;
    }

    // Create a new record
    public function createRecord($params)
    {
        try {
            $query = 'INSERT INTO ' . $this->table . ' (userId, months, count, gst) VALUES (:userId, :months, :count, :gst)';
            $stmt = $this->connection->prepare($query);

            $stmt->bindValue(':userId', $params['userId']);
            $stmt->bindValue(':months', $params['months']);
            $stmt->bindValue(':count', $params['count']);
            $stmt->bindValue(':gst', $params['gst']);

            if ($stmt->execute()) {
                return $this->connection->lastInsertId(); // Return the newly created record ID
            }

            return false;
        } catch (PDOException $e) {
            throw new Exception('Error creating record: ' . $e->getMessage());
        }
    }

    // Retrieve a record by ID
    public function getById($id)
    {
        try {
            $query = 'SELECT * FROM ' . $this->table . ' WHERE id = ? LIMIT 1';
            $stmt = $this->connection->prepare($query);
            $stmt->execute([$id]);
            return $stmt->fetch(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            throw new Exception('Error fetching record by ID: ' . $e->getMessage());
        }
    }

    // Retrieve records by userId
    public function getDataByUserId($userId)
    {
        try {
            $query = 'SELECT * FROM ' . $this->table . ' WHERE userId = ?';
            $stmt = $this->connection->prepare($query);
            $stmt->execute([$userId]);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            throw new Exception('Error fetching records by userId: ' . $e->getMessage());
        }
    }

    // Update a record
    public function updateRecord($id, $params)
    {
        try {
            $query = 'UPDATE ' . $this->table . ' SET userId = :userId, months = :months, count = :count, gst = :gst WHERE id = :id';
            $stmt = $this->connection->prepare($query);

            $stmt->bindValue(':userId', $params['userId']);
            $stmt->bindValue(':months', $params['months']);
            $stmt->bindValue(':count', $params['count']);
            $stmt->bindValue(':gst', $params['gst']);
            $stmt->bindValue(':id', $id);

            $stmt->execute();

            if ($stmt->rowCount() > 0) {
                return ['success' => true, 'message' => 'Record updated successfully'];
            } else {
                return ['success' => false, 'message' => 'No changes made or record not found'];
            }
        } catch (PDOException $e) {
            throw new Exception('Error updating record: ' . $e->getMessage());
        }
    }

    // Delete a record
    public function deleteRecord($id)
    {
        try {
            $query = 'DELETE FROM ' . $this->table . ' WHERE id = ?';
            $stmt = $this->connection->prepare($query);
            $stmt->execute([$id]);

            if ($stmt->rowCount() > 0) {
                return ['success' => true, 'message' => 'Record deleted successfully'];
            } else {
                return ['success' => false, 'message' => 'Record not found'];
            }
        } catch (PDOException $e) {
            throw new Exception('Error deleting record: ' . $e->getMessage());
        }
    }

    // Calculate total GST for a user
    public function calculateTotalGSTByUserId($userId)
    {
        try {
            $query = 'SELECT SUM(gst) as totalGst FROM ' . $this->table . ' WHERE userId = ?';
            $stmt = $this->connection->prepare($query);
            $stmt->execute([$userId]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);

            return $result['totalGst'] ?? 0;
        } catch (PDOException $e) {
            throw new Exception('Error calculating total GST: ' . $e->getMessage());
        }
    }
}
