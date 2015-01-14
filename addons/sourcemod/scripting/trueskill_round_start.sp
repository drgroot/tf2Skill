public Event_rStart( Handle event, const char[] name, bool dontBroadcast ){
	/* restart required variables */
	roundStart = GetTime()
	ClearArray( players_stats )
	ClearArray( players_times )
	ClearArray( players )
	int client_count = 0

	if( track_elo == 0 ){
		track_game = 0
		return
	}

	int new_player[4] = {0, 0, 0, 0}
	new_player[3] = roundStart

	//loop through all players that are alive
	for(new i=1;i<= MaxClients;i++){
		if( IsNotClient(i) )
			continue

		client_count++
		new_player[2] = GetClientTeam( i )
			
		PushArrayString( players, getSteamID( i, false ) )
		PushArrayArray( players_times, new_player )
		PushArrayArray( players_stats,{0,0,0,0,0,0,0,0,0,0,
											0,0,0,0,0,0,0,0,0,0} )
	}

	/* determine if to track the game or not */
	track_game  = (	client_count >= GetConVarInt(sm_minClients)	)

	/* ensure database is connected */
	if( db == null )
		track_game = 0
}