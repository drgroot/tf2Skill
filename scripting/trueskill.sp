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
#include <tf2_stocks>
#include <updater>

#define UPDATE_URL 	"http://playtf2.com/tf2Skill/updatefile.txt"
#define PLUGIN_NAME	"TrueSkill Ranking System"
#define AUTHOR 		"Yusuf Ali"
#define VERSION 	"1.2.0"
#define URL 		"http://yusufali.ca/repos/tf2Skill.git/"

new Handle:players_times;
new Handle:players;
new game_start = 0;
new track_game = 0;
new client_count = 0;

/* define convars */
new Handle:sm_minClients = INVALID_HANDLE;

/* delcare plublic variable information */
public Plugin:myinfo = {name = PLUGIN_NAME,author = AUTHOR,description = "",version = VERSION,url = URL};

public OnPluginStart(){
   /* add to updater */
   Updater_AddPlugin(UPDATE_URL);	

   /* create database tables */

   /* define convars */
   sm_minClients = CreateConVar("sm_minClients","16","Minimum clients for ranking");

   /* bind methods to game events */
   HookEvent("player_team",Event_pTeam);
   HookEvent("teamplay_round_start", Event_rStart);
   HookEvent("teamplay_round_win",Event_rEnd);
   HookEvent("player_disconnect", Event_pDisconnect);
   RegConsoleCmd("sm_rank",playRank);

   players_times = CreateArray(3,0);
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
      client_count++;

      /* get SteamID */
      decl String:SteamID[20];
      GetClientAuthString(client,SteamID,sizeof(SteamID),true);

      /* add to database, and update last connect */

      /* if joined, determine if already rejoined */
      new player = getPlayerID(client);

      /* otherwise populate the arrays */
      if(player == -1){
	 decl String:steam_id[20];
	 GetClientAuthString(client,steam_id,sizeof(steam_id),true);

	 // populate player arrays
	 PushArrayString(players,steam_id);
	 player = FindStringInArray(players,steam_id);
	 new timeStat[3] = {0,0,0}; 
	 timeStat[0] = GetTime();
	 PushArrayArray(players_times,timeStat);
      }
		
      /* create timer */
      		
   }
   else{
	 /* player switched teams, deal with it */
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
   new curTime = GetTime();	 

   //loop through all players that are alive
   for(new i=1;i<= MaxClients;i++){
      /* ensures client is connected */
      if( (IsClientInGame(i))  && (!IsFakeClient(i)) ){
	 client_count++;
	 decl String:steam_id[20];
	 GetClientAuthString(i,steam_id,sizeof(steam_id),true);

	 // populate player arrays
	 new timeData[3] = {0,0,0,};
	 timeData[0] = curTime;
	 PushArrayString(players,steam_id);
	 PushArrayArray(players_times,timeData);
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
   new result = GetEventInt(event,"team");
   new random = GetRandomInt(0,400);

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

      /* build insert query */

		
   }
}



/* REGISTERED ACTION COMMANDS */

/*
	gets player rank from trueskill
	database implementation
*/
public Action:playRank(client, args){
	decl String:SteamID[20];
	new rank = 0; new Float:sigma = 100.0;

	/* steps */
	 /* 1. get steamid from client */
	GetClientAuthString(client,SteamID,sizeof(SteamID),true);

	 /* 2. query database and return player skill
               and sigma, and rank (1- x etc)   */

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

