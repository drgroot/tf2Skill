public Event_rEnd( Handle event, const char[] namep, bool dontBroadcast){
	/* ensure this game is to be tracked */
	if(!track_game)
		return

	/* declare useful buffers */
	char query[QUERY_SIZE]
	int player_time[4]
	int player_stat[20]
	char steam_id[STEAMID]

	/* declare useful comparison */
	int result = GetEventInt( event,"team" )
	int random = GetRandomInt( 1, 999 )
	int curTime = GetTime()
	int gameDuration = curTime - roundStart

	for(int i=0; i<GetArraySize(players); i++){

		updateTimes( i, 0, 0, curTime )
		int last = (i == GetArraySize(players) -1)

		/* store player data into buffers */
		GetArrayArray( players_stats,i,player_stat,sizeof(player_stat) );
		GetArrayArray( players_times,i,player_time,sizeof(player_time) );
		GetArrayString( players,i,steam_id, STEAMID );

		/* get team time ratio */
		float blu = float( player_time[1] )/gameDuration
		float red = float( player_time[0] )/gameDuration
	
		/* insert data into database */
		Format( query,sizeof(query), 
"INSERT INTO `temp` (steamid,time_blue,time_red,result,random) VALUES('%s',%f,%f,%d,%d)" , 
			steam_id, blu , red , result, random )

		SQL_TQuery( db,T_query, query, last * random )

		/* loop through role stats and store into mysql */
		for(new j=0; j<10; j++){

			new role = j;
			new kills = player_stat[j]
			new deths = player_stat[j+10]

			if(kills == 0 && deths == 0)
				continue
			
			/* build query and insert into database */
			Format( query, sizeof(query), 
"INSERT INTO `player_stats` (stat_id,steamID,roles,kills,deaths) VALUES ('%s.%d','%s',%d,%d,%d) ON DUPLICATE KEY UPDATE kills = kills + %d, deaths = deaths + %d"
				, steam_id, role, steam_id, role, kills, deths, kills, deths );
			
			SQL_TQuery( db,T_query,query,0 )
		}
	}
	track_game = 0
}