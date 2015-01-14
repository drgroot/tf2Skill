public Event_pTeam( Handle event, const char[] name, bool dontBroadcast){
	int oTeam = GetEventInt( event,"oldteam" )
	int cTeam = GetEventInt( event, "team" )
	int userid = GetEventInt( event,"userid" )
	int client  = GetClientOfUserId( userid )

	/* ensure its a legit client */
	if( IsNotClient(client) )
		return
	
	/* get steamID */
	char steamID[STEAMID]
	steamID = getSteamID( client )
	int player = getPlayerID( client )

	/* get player name */
	char playerName[MAX_NAME_LENGTH *2 +1]
	GetClientName( client, playerName, MAX_NAME_LENGTH	)
	SQL_EscapeString( db, playerName, playerName,sizeof( playerName )	)

	/* determine if player switched teams or joined */
	if(oTeam != _:TFTeam_Red && oTeam != _:TFTeam_Blue){
		
		/* add to database, and update last connect */
		char query[QUERY_SIZE]
		Format(	query, sizeof(query), 
"INSERT INTO PLAYERS (steamID,name) VALUES ('%s','%s') ON DUPLICATE KEY UPDATE NAME = '%s'" 
			, steamID, playerName, playerName	)
		
		SQL_TQuery(db,T_query,query,0)

		/* only if tracking game */
		if( !track_game )
			return

		/* otherwise populate the arrays */
		if(player == -1){
			PushArrayString( players, steamID )
			PushArrayArray(players_times, { 0, 0, 0, 0 } )
			PushArrayArray(players_stats,{0,0,0,0,0,0,0,0,0,0,
		  								0,0,0,0,0,0,0,0,0,0})
			player = FindStringInArray( players, steamID )
		}
	}

	updateTimes( player, cTeam, oTeam, 0 )
}