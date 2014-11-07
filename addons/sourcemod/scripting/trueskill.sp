/*

TRUESKILL RANKING SYSTEM

A TF2 adapted implementation of the ever popular
trueskill ranking system.

Author: Yusuf Ali

*/
/*
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

#define UPDATE_URL 	"http://playtf2.com/tf2Skill/addons/sourcemod/updatefile.txt"
#define PLUGIN_NAME	"TrueSkill Ranking System"
#define AUTHOR 		"Yusuf Ali"
#define VERSION 	"3.0"
#define URL 		"https://github.com/yusuf-a/tf2Skill"
#define STEAMID		20
#define QUERY_SIZE   512
#define INTERVAL	0.15

Handle db						// database handle
Handle players_stats			// player k:d storage variable
Handle players_times			// player time storage variable
Handle players					// player ids variable		
float gameDuration = 0.0	// time of round start
int track_game = 0			// track game or not

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
	sm_url = CreateConVar("sm_trueskill_url","http://server.com/trueskill.php","url to trueskill php file", FCVAR_PROTECTED)
	sm_minGlobal = CreateConVar("sm_trueskill_global","50","Minimum rank for global display, 0 for off", FCVAR_NOTIFY)

	/* bind methods to game events */
	HookEvent( "player_team", Event_pTeam )
	HookEvent( "teamplay_round_start", Event_rStart )
	HookEvent( "teamplay_round_win", Event_rEnd )
	HookEvent( "player_death", Event_pDeath )
	RegConsoleCmd( "sm_rank", playRank )
}
public OnLibraryAdded(	const char name[]	){
	 if(	StrEqual( name, "updater" )	){
		Updater_AddPlugin( UPDATE_URL )
	 }
}
public APLRes AskPluginLoad2(Handle me, bool late, char err[], err_max){
	CreateNative( "trueskill_getAllElo", native_trueskill_getAllElo )
	CreateNative( "trueskill_getElo", native_trueskill_getElo )
	return APLRes_Success
}

