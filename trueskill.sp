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
#include <system2>

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

	/* bind methods to game events */
	HookEvent("player_team",Event_pTeam);
	HookEvent("player_death", Event_pDeath);
	HookEvent("player_disconnect", Event_pDisconnect);
	HookEvent("teamplay_round_start", Event_rStart);
	HookEvent("teamplay_round_win",Event_rEnd);
}





/* METHODS FOR GAME EVENTS */

/*
	- keep tract of client playing time
	- update client playing time
*/
public Event_pTeam(Handle:event, const String:namep[], bool:dontBroadcast){
	
}

/*
	- store kills and deaths
	 - for statistics purposes
	 - no affect on ranking,
	   just to make everyone happy
*/
public Event_pDeath(Handle:event, const String:namep[], bool:dontBroadcast){
		
}

/*
	- keep track of clients disconnecting
	- update client playing time
*/
public Event_pDisconnect(Handle:event, const String:namep[], bool:dontBroadcast){
	
}

/*
	- reset arrays, grab client information
	 - structure data
*/
public Event_rStart(Handle:event, const String:namep[], bool:dontBroadcast){
	
}

/*
	- finalize client data, playing time, teams etc
	 - post data to trueskill implementation
*/
public Event_rEnd(Handle:event, const String:namep[], bool:dontBroadcast){
	
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