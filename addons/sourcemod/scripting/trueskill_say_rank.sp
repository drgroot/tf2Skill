public Action playRank(client, args){
	char steamID[STEAMID]
	steamID = getSteamID( client )

	char query[QUERY_SIZE]
	Format( query,sizeof(query), 
"select count(*) rank, 30*my.rank + 1500 from players my left join players others on others.rank >= my.rank where my.SteamID = '%s'"
	, steamID 	)

	SQL_TQuery(db, rank_query, query, GetClientUserId(client) )
	
	return Plugin_Handled
}

public rank_query(Handle:owner,Handle:hndl,const String:error[], any:data){
	int client = GetClientOfUserId(data)
	int rank = 0; float sigma = 100.0
	char name[MAX_NAME_LENGTH]

	if( IsNotClient(client) )
		return
	
	if( hndl == null ){
		printTErr(hndl,error)
	}
	else{
		while(SQL_FetchRow(hndl)){
			rank = SQL_FetchInt(hndl,0)
			sigma = SQL_FetchFloat(hndl,1)
		}

		if(rank <= GetConVarInt(sm_minGlobal) && sigma > 0 ){
			GetClientName(client,name,sizeof(name))
			CPrintToChatAll("Player: {green}%s {normal}Rank: {green}%d {normal}with {green}%.0f {normal}Elo",
				name,rank,sigma)
		}
		else{
			CPrintToChat(client, "Rank {green}#%d {normal} with {red}%.0f {normal}Elo", rank,sigma)
		}
	}
}