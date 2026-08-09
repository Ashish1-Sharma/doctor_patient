<?php

error_reporting(E_ALL);
ini_set('display_error', 1);

class users
{

    //user fields

    public $id;
    public $userName;
    public $userEmail;
    public $userMobile;
    public $country;
    public $password;
    public $reg_date;
    public $validity;
    public $purchase_date;
    public $purchase_id;
    public $flag;
    public $parentId;

    // db fields

    private $connection;
    private $table = 'registration';

    public function __construct($db)
    {
        $this->connection = $db;
    }

    public function getUserByEmailOrMobile($userEmail, $userMobile)
    {
        try {
            $query = 'SELECT * FROM ' . $this->table . ' WHERE userEmail = ? OR userMobile = ? LIMIT 0,1';

            $user = $this->connection->prepare($query);

            $user->execute([$userEmail, $userMobile]);

            return $user;
        } catch (PDOException $e) {
            throw new Exception('Error checking user by email or mobile: ' . $e->getMessage());
        }
    }

public function updateEmail($currentEmail, $newEmail)
{
    try {
        // Check if the new email already exists in the database
        $checkQuery = 'SELECT id FROM ' . $this->table . ' WHERE userEmail = ? LIMIT 1';
        $checkStmt = $this->connection->prepare($checkQuery);
        $checkStmt->execute([$newEmail]);

        if ($checkStmt->fetch(PDO::FETCH_ASSOC)) {
            // Email already exists
            throw new Exception('The new email is already in use');
        }

        // Proceed to update the email if no conflict
        $updateQuery = 'UPDATE ' . $this->table . ' SET userEmail = ? WHERE userEmail = ?';
        $updateStmt = $this->connection->prepare($updateQuery);
        $updateStmt->execute([$newEmail, $currentEmail]);

        if ($updateStmt->rowCount() > 0) {
            return true; // Update successful
        } else {
            throw new Exception('No changes made or user not found');
        }
    } catch (PDOException $e) {
        throw new Exception('Error updating email: ' . $e->getMessage());
    }
}

public function getUserById($id)
{
    try {
        $query = 'SELECT * FROM ' . $this->table . ' WHERE id = ? LIMIT 0,1';
        $stmt = $this->connection->prepare($query);
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        throw new Exception('Error fetching user by ID: ' . $e->getMessage());
    }
}

public function updateUser($id, $userName, $userEmail, $userMobile, $country, $password = null)
{
    try {
        // Check if the new email or mobile number is already in use by another user
        $checkQuery = 'SELECT id FROM ' . $this->table . ' WHERE (userEmail = ? OR userMobile = ?) AND id != ? LIMIT 1';
        $checkStmt = $this->connection->prepare($checkQuery);
        $checkStmt->execute([$userEmail, $userMobile, $id]);
        if ($checkStmt->fetch(PDO::FETCH_ASSOC)) {
            return ['success' => false, 'message' => 'Email or mobile number is already in use by another account'];
        }

        // Start building the query
        $query = 'UPDATE ' . $this->table . ' SET userName = ?, userEmail = ?, userMobile = ?, country = ?';

        // Add password to the query if it's provided
        $params = [$userName, $userEmail, $userMobile, $country];
        if ($password !== null) {
            $query .= ', password = ?';
            $params[] = $password;
        }

        $query .= ' WHERE id = ?';
        $params[] = $id; // Add ID to the parameters

        // Prepare and execute the statement
        $stmt = $this->connection->prepare($query);
        $stmt->execute($params);

        return ['success' => true, 'message' => 'User updated successfully'];
    } catch (PDOException $e) {
        throw new Exception('Error updating user: ' . $e->getMessage());
    }
}

public function subUserLogin($params)
{
    try {
        $parentEmail = $params['parentEmail'];
        $childEmail = $params['childEmail'];
        $inputPassword = $params['inputPassword'];

        // Step 1: Fetch parent details using parentEmail
        $parentQuery = '
            SELECT id, reg_date, validity, purchase_date, purchase_id, flag 
            FROM ' . $this->table . ' 
            WHERE userEmail = ?
            LIMIT 0,1';

        $parentStmt = $this->connection->prepare($parentQuery);
        $parentStmt->execute([$parentEmail]);
        $parent = $parentStmt->fetch(PDO::FETCH_ASSOC);

        if ($parent) {
            $parentId = $parent['id'];

            // Step 2: Fetch child details using parentId
            $childQuery = '
                SELECT id, userName, userEmail, userMobile, country, password, parentId, status 
                FROM ' . $this->table . ' 
                WHERE parentId = ?';

            $childStmt = $this->connection->prepare($childQuery);
            $childStmt->execute([$parentId]);
            $children = $childStmt->fetchAll(PDO::FETCH_ASSOC);

            // Step 3: Validate child email and password
            foreach ($children as $child) {
                if ($child['userEmail'] === $childEmail && $child['password'] === $inputPassword) {
                    // Merge parent data into child data
                    $child['reg_date'] = $parent['reg_date'];
                    $child['purchase_id'] = $parent['purchase_id'];
                    $child['validity'] = $parent['validity'];
                    $child['purchase_date'] = $parent['purchase_date'];
                    $child['flag'] = $parent['flag'];

                    return $child; // Return the merged data
                }
            }
        }

        // Login failed
        return false;
    } catch (PDOException $e) {
        throw new Exception("Error in sub-user login: " . $e->getMessage());
    }
}

public function loginUser($params)
{
    try {
        $userEmailMobile = $params['userEmailMobile'];
        $inputPassword = $params['password']; // Plain-text password

        $query = '
            SELECT *
            FROM ' . $this->table . ' 
            WHERE (userEmail = ? OR TRIM(SUBSTRING_INDEX(userMobile, " ", -1)) = ?) 
            AND parentId IS NULL 
            LIMIT 0,1';

        $stmt = $this->connection->prepare($query);

        if ($stmt->execute([$userEmailMobile, $userEmailMobile])) {
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($user && $inputPassword === $user['password']) {
                return $user;
            }
        }

        // Login failed
        return false;
    } catch (PDOException $e) {
        throw new Exception("Error in user login: " . $e->getMessage());
    }
}

