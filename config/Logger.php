<?php

class Logger
{
    /**
     * Log any activity to the records table.
     *
     * @param PDO          $connection  Shared DB connection.
     * @param int          $userId      Who performed the action.
     * @param string       $entityType  What was acted on: 'stock', 'sale', 'order', etc.
     * @param int          $entityId    ID of the entity acted on.
     * @param string       $status      'created', 'edited', 'deleted', 'sold', 'refunded'
     * @param string       $user        Deprecated — kept for backward compatibility, not used.
     * @param array|string $payload     Any extra context relevant to this entity type.
     */
    public static function log(
        $connection,
        $userId,
        $entityType,
        $entityId,
        $status,
        $user    = 'admin',  // kept for backward compatibility — value is ignored
        $payload = []
    ) {
        try {
            // -- 1. Fetch user details from registration table -------------

            $userQuery = $connection->prepare("
                SELECT parentId
                FROM   registration
                WHERE  id = :id
                LIMIT  1
            ");

            $userQuery->execute(['id' => $userId]);
            $userData = $userQuery->fetch(PDO::FETCH_ASSOC);

            // -- 2. Resolve role -------------------------------------------
            //    parentId set  ? sub-user
            //    parentId null ? admin

            $role = !empty($userData['parentId']) ? 'sub-user' : 'admin';

            // -- 3. Normalize payload --------------------------------------

            if (is_string($payload)) {
                $payload = json_decode($payload, true) ?? [];
            }

            $payloadJson = json_encode($payload);

            // -- 4. Backward-compatibility shims --------------------------

            $stockId = ($entityType === 'stock') ? $entityId : null;
            $qty     = $payload['qty'] ?? $payload['stockQuantity'] ?? 0;

            // -- 5. Insert record ------------------------------------------

            $stmt = $connection->prepare("
                INSERT INTO records (
                    userId,
                    stockId,
                    entityType, entityId,
                    qty, status, user, payload
                ) VALUES (
                    :userId,
                    :stockId,
                    :entityType, :entityId,
                    :qty, :status, :user, :payload
                )
            ");

            $stmt->bindParam(':userId',     $userId,      PDO::PARAM_INT);
            $stmt->bindParam(':stockId',    $stockId,     PDO::PARAM_INT);
            $stmt->bindParam(':entityType', $entityType,  PDO::PARAM_STR);
            $stmt->bindParam(':entityId',   $entityId,    PDO::PARAM_INT);
            $stmt->bindParam(':qty',        $qty,         PDO::PARAM_INT);
            $stmt->bindParam(':status',     $status,      PDO::PARAM_STR);
            $stmt->bindParam(':user',       $role,        PDO::PARAM_STR);
            $stmt->bindParam(':payload',    $payloadJson, PDO::PARAM_STR);

            $stmt->execute();

        } catch (Exception $e) {
            // Never let a logging failure break the main application flow.
            error_log('Logger error: ' . $e->getMessage());
        }
    }
}