<?php

	$group = $_GET["group"];
	$output = shell_exec("python trueSkill.py --group $group");
	echo "$output";
?>	
