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
    public $clinic_reg_no;
    public $pollution_control_cert;
    public $trade_license;
    public $municipality_noc;
    public $doctor_reg_cert;
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
        $data['clinic_reg_no'] = empty($data['clinic_reg_no']) ? null : $data['clinic_reg_no'];
        $data['pollution_control_cert'] = empty($data['pollution_control_cert']) ? null : $data['pollution_control_cert'];
        $data['trade_license'] = empty($data['trade_license']) ? null : $data['trade_license'];
        $data['municipality_noc'] = empty($data['municipality_noc']) ? null : $data['municipality_noc'];
        $data['doctor_reg_cert'] = empty($data['doctor_reg_cert']) ? null : $data['doctor_reg_cert'];
        $data['terms'] = empty($data['terms']) ? null : $data['terms'];

        $query = "INSERT INTO $this->table 
            (userId, companyName, companyAddress, clinic_reg_no, pollution_control_cert, trade_license, municipality_noc, doctor_reg_cert, terms) 
            VALUES 
            (:userId, :companyName, :companyAddress, :clinic_reg_no, :pollution_control_cert, :trade_license, :municipality_noc, :doctor_reg_cert, :terms)";

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
        $data['clinic_reg_no'] = empty($data['clinic_reg_no']) ? null : $data['clinic_reg_no'];
        $data['pollution_control_cert'] = empty($data['pollution_control_cert']) ? null : $data['pollution_control_cert'];
        $data['trade_license'] = empty($data['trade_license']) ? null : $data['trade_license'];
        $data['municipality_noc'] = empty($data['municipality_noc']) ? null : $data['municipality_noc'];
        $data['doctor_reg_cert'] = empty($data['doctor_reg_cert']) ? null : $data['doctor_reg_cert'];
        $data['terms'] = empty($data['terms']) ? null : $data['terms'];

        // Prepare the update query
        $query = "UPDATE $this->table SET 
            userId = :userId,
            companyName = :companyName,
            companyAddress = :companyAddress,
            clinic_reg_no = :clinic_reg_no,
            pollution_control_cert = :pollution_control_cert,
            trade_license = :trade_license,
            municipality_noc = :municipality_noc,
            doctor_reg_cert = :doctor_reg_cert,
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

    /**
     * Save or Update Company (upsert by id or userId) and remove duplicates
     */
    public function saveOrUpdate($data)
    {
        $userId = $data['userId'] ?? null;
        $id = $data['id'] ?? null;

        $targetId = null;

        if (!empty($id)) {
            $targetId = $id;
        } else if (!empty($userId)) {
            // Find existing company record for this userId
            $stmt = $this->connection->prepare("SELECT id FROM {$this->table} WHERE userId = ? ORDER BY id ASC LIMIT 1");
            $stmt->execute([$userId]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($row) {
                $targetId = $row['id'];
            }
        }

        if ($targetId) {
            $this->update($targetId, $data);

            // Clean up redundant duplicate rows for this userId if present
            if (!empty($userId)) {
                $cleanStmt = $this->connection->prepare("DELETE FROM {$this->table} WHERE userId = ? AND id != ?");
                $cleanStmt->execute([$userId, $targetId]);
            }

            return $targetId;
        } else {
            return $this->create($data);
        }
    }
}
