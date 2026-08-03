<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

class Company
{
    // User fields
    public $id;
    public $userId;
    public $companyName;
    public $companyAddress;
    public $gst;
    public $dlNo;
    public $terms;

    // DB fields
    private $connection;
    private $table = 'company';

    public function __construct($db)
    {
        $this->connection = $db;
    }

    public function create($data)
    {
        $data['gst'] = empty($data['gst']) ? null : $data['gst'];
        $data['dlNo'] = empty($data['dlNo']) ? null : $data['dlNo'];
        $data['terms'] = empty($data['terms']) ? null : $data['terms'];

        $query = "INSERT INTO $this->table 
            (userId, companyName, companyAddress, gst, dlNo, terms) 
            VALUES 
            (:userId, :companyName, :companyAddress, :gst, :dlNo, :terms)";

        $stmt = $this->connection->prepare($query);

        if ($stmt->execute($data)) {
            return $this->connection->lastInsertId(); // Return the ID of the newly created record
        }

        return 0; // Return 0 if the insertion fails
    }

public function getByUserId($userId)
{
    try {
        // Step 1: Determine the IDs to include in the query
        $parentQuery = "
            SELECT parentId 
            FROM registration 
            WHERE id = :userId
        ";

        $parentStmt = $this->connection->prepare($parentQuery);
        $parentStmt->execute(['userId' => $userId]);
        $parentData = $parentStmt->fetch(PDO::FETCH_ASSOC);

        $idsToFetch = []; // Array to store user IDs

        if ($parentData && $parentData['parentId'] !== null) {
            // Case 1: If user has a parentId, fetch all users with the same parentId
            $idsQuery = "SELECT id FROM registration WHERE parentId = :parentId";
            $idsStmt = $this->connection->prepare($idsQuery);
            $idsStmt->bindParam(":parentId", $parentData['parentId'], PDO::PARAM_INT);
            $idsStmt->execute();

            $idsToFetch = $idsStmt->fetchAll(PDO::FETCH_COLUMN); // Fetch user IDs with the same parentId
            $idsToFetch[] = $parentData['parentId']; // Include the parentId itself
        } else {
            // Case 2: If user does not have a parentId, fetch users with this userId as parentId
            $idsQuery = "SELECT id FROM registration WHERE parentId = :userId";
            $idsStmt = $this->connection->prepare($idsQuery);
            $idsStmt->bindParam(":userId", $userId, PDO::PARAM_INT);
            $idsStmt->execute();

            $idsToFetch = $idsStmt->fetchAll(PDO::FETCH_COLUMN); // Fetch user IDs with this userId as parentId
            $idsToFetch[] = $userId; // Include the userId itself
        }

        // Step 2: Query to fetch data for the relevant user IDs
        $query = "
            SELECT * 
            FROM `$this->table`
            WHERE userId IN (" . implode(',', array_map('intval', $idsToFetch)) . ")
        ";

        $stmt = $this->connection->prepare($query);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC); // Fetch all rows as an array of associative arrays
    } catch (PDOException $e) {
        throw new Exception('Error fetching user data: ' . $e->getMessage());
    }
}

    public function update($id, $data)
    {
        // Ensure optional fields are set to NULL if not provided
        $data['gst'] = empty($data['gst']) ? null : $data['gst'];
        $data['dlNo'] = empty($data['dlNo']) ? null : $data['dlNo'];
        $data['terms'] = empty($data['terms']) ? null : $data['terms'];

        // Prepare the update query
        $query = "UPDATE $this->table SET 
            userId = :userId,
            companyName = :companyName,
            companyAddress = :companyAddress,
            gst = :gst,
            dlNo = :dlNo,
            terms = :terms
            WHERE id = :id";

        // Add the ID to the data for binding
        $data['id'] = $id;

        $stmt = $this->connection->prepare($query);

        if ($stmt->execute($data)) {
            return true; // Return true if update was successful
        }

        return false; // Return false if the update failed
    }
}
