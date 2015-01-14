public Event_pDeath( Handle event, const char[] name, bool dontBroadcast){
	/* only if tracking game */
	if( !track_game )
		return

	/* ensure not a fake death */
	if(	GetEventInt( event, "death_flags" ) & TF_DEATHFLAG_DEADRINGER	)
		return
	
	int atker[20]
	int victm[20]

	/* get client index */
	int killer = GetClientOfUserId( GetEventInt(event, "attacker") )
	int victim = GetClientOfUserId( GetEventInt(event, "userid") )

	/* ensure not suicide */
	if( killer == victim )
		return

	/* ensure client index is valid */
	if(	killer*victim <= 0 || killer > MaxClients || victim > MaxClients )
		return

	/* get client roles */
	TFClassType killer_role = TF2_GetPlayerClass( killer )
	TFClassType victim_role = TF2_GetPlayerClass( victim )

	/* get adt_array index and old stats */
	killer = getPlayerID(killer); victim = getPlayerID(victim);
	GetArrayArray( players_stats, killer, atker, sizeof(atker) )
	GetArrayArray( players_stats, victim, victm, sizeof(victm) )

	/* increment data */
	atker[killer_role]++
	victm[victim_role + TFClassType:10]++

	/* store into <adt_array> player_stats */
	SetArrayArray( players_stats, killer, atker, sizeof(atker) )
	SetArrayArray( players_stats, victim, victm, sizeof(victm) )
}