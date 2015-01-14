public APLRes AskPluginLoad2(Handle me, bool late, char[] err, err_max){
	CreateNative( "trueskill_getElo", native_trueskill_getElo )
	CreateNative( "trueskill_enable", native_trueskill_enable )
	return APLRes_Success
}

public native_trueskill_enable( Handle plugin, numParams ){
	track_elo = GetNativeCell(1)
}

public native_trueskill_getElo( Handle plugin, numParams ){
	int user = GetNativeCell(1)

	int client = GetClientOfUserId( user )
	if( IsNotClient(client) )
		return ThrowNativeError( SP_ERROR_NATIVE, "Client not connected" )

	char query[QUERY_SIZE]
	Format( query, sizeof(query), 
"select 30*my.rank + 1500,%d,count(*) rank  from players my left join players others on others.rank >= my.rank where my.SteamID = '%s'" 
	, user, esc_getSteamID(client) )
	
	SQL_TQuery( db, native_callback, query, plugin )

	AddToForward( g_playerElo, plugin, GetNativeCell(2) )

	return 1
}

public native_callback( Handle o, Handle h, const char[] e, any plugin){
	float elo = 0.0
	int user = -1
	int rank = 0
	
	while(	SQL_FetchRow( h )	){
		elo = SQL_FetchFloat( h, 0 )
		user = SQL_FetchInt( h, 1 )
		rank = SQL_FetchInt( h, 2 )
	}

	Call_StartForward( g_playerElo )
	Call_PushCell( user )
	Call_PushFloat( elo )
	Call_PushCell( rank == 1 )
	Call_Finish()
	RemoveAllFromForward( g_playerElo, plugin )
}