    public function registerUser($params)
    {
        try {

            $this->userName = $params['userName'];
            $this->userEmail = $params['userEmail'];
            $this->userMobile = $params['userMobile'];
            $this->country = $params['country'];
            $this->password = $params['password'];
            $this->reg_date = $params['reg_date'];
            $this->validity = $params['validity'];
            $this->purchase_date = $params['purchase_date'];
            $this->purchase_id = $params['purchase_id'];
            $this->flag = $params['flag'];

            $query = 'INSERT INTO ' . $this->table . ' SET userName=:userName, userEmail=:userEmail, userMobile=:userMobile, country=:country, password=:password, reg_date=:reg_date, validity=:validity, purchase_date=:purchase_date, purchase_id=:purchase_id, flag=:flag';

            $user = $this->connection->prepare($query);

            $user->bindValue('userName', $this->userName);
            $user->bindValue('userEmail', $this->userEmail);
            $user->bindValue('userMobile', $this->userMobile);
            $user->bindValue('country', $this->country);
            $user->bindValue('password', $this->password);
            $user->bindValue('reg_date', $this->reg_date);
            $user->bindValue('validity', $this->validity);
            $user->bindValue('purchase_date', $this->purchase_date);
            $user->bindValue('purchase_id', $this->purchase_id);
            $user->bindValue('flag', $this->flag);

            if ($user->execute()) {
                $id = $this->connection->lastInsertId();
                return $id;
            }

            return 0;
        } catch (PDOException $e) {
            echo "Error in user registration: " . $e->getMessage();
        }
    }

public function addUser($params)
{
    try {
        $this->userName = $params['userName'];
        $this->userEmail = $params['userEmail'];
        $this->userMobile = $params['userMobile'];
        $this->country = $params['country'];
        $this->parentId = $params['parentId'];
        $this->password = $params['password']; 
        //$this->validity = $params['validity']; 

        // Check if email already exists for the given parentId
        $queryCheck = 'SELECT COUNT(*) AS count FROM ' . $this->table . ' WHERE userEmail = :userEmail AND parentId = :parentId';
        $stmtCheck = $this->connection->prepare($queryCheck);
        $stmtCheck->bindValue('userEmail', $this->userEmail);
        $stmtCheck->bindValue('parentId', $this->parentId);
        $stmtCheck->execute();

        $result = $stmtCheck->fetch(PDO::FETCH_ASSOC);
        if ($result['count'] > 0) {
                throw new Exception('Email already exists for this parentId');
	}

        // Insert the new user
        $query = 'INSERT INTO ' . $this->table . ' 
                  SET userName = :userName, parentId = :parentId, userEmail = :userEmail, 
                      userMobile = :userMobile, country = :country, password = :password';
                      //, validity = :validity

        $user = $this->connection->prepare($query);
        $user->bindValue('userName', $this->userName);
        $user->bindValue('userEmail', $this->userEmail);
        $user->bindValue('userMobile', $this->userMobile);
        $user->bindValue('parentId', $this->parentId);
        $user->bindValue('country', $this->country);
        $user->bindValue('password', $this->password);
        //$user->bindValue('validity', $this->validity);

	if ($user->execute()) {
                $id = $this->connection->lastInsertId();
                return $id;
            }

            return 0;
    } catch (PDOException $e) {
        throw new Exception('Error adding user: ' . $e->getMessage());
    }
}


   
public function deactivateUser($id, $status)
{
    try {
        $query = 'UPDATE ' . $this->table . ' SET status = ? WHERE id = ?';

        $stmt = $this->connection->prepare($query);

        // Ensure the correct order of parameters (status first, then id)
        $stmt->execute([$status, $id]);

        if ($stmt->rowCount() > 0) {
            return ['success' => true, 'message' => 'User deactivated'];
        } else {
            return ['success' => false, 'message' => 'No changes made or user not found'];
        }
    } catch (PDOException $e) {
        // Include specific error handling for PDOException
        return ['success' => false, 'message' => 'Error updating user: ' . $e->getMessage()];
    }
}



public function getUsersByParentId($params)
{
    try {

        if (!$this->connection) {
            throw new Exception("Database connection is null.");
        }

        if (!isset($params['parentId']) || empty($params['parentId'])) {
            throw new Exception("parentId is required.");
        }

        $parentId = $params['parentId'];

        $query = "SELECT
                    id,
                    userName,
                    userEmail,
                    userMobile,
                    country,
                    password,
                    parentId,
                    status,
                    reg_date,
                    validity,
                    purchase_date,
                    purchase_id,
                    flag
                  FROM {$this->table}
                  WHERE parentId = :parentId
                  ORDER BY id DESC";

        $stmt = $this->connection->prepare($query);

        $stmt->bindValue(':parentId', $parentId, PDO::PARAM_INT);

        $stmt->execute();

        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return $users;

    } catch (PDOException $e) {

        throw new Exception("Database Error: " . $e->getMessage());

    } catch (Exception $e) {

        throw new Exception($e->getMessage());

    }
}

public function updateSubUser($parentEmail, $id, $email, $password)
{
    try {
        // Fetch all emails associated with the given parentEmail
        $query = 'SELECT userEmail FROM ' . $this->table . ' WHERE parentId = (SELECT id FROM ' . $this->table . ' WHERE userEmail = ?)';
        $stmt = $this->connection->prepare($query);
        $stmt->execute([$parentEmail]);
        $emails = $stmt->fetchAll(PDO::FETCH_COLUMN);

        // Check if the provided email already exists in the list
        if (in_array($email, $emails)) {
            throw new Exception('The email is already in use.');
        }

        // Update the email and password for the given id
        $updateQuery = 'UPDATE ' . $this->table . ' SET userEmail = ?, password = ? WHERE id = ?';
        $updateStmt = $this->connection->prepare($updateQuery);

        // Hash the password before saving
        $updateStmt->execute([$email, $password, $id]);

        // Check if the update affected any rows
        if ($updateStmt->rowCount() > 0) {
            return true; // Indicate success
        } else {
            throw new Exception('No changes made or user not found.');
        }
    } catch (PDOException $e) {
        throw new Exception('Database error: ' . $e->getMessage());
    } catch (Exception $e) {
        throw $e; // Rethrow the exception for the controller to handle
    }
}

