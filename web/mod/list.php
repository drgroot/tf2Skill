<?php
	require 'config.php';

	$conn = new mysqli($host, $username, $password, $database, $port);
	if( $conn->connect_error ){
		die("Connection failed: " . $conn->connect_error);
	}

	$results = array();

	
	$page = ( isset($_POST['page']) )? $_POST['page'] : 1;
	$result = $conn->query($queryPlayers . (15*$page));

	$i = 15 * ($page-1);
	while( $row = $result->fetch_assoc() ){
		if( $i != 0){
			$i--;
			continue;
		}

		/* fix variable types */
		$row['player_id'] = (int) $row['player_id'];
		$row['elo'] = (float) $row['elo'];
		$row['kills'] = (int) $row['kills'];
		$row['deaths'] = (int) $row['deaths'];
		
		array_push( $results, $row );
	}


	echo json_encode( $results );

	$conn->close();
?>