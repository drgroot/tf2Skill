/*

TRUESKILL RANKING SYSTEM

A TF2 adapted implementation of the ever popular
trueskill ranking system.

Author: Yusuf Ali

requires:
	curl - initiate trueskill calculations

*/

#include <sourcemod>
#include <dbi>
#include <cURL>
#include <tf2_stocks>
#include <updater>

#define UPDATE_URL "http://playtf2.com/tf2Skill/updatefile.txt"

#define USE_THREAD				1
new CURL_Default_opt[][2] = {
#if USE_THREAD
	{_:CURLOPT_NOSIGNAL,1},
#endif
	{_:CURLOPT_NOPROGRESS,1},
	{_:CURLOPT_TIMEOUT,30},
	{_:CURLOPT_CONNECTTIMEOUT,60},
	{_:CURLOPT_VERBOSE,0}
};
#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))

new Handle:players_times;
new Handle:players_stats;
new Handle:players;
new Handle:db;

new Float:gameDuration = 0.0;
new gameEnd = 0;
new client_count = 0;

/* define convars */
new Handle:sm_minClients = INVALID_HANDLE;
new Handle:sm_skillInterval = INVALID_HANDLE;

/*
delcare plublic variable information
*/
public Plugin:myinfo = 
{
	name = "TrueSkill Ranking System",
	author = "Yusuf Ali",
	description = "An implementation of TrueSkill into Source games",
	version = "1.0.1",
	url = "http://yusufali.ca/repos/tf2Skill.git/"
};
public OnPluginStart(){
	Updater_AddPlugin(UPDATE_URL);	

	/* connect to database */
	connect_database();

	/* create database tables */
	createDB_tables();

	/* define convars */
	sm_minClients = CreateConVar("sm_minClients","16","Minimum clients for ranking");
	sm_skillInterval = CreateConVar("sm_skillInterval","0.5","TrueSkill interval");

	/* bind methods to game events */
	HookEvent("player_team",Event_pTeam);
	HookEvent("player_death", Event_pDeath);
	HookEvent("teamplay_round_start", Event_rStart);
	HookEvent("teamplay_round_win",Event_rEnd);
	HookEvent("player_disconnect", Event_pDisconnect);
	RegConsoleCmd("sm_rank",playRank);

	players_times = CreateArray(3,0);
	players_stats = CreateArray(20,0);
	players = CreateArray(20,0);
}





/* METHODS FOR GAME EVENTS */


/*
	- keep track of clients disconnecting
	- update client playing time
*/
public Event_pDisconnect(Handle:event, const String:name[], bool:dontBroadcast){
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

	/* determine if player switched teams or joined */
	if(oTeam != _:TFTeam_Red && oTeam != _:TFTeam_Blue){
		connect_database();
		client_count++;

		/* get SteamID */
		decl String:SteamID[20];
		GetClientAuthString(client,SteamID,sizeof(SteamID),true);

		/* add to database, and update last connect */
		new String:query[512];
		Format(query,sizeof(query), 
			"insert into players (steamID) values ('%s') on duplicate key update lastConnect = CURRENT_TIMESTAMP;",
			SteamID);
		new Handle:hQuery = SQL_Query(db,query);
		CloseHandle(hQuery);

		/* if joined, determine if already rejoined */
		new player = getPlayerID(client);

		/* otherwise populate the arrays */
		if(player == -1){
			decl String:steam_id[20];
			GetClientAuthString(client,steam_id,sizeof(steam_id),true);

			// populate player arrays
			PushArrayString(players,steam_id);
			player = FindStringInArray(players,steam_id);
			
			PushArrayArray(players_stats,{0,0});
			PushArrayArray(players_times,{0.0,0.0});
		}
		
		/* create timer */
		CreateTimer(GetConVarFloat(sm_skillInterval),incrementPlayerTimer,client,TIMER_REPEAT);
	}
}

/*
	- store kills and deaths
	 - for statistics purposes
	 - no affect on ranking,
	   just to make everyone happy
*/
public Event_pDeath(Handle:event, const String:name[], bool:dontBroadcast){
	/* ensure not a fake death */
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) { 
    	return;  
	}

	/* ensure killed by another player */
	if(GetEventInt(event,"attacker") <= 0 || GetEventInt(event,"attacker") > MaxClients){
		return;
	}
	decl kills[20]; decl deaths[20];

	/* get client index */
	new killer = GetClientOfUserId(GetEventInt(event,"attacker"));
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));

	/* get clients role */
	new TFClassType:killer_role = TF2_GetPlayerClass(killer);
	new TFClassType:victim_role = TF2_GetPlayerClass(victim);

	/* get adt_array index */
	killer = getPlayerID(killer); 
	victim = getPlayerID(victim);

	/* get old stats for increment purposes */
	GetArrayArray(players_stats,killer,kills,sizeof(kills));
	GetArrayArray(players_stats,victim,deaths,sizeof(deaths));

	/* increment data */
	deaths[victim_role]++; 
	kills[19-killer_role]++;

	/* store into <adt array> player_stats */
	SetArrayArray(players_stats,killer,kills,sizeof(kills));
	SetArrayArray(players_stats,victim,deaths,sizeof(deaths));
}

