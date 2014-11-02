/*

TRUESKILL RANKING SYSTEM

A TF2 adapted implementation of the ever popular
trueskill ranking system.

Author: Yusuf Ali

requires:
	socket - interact with python trueskill server

*/

#include <sourcemod>
#include <dbi>
#include <tf2_stocks>

#include <updater>
#include <steamtools>
#include <morecolors>

#define UPDATE_URL 	"http://playtf2.com/tf2Skill/updatefile.txt"
#define PLUGIN_NAME	"TrueSkill Ranking System"
#define AUTHOR 		"Yusuf Ali"
#define VERSION 	"3.0"
#define URL 		"https://github.com/yusuf-a/tf2Skill"
#define STEAMID	64
#define QUERY_SIZE   512
#define INTERVAL	0.15
#define steam64 AuthId_SteamID64

Handle db;
Handle players_stats;
Handle players_times;
Handle players;
int game_start = 0;
int track_game = 0;
int client_count = 0;

/* define convars */
Handle sm_minClients = INVALID_HANDLE;
Handle sm_server = INVALID_HANDLE;
Handle sm_minGlobal = INVALID_HANDLE;

/* delcare plublic variable information */
public Plugin myinfo = {name = PLUGIN_NAME,author = AUTHOR,description = "",version = VERSION,url = URL};

public OnPluginStart(){
	/* connect to database */
	char error[255];
	db = SQL_DefConnect(error,sizeof(error));

	/* add to updater */
	if (LibraryExists("updater")){
		Updater_AddPlugin(UPDATE_URL);
	}

	/* define convars */
	CreateConVar("sm_trueskill_version",VERSION,"public CVar shows the plugin version");
	sm_minClients = CreateConVar("sm_trueskill_minClients","16","Minimum clients to track ranking");
	sm_server = CreateConVar("sm_trueskill_server","http://yusufali.ca/update.php","remote path to trigger rank calculations");
	sm_minGlobal = CreateConVar("sm_trueskill_global","50","Minimum rank for global display, 0 for off");

	/* bind methods to game events */
	HookEvent("player_team",Event_pTeam);
	HookEvent("teamplay_round_start", Event_rStart);
	HookEvent("teamplay_round_win",Event_rEnd);
	HookEvent("player_disconnect", Event_pDisconnect);
	HookEvent("player_death", Event_pDeath);
	RegConsoleCmd("sm_rank",playRank);
    
	players_stats = CreateArray(20,0);
	players_times = CreateArray(2,0);
	players = CreateArray(STEAMID,0);
}

public OnLibraryAdded(const char name[]){
	 if (StrEqual(name, "updater"))
	 {
		  Updater_AddPlugin(UPDATE_URL)
	 }
}

/* METHODS FOR GAME EVENTS */

