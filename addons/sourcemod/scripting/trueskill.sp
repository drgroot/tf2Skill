/*

 TRUESKILL RANKING SYSTEM

 A TF2 adapted implementation of the ever popular
 trueskill ranking system.

 Author: Yusuf Ali

 YusufAli's TrueSkill Ranking System
 Copyright (C) 2014 YusufAli

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <trueskill>
#include <sourcemod>
#include <dbi>
#include <tf2_stocks>
#include <updater>
#include <steamtools>
#include <morecolors>

#define UPDATE_URL 	"http://dev.yusufali.ca/plugins/tf2Skill/master/"
#define PLUGIN_NAME	"TrueSkill Ranking System"
#define AUTHOR 		"Yusuf Ali"
#define VERSION 	"2.0"
#define URL 		"https://github.com/yusuf-a/tf2Skill"
#define STEAMID		32
#define QUERY_SIZE   512

/* MySQL Query definitions */
#define NEWPLAYER "insert into players (steamID,name) values ('%s','%s') on duplicate key update name = '%s';"
#define INTOTEMP "INSERT INTO `temp` (steamid,time_blue,time_red,result,random) VALUES('%s',%f,%f,%d,%d)"
#define STATS "INSERT INTO `player_stats` (stat_id,steamID,roles,kills,deaths) VALUES ('%s.%d','%s',%d,%d,%d) ON DUPLICATE KEY UPDATE kills = kills + %d, deaths = deaths + %d"
#define RANK "select count(*) rank, 30*my.rank + 1500 from players my left join players others on others.rank >= my.rank where my.SteamID = '%s'"

/*
	VARIABLE DOCUMENTATION

	db 				Database handle for MySQL connection

	players_stats 	Player kill and death storage variable
		structure: 	<playerID>	[array 0..19]
		the array has 20 elements (2 for every type of class)
		the first 10 are to store kills (1 index for each class)
		the last 10 are to store deaths (1 index for each class)

	players_times 	Player time storage variable
		structure:	<playerID>	[array 0..3]
		the array has 4 elements to store how long a player has been on a team
		0:	time on team red (in seconds)
		1:	time on team blu (in seconds)
		2:	int of the current team the player is on
		3:	time (using GetTime() ) that player joined current team
		the logic is that to maintain the time, simply subtract GetTime() 
		with [3] and append it to the team specified in [2]

	players 		Player Id Storage variable
		structure: 	<playerID>	<steamID>
		this is to find the player id (FindStringInArray)
		given the players steamID

	g_playerElo		foward to allow other plugins to get Elo of player
	roundStart 		using getTime(), the start of the round
	track_game		1 to track elo statistics, 0 to ignore


	What this plugin does:

	This plugin does the low level tracking to send data to the trueskill.py
	python script to calculate player ranks under the TrueSkill system.

	In order to do so, trueskill.py needs 3 pieces of information from every 
	player who took part in the round:

	1. SteamID (uniquely desribe player)
	2. percent time on each time (eg: 40% on red, 60% on blue)
	3. which team won the round

	Additionally, this plugin tracks the kill and death statistics for each 
	player (not required, but a nice feature)

	How this plugin operates:

	1. At the start of the round
		- reset all variables
		- beginning of round time is stored into roundStart
		- players are assigned a unique number (playerID) to their steamid
		- players information such as team and kill stats are initialized

	2. Player teamchanges/reconnects/disconnencts
		- the amount of time spent on the previous team is updated
		- the players current team is updated
		- the time of the event is updated
		- all of this is stored in players_times

	3. Player kills/dies
		- player kill/death stats are updated into players_stats

	4. round ends
		- round is assigned a random number (called 'random')
		- all player times on teams are updated
		- throws information (kill/death stats, aswell as required trueskill data) into mysql database identified by the round number
		- when insertation has been complete, a curl request is sent to the php file with the random number, initiating the python script to calculate player ranks

*/
Handle db = null	
Handle players_stats
Handle players_times
Handle players
Handle g_playerElo = null
int roundStart
int track_game = 0
	

/* define convars */
Handle sm_minClients = null
Handle sm_url = null
Handle sm_minGlobal = null


/* delcare plublic variable information */
public Plugin myinfo = {name = PLUGIN_NAME,author = AUTHOR,description = "",version = VERSION,url = URL};

public OnPluginStart(){
	/* connect to database */
	SQL_TConnect( gotDB, "default" )

	/* add to updater */
	if(	LibraryExists( "updater" )	){
		Updater_AddPlugin(UPDATE_URL)
	}

	/* define convars */
	CreateConVar("sm_trueskill_version",VERSION,"public CVar shows the plugin version",FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED)
	sm_minClients = CreateConVar("sm_trueskill_minClients","16","Minimum clients to track ranking", FCVAR_NOTIFY)
	sm_url = CreateConVar("sm_trueskill_url","http://server.com/trueskill.php","url to trueskill php file", FCVAR_PROTECTED)
	sm_minGlobal = CreateConVar("sm_trueskill_global","50","Minimum rank for global display, 0 for off", FCVAR_NOTIFY)

	/* bind methods to game events */
	HookEvent( "player_team", Event_pTeam )
	HookEvent( "teamplay_round_start", Event_rStart )
	HookEvent( "teamplay_round_win", Event_rEnd )
	HookEvent( "player_death", Event_pDeath )
	RegConsoleCmd( "sm_rank", playRank )
	g_playerElo = CreateForward( ET_Event, Param_Cell, Param_Float, Param_Cell )

	/* init arrays */
	players_stats = CreateArray( 20, 0 )
	players_times = CreateArray( 4, 0 )
	players = CreateArray( STEAMID, 0 )
}
public gotDB( Handle o, Handle h, const char[] e, any data){
	if( h == null )
		LogError("Database failure: %s", e)
	else
		db = h
}
public OnLibraryAdded(	const char[] name	){
	 if(	StrEqual( name, "updater" )	){
		Updater_AddPlugin( UPDATE_URL )
	 }
}
public Updater_OnPluginUpdated(){
	ReloadPlugin()
}
public APLRes AskPluginLoad2(Handle me, bool late, char[] err, err_max){
	CreateNative( "trueskill_getElo", native_trueskill_getElo )
	return APLRes_Success
}