/*
	- reset arrays, grab client information
	 - structure data
*/
public Event_rStart(Handle:event, const String:name[], bool:dontBroadcast){
	/* connect to database */
	connect_database();

	gameDuration=0.0; gameEnd = 0;
	ClearArray(players); 
	ClearArray(players_stats); ClearArray(players_times); 

	// start the timer for the game
	CreateTimer(GetConVarFloat(sm_skillInterval), incrementGameTimer, _, TIMER_REPEAT);

	//loop through all players that are alive
	for(new i=1;i<= MaxClients;i++){
		/* ensures client is connected */
		if( (IsClientInGame(i))  && (!IsFakeClient(i)) ){

			client_count++;
			decl String:steam_id[20];
			GetClientAuthString(i,steam_id,sizeof(steam_id),true);

			// populate player arrays
			PushArrayString(players,steam_id);
			PushArrayArray(players_times,{0.0,0.0});
			PushArrayArray(players_stats,{0,0,0,0,0,0,0,0,0,0,
						      0,0,0,0,0,0,0,0,0,0});

			// create timer for player
			CreateTimer(GetConVarFloat(sm_skillInterval),incrementPlayerTimer,i,TIMER_REPEAT);
		}
	}
}

/*
	- finalize client data, playing time, teams etc
	 - post data to trueskill implementation
*/
public Event_rEnd(Handle:event, const String:namep[], bool:dontBroadcast){
	gameEnd = 1;
	new result = GetEventInt(event,"team");
	new random = GetRandomInt(0,400);

	connect_database();

	/* ensure that the game was not a farm fest */
	if (GetArraySize(players) < 24 && client_count < GetConVarInt(sm_minClients)) {
		return;
	}	

	for(new i=0;i<GetArraySize(players);i++){
		decl Float:player_time[2];
		GetArrayArray(players_times,i,player_time,sizeof(player_time));
		
		decl String:steam_id[20];
		GetArrayString(players,i,steam_id,sizeof(steam_id));

		/* insert data into database */
		new String:query[512]; new buffer_len = strlen(steam_id)*2 +1;
		new String:new_name[buffer_len];

		/* build insert query */
		SQL_EscapeString(db,steam_id,new_name,buffer_len);
		Format(query,sizeof(query), 
			"INSERT INTO `temp` VALUES('%s',%f,%f,%d,%d);",
			new_name,player_time[1]/gameDuration,player_time[0]/gameDuration,result,random);

		new Handle:hQuery = SQL_Query(db,query);
		//CloseHandle(hQuery);

		/* do the same for the kill stat information */
		decl player_stats[20];
		GetArrayArray(players_stats,i,player_stats,sizeof(player_stats));

		/* loop through stats and insert into database */
		for(new j=0;j<10;j++){
		  new kills = player_stats[19-j];
		  new deaths = player_stats[j];
	    
		  Format(query,sizeof(query),
		     "INSERT INTO `player_stats` (stat_id,steamID,roles,kills,deaths) VALUES ('%s:%d','%s',%d,%d,%d) ON DUPLICATE KEY UPDATE kills = kills + %d, deaths = deaths + %d;", 
		     steam_id,j,steam_id,j,kills,deaths,kills,deaths);

		  new String:error[255];
		  hQuery = SQL_Query(db,query);

		  if(!hQuery){
		  	SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		  }

		  CloseHandle(hQuery);
		}
	}

	/* post to remote website to initiate calculations */
	new Handle:curl = curl_easy_init();
	CURL_DEFAULT_OPT(curl);
	curl_easy_setopt_string(curl, CURLOPT_URL, "http://playtf2.com/test.php");
	ExecCURL(curl,2);
}



/* TIMER METHODS */

public Action:incrementGameTimer(Handle:timer){
	if(gameEnd) 
		return Plugin_Stop;
	
	gameDuration = gameDuration + GetConVarFloat(sm_skillInterval);

	return Plugin_Continue;
}

