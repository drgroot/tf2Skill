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
#include <socket>

#define UPDATE_URL 	"http://playtf2.com/tf2Skill/updatefile.txt"
#define PLUGIN_NAME	"TrueSkill Ranking System"
#define AUTHOR 		"Yusuf Ali"
#define VERSION 	"2.9"
#define URL 		"http://yusufali.ca/repos/tf2Skill.git/"
#define sID_size	20
#define QUERY_SIZE   512
#define NAME_SIZE	100
#define INTERVAL	0.15

new Handle:db;
new Handle:players_stats;
new Handle:players_times;
new Handle:players;
new Handle:socket;
new game_start = 0;
new track_game = 0;
new client_count = 0;
new gameNumber = 0;

/* define convars */
new Handle:sm_minClients = INVALID_HANDLE;
new Handle:sm_server = INVALID_HANDLE;
new Handle:sm_port = INVALID_HANDLE;

/* delcare plublic variable information */
public Plugin:myinfo = {name = PLUGIN_NAME,author = AUTHOR,description = "",version = VERSION,url = URL};

public OnPluginStart(){
	/* connect to database */
	new String:error[255];
	db = SQL_DefConnect(error,sizeof(error));

	/* add to updater */
	if (LibraryExists("updater")){
		Updater_AddPlugin(UPDATE_URL);
	}

	/* define convars */
	sm_minClients = CreateConVar("sm_trueskill_minClients","16","Minimum clients to track ranking");
	sm_server = CreateConVar("sm_trueskill_server","dev.yusufali.ca","Server ip with python script");
	sm_port = CreateConVar("sm_trueskill_port","5000","Port to interact with python script");

	/* bind methods to game events */
	HookEvent("player_team",Event_pTeam);
	HookEvent("teamplay_round_start", Event_rStart);
	HookEvent("teamplay_round_win",Event_rEnd);
	HookEvent("player_disconnect", Event_pDisconnect);
	HookEvent("player_death", Event_pDeath);
	RegConsoleCmd("sm_rank",playRank);
    
	players_stats = CreateArray(20,0);
	players_times = CreateArray(2,0);
	players = CreateArray(sID_size,0);
}

public OnLibraryAdded(const String:name[]){
	 if (StrEqual(name, "updater"))
	 {
		  Updater_AddPlugin(UPDATE_URL)
	 }
}


/* METHODS FOR GAME EVENTS */

public Event_pDeath(Handle:event, const String:name[], bool:dontBroadcast){
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

	/* get client roles */
	new TFClassType:killer_role = TF2_GetPlayerClass( killer );
	new TFClassType:victim_role = TF2_GetPlayerClass( victim );

	/* get adt_array index and old stats */
	killer = getPlayerID(killer); victim = getPlayerID(victim);
	GetArrayArray( players_stats, killer, atker, sizeof(atker) );
	GetArrayArray( players_stats, victim, victm, sizeof(victm) );

	/* increment data */
	atker[killer_role]++;
	victm[victim_role + 10]++;

	/* store into <adt_array> player_stats */
	SetArrayArray( players_stats, killer, atker, sizeof(atker) );
	SetArrayArray( players_stats, victim, victm, sizeof(victm) );
}

/*
	- keep track of clients disconnecting
	- update client playing time
*/
public Event_pDisconnect(Handle:event, const String:name[], bool:dontBroadcast){
	if(!track_game)
		return;

	client_count--;
}

/*
	- keep tract of client playing time
	- update client playing time
*/
public Event_pTeam(Handle:event, const String:name[], bool:dontBroadcast){
	new oTeam = GetEventInt(event,"oldteam");
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	/* ensure its a legit client */
	if(IsFakeClient(client))
		return;
	
	/* get steamID */
	decl String:steamID[sID_size]; steamID = getSteamID( client );
	new player = getPlayerID( client );

	/* get player name */
	decl String:playerName[NAME_SIZE];
	GetClientName(client, playerName, sizeof(playerName));
	SQL_EscapeString(db,playerName,playerName,sizeof(playerName));

	/* ensure we are tracking data */
	if(!track_game)
		return;

	/* determine if player switched teams or joined */
	if(oTeam != _:TFTeam_Red && oTeam != _:TFTeam_Blue){
		client_count++;

		/* add to database, and update last connect */
		decl String:query[QUERY_SIZE];
		Format(query,sizeof(query),
		"insert into players (steamID) values ('%s') on duplicate key update lastConnect = CURRENT_TIMESTAMP;",
			steamID);
		SQL_TQuery(db,T_query,query,0);

		Format(query,sizeof(query),
		"UPDATE players SET name = '%s' WHERE steamID = '%s';",
			playerName, steamID);
		SQL_TQuery(db,T_query,query,0);

		/* update player name */

		/* otherwise populate the arrays */
		if(player == -1){
		  PushArrayString(players,steamID);
		  player = FindStringInArray(players,steamID);
		  PushArrayArray(players_times,{0.0,0.0});
		  PushArrayArray(players_stats,{0,0,0,0,0,0,0,0,0,0,
		  								0,0,0,0,0,0,0,0,0,0});
		}

		/* create timer */
		CreateTimer(INTERVAL,UpdateTimes,client,TIMER_REPEAT);
	}
}

