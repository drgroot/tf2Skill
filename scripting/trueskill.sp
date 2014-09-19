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
#define sID_size	20

new Handle:db;
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
   /* connect to database */
   new String:error[255];
   db = SQL_DefConnect(error,sizeof(error));

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
   players = CreateArray(sID_size,0);
}


/* METHODS FOR GAME EVENTS */
/*
	- keep track of clients disconnecting
	- update client playing time
*/
public Event_pDisconnect(Handle:event, const String:name[], bool:dontBroadcast){
   if(!track_game)
      return;

   client_count--;

   /* update player time in array */
}

/*
	- keep tract of client playing time
	- update client playing time
*/
public Event_pTeam(Handle:event, const String:name[], bool:dontBroadcast){
   if(!track_game)
      return;

   new oTeam = GetEventInt(event,"oldteam");
   new client = GetClientOfUserId(GetEventInt(event,"userid"));
   decl timeStat[3];

   /* ensure its a legit client */
   if(IsFakeClient(client))
      return;
   
   /* get steamID */
   decl String:steamID[sID_size]; steamID = getSteamID( client );
   new player = getPlayerID( client );

   /* determine if player switched teams or joined */
   if(oTeam != _:TFTeam_Red && oTeam != _:TFTeam_Blue){
      client_count++;

      /* add to database, and update last connect */

      /* otherwise populate the arrays */
      if(player == -1){
	 // populate player arrays
	 PushArrayString(players,steamID);
	 player = FindStringInArray(players,steamID);
	 PushArrayArray(players_times,{0,0,0});
      }
      // store time into array 
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

   decl String:steam_id[sID_size];

   //loop through all players that are alive
   for(new i=1;i<= MaxClients;i++){
      /* ensures client is connected */
      if( (IsClientInGame(i))  && (!IsFakeClient(i)) ){
	 client_count++;
	 steam_id = getSteamID(i);

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
   /* ensure this game is to be tracked */
   if(!track_game)
      return;
   
   /* declare useful buffers */
   decl String:steam_id[sID_size];
   decl player_time[3];

   /* declare useful comparison */
   new result = GetEventInt(event,"team");
   new random = GetRandomInt(0,400);
   new curTime = GetTime();

   /* ensure that the game was not a farm fest */
   if (GetArraySize(players) < 24 && client_count < GetConVarInt(sm_minClients)) 
      return;

   for(new i=0;i<GetArraySize(players);i++){
      /* declare useful constants */
      GetArrayArray( players_times,i,player_time,sizeof(player_time) );
      steam_id = getSteamID(i);
   
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
   decl String:steamID[20];
   new rank = 0; new Float:sigma = 100.0;

   /* steps */
      /* 1. get steamid from client */
   steamID = getSteamID( client );

      /* 2. query database and return player skill
            and sigma, and rank (1- x etc)   */

      /* 3. display to user in chat box */
   PrintToChat( client,"Rank of %d, with %.2f units of uncertainty",rank,sigma );		

   return Plugin_Handled;
}

/* UTILITY COMMANDS */

/* Return playerID given client index */
getPlayerID(client){
   return FindStringInArray( players,getSteamID( client ) );
}

/* return players steamID */
String:getSteamID(client){
   decl String:steam_id[20];
   GetClientAuthString(client,steam_id,sizeof(steam_id),true);
   return steam_id; 
}