public Action:incrementPlayerTimer(Handle:timer, any:client){
	/* increments if player is connected and game is going */
	if ( (gameEnd) || (! (IsClientInGame(client))  )  )
		return Plugin_Stop;
	
	/* determine corresponding playerID */
	new player = getPlayerID(client);
	
	/* get the required data array information */
	decl Float:player_time[2];
	GetArrayArray(players_times,player,player_time,sizeof(player_time)); 

	/* determine which team counter to increment */
	switch (GetClientTeam(client)){
		case (_:TFTeam_Red): {
			player_time[0] = player_time[0] + GetConVarFloat(sm_skillInterval);
		}

		case (_:TFTeam_Blue): {
			player_time[1] = player_time[1] + GetConVarFloat(sm_skillInterval);
		}
	}
	
	/* store array back into adt */
	SetArrayArray(players_times,player,player_time,sizeof(player_time));
	
	return Plugin_Continue;
}




/* REGISTERED ACTION COMMANDS */

/*
	gets player rank from trueskill
	database implementation
*/
public Action:playRank(client, args){
	connect_database();
	decl String:SteamID[20];
	new rank = 0; new Float:sigma = 100.0;

	/* steps */
	 /* 1. get steamid from client */
	GetClientAuthString(client,SteamID,sizeof(SteamID),true);

	 /* 2. query database and return player skill
               and sigma, and rank (1- x etc)   */
	decl String:query[250];
	Format(query,sizeof(query)," select count(*)+1 rank,my.sigma from players my left join players others on others.rank > my.rank where my.SteamID = '%s';",SteamID);
	new Handle:hQuery = SQL_Query(db,query);

	while(SQL_FetchRow(hQuery)){
		rank = SQL_FetchInt(hQuery,0); sigma = SQL_FetchFloat(hQuery,1);
	}

	 /* 3. display to user in chat box */
	PrintToChat(client,"Rank of %d, with %.2f units of uncertainty",rank,sigma);		

	return Plugin_Handled;
}

/* UTILITY COMMANDS */

/* Return playerID given client index */
getPlayerID(client){
	decl String:steam_id[20];
	GetClientAuthString(client,steam_id,sizeof(steam_id),true);
	return FindStringInArray(players,steam_id);
}

/* creates the mysql tables if they are not created */
createDB_tables(){
	new String:error[255];

    if(!SQL_FastQuery(db,"CREATE TABLE IF NOT EXISTS `player_stats` (`stat_id` tinytext NOT NULL,`steamID` tinytext NOT NULL,`roles` int(11) NOT NULL,`kills` int(11) NOT NULL DEFAULT '0',`deaths` int(11) NOT NULL DEFAULT '0',UNIQUE KEY `stat_id` (`stat_id`(100)),KEY `steamID` (`steamID`(100)));")){
	 PrintToServer("Failed to query (error: %s)", error);
	}

	if(!SQL_FastQuery(db,"CREATE TABLE IF NOT EXISTS `temp` (`steamid` MEDIUMTEXT NOT NULL,`time_blue` DECIMAL(11,10) NOT NULL,`time_red` DECIMAL(11,10) NOT NULL,`result` INTEGER(1) NOT NULL,`random` INTEGER(6) NOT NULL);")){
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	}

	if(!SQL_FastQuery(db,"CREATE TABLE IF NOT EXISTS `players` (`player_id` INTEGER(11) NOT NULL AUTO_INCREMENT, `steamID` TEXT NOT NULL,`lastConnect` TIMESTAMP,`mew` DECIMAL(20,17) NOT NULL DEFAULT 25.0,`sigma` DECIMAL(20,17) NOT NULL DEFAULT 8.3333,`rank` DECIMAL(20,17) NOT NULL DEFAULT 0.0 ,PRIMARY KEY (`player_id`),UNIQUE(steamid(100)));")){
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	}
}

/* connects to database */
connect_database(){
	if(db == INVALID_HANDLE){
		new String:error[255]
		db = SQL_Connect("default", true, error, sizeof(error));
		if( db == INVALID_HANDLE)
			PrintToServer("Could not connect: %s", error);
	}
}

/* close database connection 
discon_database(){
	CloseHandle(db);
}
*/

stock ExecCURL(Handle:curl, current_test)
{
#if USE_THREAD
	curl_easy_perform_thread(curl, onComplete, current_test);
#else
	new CURLcode:code = curl_load_opt(curl);
	if(code != CURLE_OK) {
		PrintTestCaseDebug(current_test, "curl_load_opt Error");
		PrintcUrlError(code);
		CloseHandle(curl);
		return;
	}
	
	code = curl_easy_perform(curl);
	
	onComplete(curl, code, current_test);

#endif
}

public onComplete(Handle:hndl, CURLcode: code, any:data)
{
	CloseHandle(hndl);
}
