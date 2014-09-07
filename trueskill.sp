/*

TRUESKILL RANKING SYSTEM

A TF2 adapted implementation of the ever popular
trueskill ranking system.

Author: Yusuf Ali

requires:
 System2 for advanced shell commands
 https://forums.alliedmods.net/showthread.php?t=146019


*/

#include <sourcemod>
#include <tf2>
#include <system2>
#include <dbi>

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
public Plugin:trueskill = 
{
	name = "TrueSkill Ranking System",
	author = "Yusuf Ali",
	description = "An implementation of TrueSkill into Source games",
	version = "0.0",
	url = "http://yusufali.ca/repos/tf2Skill.git/"
};
public OnPluginStart(){
	/* connect to database */
	new String:error[255]
	db = SQL_Connect("trueskill", true, error, sizeof(error));
	if( db == INVALID_HANDLE)
		PrintToServer("Could not connect: %s", error);

	/* create database tables */
	createDB_tables();

	/* define convars */
	sm_minClients = CreateConVar("sm_minClients","3","Minimum clients for ranking");
	sm_skillInterval = CreateConVar("sm_skillInterval","0.5","TrueSkill interval");

	/* bind methods to game events */
	HookEvent("player_team",Event_pTeam);
	HookEvent("player_death", Event_pDeath);
	HookEvent("teamplay_round_start", Event_rStart);
	HookEvent("teamplay_round_win",Event_rEnd);
	HookEvent("player_disconnect", Event_pDisconnect);

	players_times = CreateArray(2,0);
	players_stats = CreateArray(2,0);
	players = CreateArray(1,0);
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
	new client = GetEventInt(event,"userid"); 
	
	/* ensure its a legit client */
	if(IsFakeClient(client))
		return;

	/* determine if player switched teams or joined */
	if(oTeam != _:TFTeam_Red && oTeam != _:TFTeam_Blue){
		
		/* if joined, determine if already rejoined */
		new player = getPlayerID(client);

		/* otherwise populate the arrays */
		if(player == -1){
			client_count++;
			decl String:steam_id[512];
			GetClientAuthString(client,steam_id,sizeof(steam_id),true);

			// populate player arrays
			PushArrayString(players,steam_id);
			player = FindStringInArray(players,steam_id);
			
			SetArrayArray(players_stats,player,{0,0});
			SetArrayArray(players_times,player,{0.0,0.0});
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
		
}

/*
	- reset arrays, grab client information
	 - structure data
*/
public Event_rStart(Handle:event, const String:name[], bool:dontBroadcast){
	gameDuration=0.0; gameEnd = 0; 
	ClearArray(players); 
	ClearArray(players_stats); ClearArray(players_times); 

	// start the timer for the game
	CreateTimer(GetConVarFloat(sm_skillInterval), incrementGameTimer, _, TIMER_REPEAT);

	//loop through all players that are alive
	for(new i=1;i<= MaxClients;i++){
		if( (IsClientInGame(i))  && (!IsFakeClient(i)) ){

			client_count++;
			decl String:steam_id[512];
			GetClientAuthString(i,steam_id,sizeof(steam_id),true);

			// populate player arrays
			PushArrayString(players,steam_id);
			new player = FindStringInArray(players,steam_id);

			SetArrayArray(players_stats,player,{0,0});
			SetArrayArray(players_times,player,{0.0,0.0});

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

}



/* TIMER METHODS */

public Action:incrementGameTimer(Handle:timer){
	if(gameEnd) 
		return Plugin_Stop;
	if(GetConVarInt(sm_minClients) > client_count)
		return Plugin_Continue;

	gameDuration = gameDuration + GetConVarFloat(sm_skillInterval);

	return Plugin_Continue;
}

public Action:incrementPlayerTimer(Handle:timer, any:client){
	/* increments if player is connected and game is going */
	if ( (gameEnd) || (! (IsClientInGame(client))  )  )
		return Plugin_Stop;
	if(GetConVarInt(sm_minClients) > client_count)
		return Plugin_Continue;
	
	/* determine corresponding playerID */
	new player = getPlayerID(client);

	/* determine which team counter to increment */
	switch (GetClientTeam(client)){
		case (_:TFTeam_Red): {
			SetArrayCell(players_times,player,
				GetArrayCell(players_times,player,0,false) + GetConVarFloat(sm_skillInterval), 
				0,false);
		}

		case (_:TFTeam_Blue): {
			SetArrayCell(players_times,player,
				GetArrayCell(players_times,player,1,false) + GetConVarFloat(sm_skillInterval), 
				1,false);
		}
	}

	return Plugin_Continue;
}




/* REGISTERED ACTION COMMANDS */

/*
	gets player rank from trueskill
	database implementation
*/
public Action:playRank(client, args){
	return Plugin_Handled;
}

/*
	shows top10 players from trueskill
	database implementation from get request
*/
public Action:topTen(client,args){
	return Plugin_Handled;
}



/* UTILITY COMMANDS */

/* Return playerID given client index */
getPlayerID(client){
	decl String:steam_id[512];
	GetClientAuthString(client,steam_id,sizeof(steam_id),true);
	return FindStringInArray(players,steam_id);
}

createDB_tables(){
	new String:error[255];

	if(!SQL_FastQuery(db,"CREATE TABLE IF NOT EXISTS`temp` (`steamid` MEDIUMTEXT NOT NULL,`time_blue` DECIMAL(6,5) NOT NULL,`time_red` DECIMAL(6,5) NOT NULL,`result` INTEGER(1) NOT NULL);")){
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	}

	if(!SQL_FastQuery(db,"CREATE TABLE IF NOT EXISTS `players` (`player_id` INTEGER(11) NOT NULL AUTO_INCREMENT, `steamID` TEXT NOT NULL,`lastConnect` TIMESTAMP,`mew` DECIMAL(11,5) NOT NULL DEFAULT 0.0,`sigma` DECIMAL(11,5) NOT NULL DEFAULT 0.0,`skill` DECIMAL(11,5) NOT NULL DEFAULT 0.0,PRIMARY KEY (`player_id`));")){
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	}
}