/* METHODS FOR GAME EVENTS */
public Event_pDeath( Handle event, const char name[], bool dontBroadcast){
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
	char steamID[STEAMID]
	steamID = getSteamID( client )
	int player = getPlayerID( client )

	/* get player name */
	char playerName[MAX_NAME_LENGTH *2 +1]
	GetClientName( client, playerName, sizeof( playerName )	)
	SQL_EscapeString( db, playerName, playerName,sizeof( playerName )	)

	/* determine if player switched teams or joined */
	if(oTeam != _:TFTeam_Red && oTeam != _:TFTeam_Blue){
		/* add to database, and update last connect */
		char query[QUERY_SIZE]
		Format(	query, sizeof(query), NEWPLAYER , steamID, playerName, playerName	)
		SQL_TQuery(db,T_query,query,0)

		/* ensure we are tracking data */
		if( !track_game )
			return

		/* otherwise populate the arrays */
		if(player == -1){
		  PushArrayString( players, steamID )
		  player = FindStringInArray( players, steamID )
		  PushArrayArray(players_times,{0.0,0.0})
		  PushArrayArray(players_stats,{0,0,0,0,0,0,0,0,0,0,
		  								0,0,0,0,0,0,0,0,0,0})
		}

		/* create timer */
		CreateTimer( INTERVAL,UpdateTimes,client,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
}

/*
	- reset arrays, grab client information
	 - structure data
*/
public Event_rStart( Handle event, const char name[], bool dontBroadcast ){
	/* restart required variables */
	gameDuration = 0.0
	players_stats = CreateArray( 20,0 )
	players_times = CreateArray( 2,0 )
	players = CreateArray( STEAMID,0 )
	int client_count = 0

	char steam_id[STEAMID]

	//loop through all players that are alive
	for(new i=1;i<= MaxClients;i++){
		/* ensures client is connected */
		if( IsClientInGame( i )  && !IsFakeClient( i ) ){
			client_count++
			steam_id = getSteamID( i )

			PushArrayString( players, steam_id )
			PushArrayArray( players_times,{0.0,0.0} )
			PushArrayArray( players_stats,{0,0,0,0,0,0,0,0,0,0,
											0,0,0,0,0,0,0,0,0,0} )

			/* create timer */
			CreateTimer( INTERVAL, UpdateTimes,i,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE )
		}
	}
	CreateTimer( INTERVAL, gameTime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE )

	/* determine if to track the game or not */
	track_game  = (	client_count >= GetConVarInt(sm_minClients)	)

	/* ensure database is connected */
	if( db == null )
		track_game = 0
}
public Action gameTime( Handle timer, any data ){
	if(!track_game)
		return Plugin_Stop
	gameDuration += INTERVAL
	return Plugin_Continue
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
	char steam_id[STEAMID]

	track_game = 0

	/* declare useful comparison */
	int result = GetEventInt( event,"team" )
	int random = GetRandomInt( 0,400 )

	/* ensure that the game was not a farm fest */
	if( GetArraySize(players) < 24 ) 
		return

	for(int i=0; i<GetArraySize(players); i++){
		int last = (i == GetArraySize(players) -1)

		/* store player data into buffers */
		GetArrayArray( players_stats,i,player_stat,sizeof(player_stat) );
		GetArrayArray( players_times,i,player_time,sizeof(player_time) );
		GetArrayString( players,i,steam_id, STEAMID );

		float blu = player_time[1]/gameDuration
		float red = player_time[0]/gameDuration

		blu = (blu > 1.0)? 1.0 : blu
		red = (red > 1.0)? 1.0 : red
	
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

	if(!IsClientInGame(client)){
		return
	}
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
public Action UpdateTimes( Handle timer, any client ){
	/* ensure tracking game */
	if(	!track_game || !IsClientConnected(client)	)
		return Plugin_Stop

	if(	!IsClientInGame(client)	)
		return Plugin_Stop

	/* get player id in array */
	int player = getPlayerID( client )

	/* get the required data array information */
	float player_time[2];
	GetArrayArray( players_times, player, player_time, sizeof( player_time ) ); 

	/* determine which team counter to increment */
	switch ( GetClientTeam( client )	){
		case ( _:TFTeam_Red ): {
			player_time[0] = player_time[0] + INTERVAL
		}

		case ( _:TFTeam_Blue ): {
			player_time[1] = player_time[1] + INTERVAL
		}
	}
	/* store array back into adt */
	SetArrayArray(	players_times, player, player_time, sizeof( player_time )	)

	return Plugin_Continue
}
/* prints an error given handle and error string */
printTErr( Handle hndle, const char error[] ){
	if( hndle == null ){
		LogError( "TrueSkill - Query Failed: %s", error )
		return 0
	}
	return 1
}


/*

	PlayerID / SteamID Functions

*/
char[] getSteamID( client ){
	char steam_id[STEAMID]
	GetClientAuthId( client, AuthIdType:AuthId_SteamID64 , steam_id, STEAMID )
	return steam_id
}
int getPlayerID( client ){
	return FindStringInArray( players, getSteamID( client ) )
}




/*

	NATIVES 

*/
public native_trueskill_getElo( Handle plugin, numParams ){
	int client = GetClientOfUserId( GetNativeCell(1) )
	Handle callback = Handle:GetNativeCell(2)

	if( !IsClientInGame(client) )
		return ThrowNativeError( SP_ERROR_NATIVE, "Client not connected" )

	char steamID[STEAMID]
	steamID = getSteamID( client )

	char query[QUERY_SIZE]
	Format( query, sizeof(query), 
	"SELECT 30*rank + 1500 as elo from players where SteamID = '%s'" , steamID )
	SQL_TQuery( db, native_callback, query, callback )

	return 1
}
public native_trueskill_getAllElo( Handle plugin, numParams ){
	//Handle callback = Handle:GetNativeCell(1)
}

/* Handles the Callback given by native query */
public native_callback( Handle o, Handle h, const char[] e, any hndl){
	Handle callback = Handle:hndl
	
}
