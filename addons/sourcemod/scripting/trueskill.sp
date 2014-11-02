/*

TRUESKILL RANKING SYSTEM

A TF2 adapted implementation of the ever popular
trueskill ranking system.

Author: Yusuf Ali

*/

#include <sourcemod>
#include <dbi>
#include <tf2_stocks>
#include <updater>
#include <steamtools>
#include <morecolors>

#define UPDATE_URL 	"http://playtf2.com/mng_playtf2/addons/sourcemod/updatefile.txt"
#define PLUGIN_NAME	"TrueSkill Ranking System"
#define AUTHOR 		"Yusuf Ali"
#define VERSION 	"3.0"
#define URL 		"https://github.com/yusuf-a/tf2Skill"
#define STEAMID		20
#define QUERY_SIZE   512
#define INTERVAL	0.15
#define steam64 AuthId_SteamID64

Handle db				// database handle
Handle players_stats	// player k:d storage variable
Handle players_times	// player time storage variable
Handle players			// player ids variable		
game_start = 0			// time of round start
track_game = 0			// track game or not

/* define convars */
Handle sm_minClients = null
Handle sm_url = null
Handle sm_minGlobal = null

/* delcare plublic variable information */
public Plugin myinfo = {name = PLUGIN_NAME,author = AUTHOR,description = "",version = VERSION,url = URL};

public OnPluginStart(){
	/* connect to database */
	char error[255]
	db = SQL_DefConnect(error,sizeof(error))

	/* add to updater */
	if(	LibraryExists( "updater" )	){
		Updater_AddPlugin(UPDATE_URL)
	}

	/* define convars */
	CreateConVar("sm_trueskill_version",VERSION,"public CVar shows the plugin version",FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED)
	sm_minClients = CreateConVar("sm_trueskill_minClients","16","Minimum clients to track ranking", FCVAR_NOTIFY)
	sm_url = CreateConVar("sm_trueskill_url","http://server/trueskill.php","url to trueskill", FCVAR_PROTECTED)
	sm_minGlobal = CreateConVar("sm_trueskill_global","50","Minimum rank for global display, 0 for off", FCVAR_NOTIFY)

	/* bind methods to game events */
	HookEvent("player_team",Event_pTeam)
	HookEvent("teamplay_round_start", Event_rStart)
	HookEvent("teamplay_round_win",Event_rEnd)
	HookEvent("player_death", Event_pDeath)
	RegConsoleCmd("sm_rank",playRank)
    
	players_stats = CreateArray( 20,0 )
	players_times = CreateArray( 2,0 )
	players = CreateArray( 1,0 )
}
public OnLibraryAdded(	const char name[]	){
	 if(	StrEqual( name, "updater" )	){
		Updater_AddPlugin(UPDATE_URL)
	 }
}