    public function updatePassword($params)
    {
        try {
            $userEmailMobile = $params['userEmailMobile'];
            $newPassword = $params['newPassword'];

            // Prepare the update query
            $updateQuery = '
            UPDATE ' . $this->table . ' 
            SET password = :password 
            WHERE userEmail = :userEmail 
            LIMIT 1';

            $updateStmt = $this->connection->prepare($updateQuery);

            // Bind parameters for the update query
            $updateStmt->bindValue(':password', $newPassword);
            $updateStmt->bindValue(':userEmail', $userEmailMobile);

            // Execute the update query
            if ($updateStmt->execute()) {
                return $updateStmt->rowCount() > 0; // Return true if a row was updated
            }

            return false; // No rows were updated
        } catch (PDOException $e) {
            throw new Exception("Error updating password: " . $e->getMessage());
        }
    }

public function updateSubUserPassword($params)
{
    try {
        $userId = $params['id'];
        $newPassword = $params['newPassword'];

        // Prepare the update query
        $updateQuery = '
        UPDATE ' . $this->table . ' 
        SET password = :password 
        WHERE id = :id 
        LIMIT 1';

        $updateStmt = $this->connection->prepare($updateQuery);

        // Bind parameters for the update query
        $updateStmt->bindValue(':password', $newPassword);
        $updateStmt->bindValue(':id', $userId);

        // Execute the update query
        if ($updateStmt->execute()) {
            return $updateStmt->rowCount() > 0; // Return true if a row was updated
        }

        return false; // No rows were updated
    } catch (PDOException $e) {
        throw new Exception("Error updating password: " . $e->getMessage());
    }
}
}