/* METHODS FOR GAME EVENTS */
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

/*
	- reset arrays, grab client information
	 - structure data
*/
public Event_rStart( Handle event, const char[] name, bool dontBroadcast ){
	/* restart required variables */
	roundStart = GetTime()
	ClearArray( players_stats )
	ClearArray( players_times )
	ClearArray( players )
	int client_count = 0

	int new_player[4] = {0, 0, 0, 0}
	new_player[3] = roundStart

	char steam_id[STEAMID]

	//loop through all players that are alive
	for(new i=1;i<= MaxClients;i++){
		if( IsNotClient(i) )
			continue

		client_count++
		steam_id = getSteamID_noValidation( i )
		int team = GetClientTeam( i )
		new_player[2] = team
			
		PushArrayString( players, steam_id )
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

/*
	- keep tract of client playing time
	- update client playing time
*/
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
		Format(	query, sizeof(query), NEWPLAYER , steamID, playerName, playerName	)
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


/*
	- finalize client data, playing time, teams etc
	 - post data to trueskill implementation
*/
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
		Format( query,sizeof(query), INTOTEMP , 
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
			Format( query, sizeof(query), STATS , 
				steam_id, role, steam_id, role, kills, deths, kills, deths );
			SQL_TQuery( db,T_query,query,0 )
		}
	}
	track_game = 0
}


/*
	
	HANDLES CURL TO REMOTE WHEN NEEDED

*/
public T_query(Handle:owner,Handle:hndle,const String:error[],any:data){
	printTErr(hndle, error );

	if(data != 0){
		char query[QUERY_SIZE]
		char url[100]; GetConVarString( sm_url, url, sizeof(url) )

		Format(	query,sizeof( query ),"%s?group=%d", url, data	)
		HTTPRequestHandle send = Steam_CreateHTTPRequest( HTTPMethod_GET, query )
		Steam_SendHTTPRequest( send, onComplete )
	}
}
public onComplete( HTTPRequestHandle req, bool success, HTTPStatusCode status ){
	if( !success || status != HTTPStatusCode_OK ){
		LogError( "TrueSkill -  post failed" )
	}

	Steam_ReleaseHTTPRequest( req )
}


/*

	HANDLES WHEN PLAYER SAY !RANK

*/
public Action playRank(client, args){
	char steamID[STEAMID]
	steamID = getSteamID( client )

	char query[QUERY_SIZE]
	Format( query,sizeof(query), RANK, steamID 	)

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


/*
	
	HANDLES UPDATE TIME STUFF

*/
updateTimes( int player, int newTeam, int oldTeam, int curTime ){
	/* ensure tracking game */
	if(	!track_game )
		return

	if( curTime == 0 )
		curTime = GetTime()

	/* get the required data array information */
	int player_time[4]
	GetArrayArray( players_times, player, player_time, sizeof( player_time ) )
	int duration = curTime - player_time[3]

	if( oldTeam == 0 )
		oldTeam = player_time[2]

	/* determine which team counter to increment */
	switch ( oldTeam ){
		case ( _:TFTeam_Red ): {
			player_time[0] = player_time[0] + duration
		}

		case ( _:TFTeam_Blue ): {
			player_time[1] = player_time[1] + duration
		}
	}

	player_time[2] = newTeam
	player_time[3] = GetTime()

	/* store array back into adt */
	SetArrayArray(	players_times, player, player_time, sizeof( player_time )	)
}



/*

	PlayerID / SteamID Functions

*/
char[] getSteamID_noValidation( client ){
	char steam_id[STEAMID]
	GetClientAuthId( client, AuthIdType:AuthId_Steam3 , steam_id, STEAMID, false )
	return steam_id
}
char[] getSteamID( client ){
	char steam_id[STEAMID]
	GetClientAuthId( client, AuthIdType:AuthId_Steam3 , steam_id, STEAMID )
	return steam_id
}
int getPlayerID( client ){
	return FindStringInArray( players, getSteamID( client ) )
}
/* prints an error given handle and error string */
printTErr( Handle hndle, const char[] error ){
	if( hndle == null ){
		LogError( "TrueSkill - Query Failed: %s", error )
		return 0
	}
	return 1
}



/*

	NATIVES 

*/
public native_trueskill_getElo( Handle plugin, numParams ){
	int user = GetNativeCell(1)

	int client = GetClientOfUserId( user )
	if( IsNotClient(client) )
		return ThrowNativeError( SP_ERROR_NATIVE, "Client not connected" )

	char steamID[STEAMID]
	steamID = getSteamID( client )

	char query[QUERY_SIZE]
	Format( query, sizeof(query), 
	"select 30*my.rank + 1500,%d,count(*) rank  from players my left join players others on others.rank >= my.rank where my.SteamID = '%s'" , user, steamID )
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