/* METHODS FOR GAME EVENTS */
public Event_pDeath( Handle event, const char name[], bool dontBroadcast){
	/* only if tracking game */
	if(!track_game)
		return

	/* ensure not a fake death */
	if( GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		return
	
	int atker[20]
	int victm[20]

	/* get client index */
	new killer = GetClientOfUserId( GetEventInt(event, "attacker") )
	new victim = GetClientOfUserId( GetEventInt(event, "userid") )

	/* ensure not suicide */
	if(killer == victim)
		return

	/* ensure client index is valid */
	if(killer*victim <= 0 || killer > MaxClients || victim > MaxClients)
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

/*
	- keep tract of client playing time
	- update client playing time
*/
public Event_pTeam( Handle event, const char name[], bool dontBroadcast){
	int oTeam = GetEventInt( event,"oldteam" )
	int client = GetClientOfUserId(	GetEventInt( event,"userid" )	)

	/* ensure its a legit client */
	if(IsFakeClient(client))
		return
	
	/* get steamID */
	int steamID = getSteamID( client )
	int player = getPlayerID( client )

	/* get player name */
	char playerName[MAX_NAME_LENGTH *2 +1]
	GetClientName( client, playerName, sizeof(playerName) )
	SQL_EscapeString( db,playerName,playerName,sizeof( playerName ) )

	/* determine if player switched teams or joined */
	if(oTeam != _:TFTeam_Red && oTeam != _:TFTeam_Blue){
		/* add to database, and update last connect */
		char query[QUERY_SIZE]
		Format(	query, sizeof(query),
		"insert into players (steamID,name) values (%d,'%s') on duplicate key \
		update lastConnect = now() AND name = '%s';",
			steamID,playerName,playerName)
		SQL_TQuery(db,T_query,query,0)

		/* ensure we are tracking data */
		if(!track_game)
			return

		/* otherwise populate the arrays */
		if(player == -1){
		  PushArrayCell( players, steamID )
		  player = FindValueInArray( players,steamID )
		  PushArrayArray(players_times,{0.0,0.0})
		  PushArrayArray(players_stats,{0,0,0,0,0,0,0,0,0,0,
		  								0,0,0,0,0,0,0,0,0,0})
		}

		/* create timer */
		CreateTimer( INTERVAL,UpdateTimes,client,TIMER_REPEAT );
	}
}

/*
	- reset arrays, grab client information
	 - structure data
*/
public Event_rStart( Handle event, const char name[], bool dontBroadcast ){
	/* restart required variables */
	game_start = GetTime(); 
	ClearArray(players); ClearArray(players_times)
	ClearArray(players_stats)
	int client_count = 0

	//loop through all players that are alive
	for(new i=1;i<= MaxClients;i++){
		/* ensures client is connected */
		if( IsClientInGame( i )  && !IsFakeClient( i ) ){
			client_count++
			int steam_id = getSteamID( i )

			PushArrayCell( players, steam_id )
			PushArrayArray( players_times,{0.0,0.0} )
			PushArrayArray( players_stats,{0,0,0,0,0,0,0,0,0,0,
											0,0,0,0,0,0,0,0,0,0} )

			/* create timer */
			CreateTimer( INTERVAL, UpdateTimes,i,TIMER_REPEAT )
		}
	}

	// determine if to track the game or not
	track_game  = (client_count >= GetConVarInt(sm_minClients))

	// ensure database is connected 
	if( db == INVALID_HANDLE )
		track_game = 0
}

/*
	- finalize client data, playing time, teams etc
	 - post data to trueskill implementation
*/
public Event_rEnd( Handle event, const char namep[], bool dontBroadcast){
	/* ensure this game is to be tracked */
	if(!track_game)
		return

	/* declare useful buffers */
	char query[QUERY_SIZE]
	float player_time[2]
	int player_stat[20]

	track_game = 0

	/* declare useful comparison */
	int result = GetEventInt( event,"team" )
	int random = GetRandomInt( 0,400 )
	float gameDuration = float( GetTime() - game_start )

	/* ensure that the game was not a farm fest */
	if( GetArraySize(players) < 24 ) 
		return

	for(int i=0; i<GetArraySize(players); i++){
		int last = (i == GetArraySize(players) -1)

		/* store player data into buffers */
		GetArrayArray( players_stats,i,player_stat,sizeof(player_stat) );
		GetArrayArray( players_times,i,player_time,sizeof(player_time) );
		int steam_id = GetArrayCell( players,i );

		float blue = player_time[1]
		float red = player_time[0]
	
		/* insert data into database */
		Format(query,sizeof(query),"INSERT INTO `temp` (steamid,time_blue,time_red,result,random) \
		 VALUES(%d,%f,%f,%d,%d)", steam_id,blue/gameDuration, red/gameDuration,result,random)
		SQL_TQuery( db,T_query,query, last * random )

		/* loop through role stats and store into mysql */
		for(new j=0; j<10; j++){
			new role = j;
			new kills = player_stat[j]
			new deths = player_stat[j+10]

			if(kills == 0 && deths == 0)
				continue
			
			/* build query and insert into database */
			Format(query, sizeof(query), 
				"INSERT INTO `player_stats` (stat_id,steamID,roles,kills,deaths) VALUES (%d.%d,%d,%d,%d,%d) \
				ON DUPLICATE KEY UPDATE kills = kills + %d, deaths = deaths + %d",
				steam_id,role,steam_id,role,kills,deths,kills,deths);
			SQL_TQuery( db,T_query,query,0 )
		}
	}
}
public T_query(Handle:owner,Handle:hndle,const String:error[],any:data){
	printTErr(hndle, error );

	if(data != 0){
		//post to url
	}
}



/*

	HANDLES WHEN PLAYER SAY !RANK

*/
public Action playRank(client, args){
	int steamID = getSteamID( client )

	char query[QUERY_SIZE]
	Format( query,sizeof(query),
		"select count(*) rank, 30*my.rank + 1500 from players my left join players others \
		on others.rank >= my.rank where my.SteamID = %d", steamID)

	SQL_TQuery(db, rank_query, query, GetClientUserId(client) )
	
	return Plugin_Handled
}
public rank_query(Handle:owner,Handle:hndl,const String:error[], any:data){
	int client = GetClientOfUserId(data)
	int rank = 0; float sigma = 100.0
	char name[MAX_NAME_LENGTH]

	if(!IsClientInGame(client)){
		return
	}
	if(hndl == INVALID_HANDLE){
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


/*
	
	HANDLES UPDATE TIME STUFF

*/
public Action:UpdateTimes(Handle:timer,any:client){
	/* ensure tracking game */
	if(!track_game || !IsClientConnected(client))
		return Plugin_Stop

	if(!IsClientInGame(client))
		return Plugin_Stop

	/* get player id in array */
	int player = getPlayerID(client)

	/* get the required data array information */
	float player_time[2];
	GetArrayArray(players_times,player,player_time,sizeof(player_time)); 

	/* determine which team counter to increment */
	switch (GetClientTeam(client)){
		case (_:TFTeam_Red): {
			player_time[0] = player_time[0] + INTERVAL
		}

		case (_:TFTeam_Blue): {
			player_time[1] = player_time[1] + INTERVAL
		}
	}
	/* store array back into adt */
	SetArrayArray(players_times,player,player_time,sizeof(player_time));

	return Plugin_Continue;
}

/* prints an error given handle and error string */
printTErr(Handle:hndle,const String:error[]){
	if(hndle == INVALID_HANDLE){
		LogError("TrueSkill - Query Failed: %s",error);
		return 0;
	}
	return 1;
}


/*

	PlayerID / SteamID Functions

*/
int getSteamID( client ){
	char steam_id[STEAMID]
	GetClientAuthId( client, AuthIdType:steam64 , steam_id, STEAMID )
	return StringToInt( steam_id )
}
int getPlayerID( client ){
	return FindValueInArray( players, getSteamID( client ) )
}