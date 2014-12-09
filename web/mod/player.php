<?php
	require 'config.php';

	$conn = new mysqli($host, $username, $password, $database, $port);
	if( $conn->connect_error ){
		die("Connection failed: " . $conn->connect_error);
	}

	$player = array();
	$classes = array('spec','scout','sniper','soldier','demoman','medic','heavy','pyro','spy','engineer');
	
	$player_id = ( isset($_POST['player_id']) )? (int)$_POST['player_id'] : 1;
	
	$result = $conn->query($getPlayerVitals. $player_id);
	while( $row = $result->fetch_assoc() ){
		$row['mu'] = (float)$row['mu'];
		$row['sigma'] = (float)$row['sigma'];
		$row['elo'] = (float)$row['elo'];
		$player = $row;
	}

	$result = $conn->query($getBest);
	while( $row = $result->fetch_assoc() ){
		$player['bestMu'] = (float)$row['mu'];
		$player['bestSigma'] = (float)$row['sigma'];
	}

	$steamID = $player['steamID'];
	$player['death'] = array();
	$player['kill'] = array();
	$player['kills'] = 0;
	$player['deaths'] = 0;

	$result = $conn->query($getKillStat . "'$steamID'");
	while( $row = $result->fetch_assoc() ){
		$role = $classes[(int)$row['roles']];
		$kills = (int) $row['kills'];
		$deaths = (int) $row['deaths'];

		array_push( $player['kill'],  array($role, $kills) );
		array_push( $player['death'], array($role, $deaths) );

		$player['kills'] += $kills;
		$player['deaths'] += $deaths;
	}

	echo json_encode($player);

	$conn->close();
?>