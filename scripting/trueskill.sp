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
#define VERSION 	"2.3"
#define URL 		"http://yusufali.ca/repos/tf2Skill.git/"
#define sID_size	20
#define QUERY_SIZE   512

new Handle:db;
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
   RegConsoleCmd("sm_rank",playRank);

   players_times = CreateArray(4,0);
   players = CreateArray(sID_size,0);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
    }
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

   decl String:steam_id3[sID_size];
   decl String:steam_id2[sID_size];
   GetEventString(event,"networkid",steam_id3,sizeof(steam_id3));

   Steam3To2(steam_id3,steam_id2,sID_size);
   new player = FindStringInArray( players,steam_id2 );

   /* update player time in array */
   updatePlayerTimes( player );

   /* update player team */
   decl player_time[4];
   GetArrayArray( players_times,player,player_time,sizeof(player_time) );
   player_time[3] = -1;
   SetArrayArray(players_times,player,player_time,sizeof(player_time));
}

/*
	- keep tract of client playing time
	- update client playing time
*/
public Event_pTeam(Handle:event, const String:name[], bool:dontBroadcast){
   

   new oTeam = GetEventInt(event,"oldteam");
   new team = GetEventInt(event,"team");
   new client = GetClientOfUserId(GetEventInt(event,"userid"));
   decl player_time[4];
   new curTime = GetTime();

   /* ensure its a legit client */
   if(IsFakeClient(client))
      return;
   
   /* get steamID */
   decl String:steamID[sID_size]; steamID = getSteamID( client );
   new player = getPlayerID( client );

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
      SQL_TQuery(db,T_query,query,client);

      /* otherwise populate the arrays */
      if(player == -1){
	     // populate player arrays
	     PushArrayString(players,steamID);
	     player = FindStringInArray(players,steamID);
	     PushArrayArray(players_times,{0,0,0,0});
      }
      
      // store time into array 
      GetArrayArray( players_times,player,player_time,sizeof(player_time) );
      player_time[0] = curTime;
      SetArrayArray(players_times,player,player_time,sizeof(player_time));
   }
   /* player switched teams*/
   else{
	  /* update time before switch */
      updatePlayerTimes(player);

      /* get new team */
      GetArrayArray(players_times,player,player_time,sizeof(player_time));
      player_time[3] = team;
      SetArrayArray(players_times,player,player_time,sizeof(player_time));
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
	     new timeData[4] = {0,0,0,0};
	     timeData[0] = curTime; timeData[3] = GetClientTeam(i);

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
   new String:query[QUERY_SIZE];
   decl player_time[4];

   /* declare useful comparison */
   new result = GetEventInt(event,"team");
   new random = GetRandomInt(0,400);
   new Float:gameDuration = float(GetTime() - game_start);

   /* ensure that the game was not a farm fest */
   if (GetArraySize(players) < 24 && client_count < GetConVarInt(sm_minClients)) 
      return;

   for(new i=0;i<GetArraySize(players);i++){
      /* update player time information */
      updatePlayerTimes(i,false);

      /* declare useful constants */
      GetArrayArray( players_times,i,player_time,sizeof(player_time) );
      GetArrayString(players,i,steam_id,sizeof(steam_id));

      new Float:blue = float(player_time[2]);
      new Float:red = float(player_time[1]);
   
      /* insert data into database */
      Format(query,sizeof(query),"INSERT INTO `temp` (steamid,time_blue,time_red,result,random) \
       VALUES('%s',%f,%f,%d,%d);", steam_id,blue/gameDuration, red/gameDuration,result,random);
      SQL_TQuery(db,T_query,query,i);
   }

   /* use sockets to trigger rank calculations */
   connectSocket();
}



/* REGISTERED ACTION COMMANDS */

/*
	gets player rank from trueskill
	database implementation
*/
public Action:playRank(client, args){
   decl String:steamID[sID_size];
   new rank = 0; new Float:sigma = 100.0;

   /* steps */
      /* 1. get steamid from client */
   steamID = getSteamID( client );

      /* 2. query database and return player skill
            and sigma, and rank (1- x etc)   */
   decl String:query[QUERY_SIZE];
   Format(query,sizeof(query),
      "select count(*) rank,(my.rank)/(my.averageRank * 10) * 1200 from players my left join players others \
      on others.rank > my.rank where my.SteamID = '%s';", steamID);

   SQL_LockDatabase(db);
   new Handle:hQuery = SQL_Query(db,query);
   printErr(hQuery);
   while(SQL_FetchRow(hQuery)){
      rank = SQL_FetchInt(hQuery,0); sigma = SQL_FetchFloat(hQuery,1);
   }
   SQL_UnlockDatabase(db);
   CloseHandle(hQuery);

      /* 3. display to user in chat box */
   PrintToChat( client,"Rank #%d with %.2f ELO",rank,sigma );		

   return Plugin_Handled;
}


/* UTILITY COMMANDS */

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

updatePlayerTimes(client,bool:restart = true){
   decl player_time[4]; 
   new curTime = GetTime();

   GetArrayArray( players_times,client,player_time,sizeof(player_time) );
   new curTeam = player_time[3];

   /* determine which team, and increment */
   switch(curTeam){
      case (_:TFTeam_Red): {
         player_time[1] = player_time[1] + (curTime - player_time[0]);
      }
      case (_:TFTeam_Blue): {
         player_time[2] = player_time[2] + (curTime - player_time[0]);
      }
      case (-1): {

      }
   }
   
   if(restart){
      player_time[0] = curTime;
   }

   SetArrayArray(players_times,client,player_time,sizeof(player_time));
}

/* prints an error for non threaded stuff */
printErr(Handle:hndle){
   decl String:error[QUERY_SIZE];
   if(hndle == INVALID_HANDLE){
      SQL_GetError(db,error,sizeof(error));
      LogError("TrueSkill - Query Failed: %s",error);
   }
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
}

public Steam3To2(const String:in[], String:out[], maxlen)
{
        new m_unAccountID = StringToInt(in[5]);
        new m_unMod = m_unAccountID % 2;
        Format(out, maxlen, "STEAM_0:%d:%d", m_unMod, (m_unAccountID-m_unMod)/2);
}

/* socket functions for socket stuff */
public connectSocket(){
   if(SocketIsConnected(socket)){
      OnSockCon(socket,1);
      return;
   }

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