/*
	- reset arrays, grab client information
	 - structure data
*/
public Event_rStart(Handle:event, const String:name[], bool:dontBroadcast){
	/* restart required variables */
	game_start = GetTime(); client_count = 0;
	ClearArray(players); ClearArray(players_times);
	ClearArray(players_stats); 

	decl String:steam_id[sID_size];

	//loop through all players that are alive
	for(new i=1;i<= MaxClients;i++){
		/* ensures client is connected */
		if( (IsClientInGame(i))  && (!IsFakeClient(i)) ){
			client_count++;
			steam_id = getSteamID(i);

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
}

/*
	- finalize client data, playing time, teams etc
	 - post data to trueskill implementation
*/
public Event_rEnd(Handle:event, const String:namep[], bool:dontBroadcast){
	/* ensure this game is to be tracked */
	if(!track_game)
		return;

	/* declare useful buffers */
	decl String:steam_id[sID_size];
	new String:query[QUERY_SIZE];
	decl Float:player_time[2];
	decl player_stat[20];

	track_game = 0;

	/* declare useful comparison */
	new result = GetEventInt(event,"team");
	new random = GetRandomInt(0,400);
	new Float:gameDuration = float(GetTime() - game_start);
	gameNumber = random;

	/* ensure that the game was not a farm fest */
	if (GetArraySize(players) < 24 && client_count < GetConVarInt(sm_minClients)) 
		return;

	for(new i=0;i<GetArraySize(players);i++){
		/* store player data into buffers */
		GetArrayArray( players_stats,i,player_stat,sizeof(player_stat) );
		GetArrayArray( players_times,i,player_time,sizeof(player_time) );
		GetArrayString(players,i,steam_id,sizeof(steam_id));

		new Float:blue = player_time[1];
		new Float:red = player_time[0];
	
		/* insert data into database */
		Format(query,sizeof(query),"INSERT INTO `temp` (steamid,time_blue,time_red,result,random) \
		 VALUES('%s',%f,%f,%d,%d);", steam_id,blue/gameDuration, red/gameDuration,result,random);
		SQL_TQuery(db,T_query,query,i == (GetArraySize(players) - 1));

		/* loop through role stats and store into mysql */
		for(new j=0; j<10; j++){
			new role = j;
			new kills = player_stat[j];
			new deths = player_stat[j+10];

			if(kills == 0 && deths == 0)
				continue;
			
			/* build query and insert into database */
			Format(query, sizeof(query), 
				"INSERT INTO `player_stats` (stat_id,steamID,roles,kills,deaths) VALUES ('%s:%d','%s',%d,%d,%d) \
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
public Action:playRank(client, args){
	decl String:steamID[sID_size];
	steamID = getSteamID( client );

	decl String:query[QUERY_SIZE];
	Format(query,sizeof(query),
		"select count(*) rank,(my.rank)/(my.averageRank * 10) * 1200 from players my left join players others \
		on others.rank > my.rank where my.SteamID = '%s';", steamID);

	SQL_TQuery(db,rank_query,query,client);
	
	return Plugin_Handled;
}

public rank_query(Handle:owner,Handle:hndl,const String:error[], any:data){
	new client = data;
	new rank = 0; new Float:sigma = 100.0;

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

		PrintToChat( client,"Rank #%d with %.0f Elo",rank,sigma );     
	}
}

/* UTILITY COMMANDS */

public Action:UpdateTimes(Handle:timer,any:client){
	/* ensure tracking game */
	if(!track_game || !IsClientConnected(client))
		return Plugin_Stop;

	/* get player id in array */
	new player = getPlayerID(client);

	/* get the required data array information */
	decl Float:player_time[2];
	GetArrayArray(players_times,player,player_time,sizeof(player_time)); 

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
	SetArrayArray(players_times,player,player_time,sizeof(player_time));

	return Plugin_Continue;
}

/* Return playerID given client index */
getPlayerID(client){
	return FindStringInArray( players,getSteamID( client ) );
}

/* return players steamID */
String:getSteamID(client){
	decl String:steam_id[sID_size];
	GetClientAuthString(client,steam_id,sizeof(steam_id),true);
	return steam_id; 
}


/* prints an error given handle and error string */
printTErr(Handle:hndle,const String:error[]){
	if(hndle == INVALID_HANDLE){
		LogError("TrueSkill - Query Failed: %s",error);
		return 0;
	}
	return 1;
}

/* typical threaded query prototype */
public T_query(Handle:owner,Handle:hndle,const String:error[],any:data){
	printTErr(hndle, error );

	if(data == 1){
		connectSocket();
	}
}

/* socket functions for socket stuff */
public connectSocket(){
	socket = SocketCreate(SOCKET_TCP,OnSocketError);
	decl String:sock_serv[100];
	GetConVarString(sm_server,sock_serv,sizeof(sock_serv));
	SocketConnect(socket,OnSockCon,OnSockRec,OnSockDis,sock_serv,GetConVarInt(sm_port));
}

public OnSocketError(Handle:sock, const errorType, const errorNum,any:hFile){
	LogError("TrueSkill - Socket Error %d (errno %d)",errorType,errorNum);
}
public OnSockDis(Handle:sock,any:hFile){CloseHandle(sock);}
public OnSockRec(Handle:sock,String:data[],const d,any:f){}
public OnSockCon(Handle:sock,any:f){
	if(gameNumber == 0){
		return;
	}

	decl String:gNum[10]; 
	Format(gNum,sizeof(gNum),"%d",gameNumber);
	SocketSend(sock,gNum);
	gameNumber = 0;
}


