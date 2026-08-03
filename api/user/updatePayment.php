<?php 

	require_once 'DbConnect.php';
	
	//an array to display response
	$response = array();
	
	//if it is an api call 
	//that means a get parameter named api call is set in the URL 
	//and with this parameter we are concluding that it is an api call
	
	
	
				//for payment we need the username and password 
				
					
					//getting the values 
					$id = $_POST['id'];
					$validity = $_POST['validity'];
					$purchase_date = $_POST['purchase_date'];
					$purchase_id = $_POST['purchase_id'];
					$flag = '1';
					
					
							
					//fetching the user back 
					$stmt = $conn->prepare("UPDATE registration SET validity=?, purchase_date=?, purchase_id=?, flag=? WHERE id=? "); 
					$stmt->bind_param("sssss",$validity, $purchase_date, $purchase_id, $flag, $id);
					$stmt->execute();
					
							
					
							
					//adding the user data in response 
					$response['error'] = false; 
					$response['message'] = 'User successfully upgraded...Please Login again!!'; 
					$response['flag'] = $flag;
					//$response['user'] = $user; 
					$response['id'] = $id;
					//$stmt->close();
					
					
					
					
					
					
				echo json_encode($response);
				
				
?> 