public Event_pDeath(Handle event, const char name[], bool dontBroadcast){
	/* only if tracking game */
	if(!track_game)
		return;

	/* ensure not a fake death */
	if( GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		return;
	
	decl atker[20]; decl victm[20];

	/* get client index */
	new killer = GetClientOfUserId( GetEventInt(event, "attacker") );
	new victim = GetClientOfUserId( GetEventInt(event, "userid") );

	/* ensure not suicide */
	if(killer == victim)
		return;

	/* ensure client index is valid */
	if(killer*victim <= 0 || killer > MaxClients || victim > MaxClients)
		return;

	/* get client roles */
	TFClassType killer_role = TF2_GetPlayerClass( killer );
	TFClassType victim_role = TF2_GetPlayerClass( victim );

	/* get adt_array index and old stats */
	killer = getPlayerID(killer); 
	victim = getPlayerID(victim);
	GetArrayArray( players_stats, killer, atker, sizeof(atker) );
	GetArrayArray( players_stats, victim, victm, sizeof(victm) );

	/* increment data */
	atker[killer_role]++;
	victm[victim_role + TFClassType:10]++;

	/* store into <adt_array> player_stats */
	SetArrayArray( players_stats, killer, atker, sizeof(atker) );
	SetArrayArray( players_stats, victim, victm, sizeof(victm) );
}

/*
	- keep track of clients disconnecting
	- update client playing time
*/
public Event_pDisconnect(Handle event, const char name[], bool dontBroadcast){
	if(!track_game)
		return;

	client_count--;
}

/*
	- keep tract of client playing time
	- update client playing time
*/
public Event_pTeam(Handle event, const char name[], bool dontBroadcast){
	new oTeam = GetEventInt(event,"oldteam");
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	/* ensure its a legit client */
	if(IsFakeClient(client))
		return;
	
	/* get steamID */
	char steamID[STEAMID];
	GetClientAuthId(client, AuthIdType:steam64, steamID, STEAMID)	
	new player = getPlayerID( client );

	/* get player name */
	char playerName[MAX_NAME_LENGTH *2 +1];
	GetClientName( client, playerName, MAX_NAME_LENGTH );
	SQL_EscapeString(db,playerName,playerName,sizeof(playerName));

	/* determine if player switched teams or joined */
	if(oTeam != _:TFTeam_Red && oTeam != _:TFTeam_Blue){
		client_count++;

		/* add to database, and update last connect */
		decl String:query[QUERY_SIZE];
		Format(query,sizeof(query),
		"insert into players (steamID,name) values (%d,'%s') on duplicate key \
		update lastConnect = now() AND name = '%s';",
			steamID,playerName,playerName);
		SQL_TQuery(db,T_query,query,0);

		/* ensure we are tracking data */
		if(!track_game)
			return;

		/* otherwise populate the arrays */
		if(player == -1){
		  PushArrayString(players,steamID);
		  player = FindStringInArray(players,steamID);
		  PushArrayArray(players_times,{0.0,0.0});
		  PushArrayArray(players_stats,{0,0,0,0,0,0,0,0,0,0,
		  								0,0,0,0,0,0,0,0,0,0});
		}

		/* create timer */
		CreateTimer( INTERVAL, UpdateTimes, client, TIMER_REPEAT);
	}
}

/*
	- reset arrays, grab client information
	 - structure data
*/
public Event_rStart(Handle event, const char name[], bool dontBroadcast){
	/* restart required variables */
	game_start = GetTime(); client_count = 0;
	ClearArray(players); ClearArray(players_times);
	ClearArray(players_stats); 
	
	char steam_id[STEAMID];

	//loop through all players that are alive
	for(new i=1;i<= MaxClients;i++){
		/* ensures client is connected */
		if( (IsClientInGame(i))  && (!IsFakeClient(i)) ){
			client_count++;
			GetClientAuthId( i, AuthIdType:steam64, steam_id, STEAMID) 

			PushArrayString(players,steam_id);
			PushArrayArray(players_times,{0.0,0.0});
			PushArrayArray(players_stats,{0,0,0,0,0,0,0,0,0,0,
											0,0,0,0,0,0,0,0,0,0});

			/* create timer */
			CreateTimer(INTERVAL, UpdateTimes,i,TIMER_REPEAT);
		}
	}

	// determine if to track the game or not
	track_game  = (client_count >= GetConVarInt(sm_minClients));

	// ensure database is connected 
	if( db == INVALID_HANDLE )
		track_game = 0;
}

/*
	- finalize client data, playing time, teams etc
	 - post data to trueskill implementation
*/
public Event_rEnd(Handle event, const char namep[], bool dontBroadcast){
	/* ensure this game is to be tracked */
	if(!track_game)
		return;

	/* declare useful buffers */
	char steam_id[STEAMID];
	char query[QUERY_SIZE];
	float player_time[2];
	int player_stat[20];

	track_game = 0;

	/* declare useful comparison */
	int result = GetEventInt(event,"team");
	int random = GetRandomInt(0,400);
	float gameDuration = float(GetTime() - game_start);

	/* ensure that the game was not a farm fest */
	if (GetArraySize(players) < 24 && client_count < GetConVarInt(sm_minClients)) 
		return;

	for(new i=0;i<GetArraySize(players);i++){
		/* store player data into buffers */
		GetArrayArray( players_stats,i,player_stat,sizeof(player_stat) );
		GetArrayArray( players_times,i,player_time,sizeof(player_time) );
		GetArrayString(players,i,steam_id,sizeof(steam_id));

		float blue = player_time[1];
		float red = player_time[0];
		
		int lastQuery = 0
		if( i == (GetArraySize(players) - 1 ) ){
			lastQuery = random;
		}

		/* insert data into database */
		Format(query,sizeof(query),"INSERT INTO `temp` (steamid,time_blue,time_red,result,random) \
		 VALUES(%d,%f,%f,%d,%d);", steam_id,blue/gameDuration, red/gameDuration,result,random);
		SQL_TQuery(db,T_query,query,  lastQuery  );

		/* loop through role stats and store into mysql */
		for(new j=0; j<10; j++){
			new role = j;
			new kills = player_stat[j];
			new deths = player_stat[j+10];

			if(kills == 0 && deths == 0)
				continue;
			
			/* build query and insert into database */
			Format(query, sizeof(query), 
				"INSERT INTO `player_stats` (stat_id,steamID,roles,kills,deaths) VALUES ('%d:%d',%d,%d,%d,%d) \
				ON DUPLICATE KEY UPDATE kills = kills + %d, deaths = deaths + %d;",
				steam_id,role,steam_id,role,kills,deths,kills,deths);
			SQL_TQuery(db,T_query,query,0);
		}
	}
}



/* REGISTERED ACTION COMMANDS */

/*
	gets player rank from trueskill
	database implementation
*/
public Action playRank(client, args){
	char steamID[STEAMID];
	GetClientAuthId( client, AuthIdType:steam64, steamID, STEAMID )

	char query[QUERY_SIZE];
	Format(query,sizeof(query),
		"select count(*) rank, 30*my.rank + 1500 from players my left join players others \
		on others.rank >= my.rank where my.SteamID = %d;", steamID);

	SQL_TQuery( db,rank_query,query,client );
	
	return Plugin_Handled;
}

public rank_query(Handle owner,Handle hndl,const char error[], any client){
	int rank = 0; 
	float sigma = 100.0;
	char name[MAX_NAME_LENGTH];

	if(!IsClientInGame(client)){
		return;
	}
	if(hndl == INVALID_HANDLE){
		printTErr(hndl,error);
	}
	else{
		while(SQL_FetchRow(hndl)){
			rank = SQL_FetchInt(hndl,0); 
			sigma = SQL_FetchFloat(hndl,1);
		}

		if(rank <= GetConVarInt(sm_minGlobal) && sigma > 0 ){
			GetClientName(client,name,sizeof(name));
			CPrintToChatAll("Player: {green}%s {normal}Rank: {green}%d {normal}with {green}%.0f {normal}Elo",
				name,rank,sigma);
		}
		else{
			CPrintToChat(client, "Rank {green}#%d {normal} with {red}%.0f {normal}Elo", rank,sigma);
		}
	}
}

/* UTILITY COMMANDS */

public Action UpdateTimes(Handle timer,any client){
	/* ensure tracking game */
	if(!track_game || !IsClientConnected(client))
		return Plugin_Stop;

	if(!IsClientInGame(client))
		return Plugin_Stop;

	/* get player id in array */
	new player = getPlayerID( client );

	/* get the required data array information */
	float player_time[2];
	GetArrayArray( players_times,player,player_time,sizeof(player_time) ); 

	/* determine which team counter to increment */
	switch (GetClientTeam(client)){
		case (_:TFTeam_Red): {
			player_time[0] = player_time[0] + INTERVAL;
		}

		case (_:TFTeam_Blue): {
			player_time[1] = player_time[1] + INTERVAL;
		}
	}
	/* store array back into adt */
	SetArrayArray( players_times,player,player_time,sizeof(player_time) );

	return Plugin_Continue;
}


/* prints an error given handle and error string */
printTErr(Handle hndle,const char error[]){
	if(hndle == INVALID_HANDLE){
		LogError("TrueSkill - Query Failed: %s",error);
		return 0;
	}
	return 1;
}

/* typical threaded query prototype */
public T_query( Handle owner,Handle hndle,const char error[], any gameNumber ){
	printTErr(hndle, error );
	
	/* that means all data is in temp table */
	if( gameNumber !=  0){
		/* format convar update url */
		char updateURL[200]
		GetConVarString( sm_server, updateURL, sizeof(updateURL) )
		Format( updateURL, sizeof(updateURL) ,  "%s?game=%d", updateURL, gameNumber )

		/* post to remote server */
		HTTPRequestHandle req = Steam_CreateHTTPRequest( HTTPMethod_GET, updateURL )
		Steam_SendHTTPRequest( req, onComplete )
	}
}

public onComplete( HTTPRequestHandle req, bool success, HTTPStatusCode status ){
	if( !success || status != HTTPStatusCode_OK ){
		LogError("TrueSkill - Remote Post Failed")
		return
	}

	Steam_ReleaseHTTPRequest( req )
}

/* returns player id */
public getPlayerID( client ){
	char steam_id[STEAMID]
	GetClientAuthId( client, AuthIdType:steam64, steam_id, STEAMID )
	return FindStringInArray( players, steam_id );
}
