/*

TRUESKILL RANKING SYSTEM

A TF2 adapted implementation of the ever popular
trueskill ranking system.

Author: Yusuf Ali

*/

#include <sourcemod>

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
	HookEvent("round_start", Event_rStart);
	HookEvent("round_end",Event_rEnd);
}

/* methods for game events */
public Event_pTeam(Handle:event, const String:namep[], bool:dontBroadcast){
	/*
		- keep tract of client playing time
		- update client playing time
	*/
}
public Event_pDeath(Handle:event, const String:namep[], bool:dontBroadcast){
	/*
		- store kills and deaths
		 - for statistics purposes
		 - no affect on ranking,
		   just to make everyone happy
	*/
}
public Event_rStart(Handle:event, const String:namep[], bool:dontBroadcast){
	/*
		- reset arrays, grab client information
		 - structure data
	*/
}
public Event_rEnd(Handle:event, const String:namep[], bool:dontBroadcast){
	/*
		- finalize client data, playing time, teams etc
		 - post data to trueskill implementation
	*/
}


/* registered action commands */
public Action:playRank(client, args){
	/*
		gets player rank from trueskill
		database implementation
	*/
	return Plugin_Handled;
}
public Action:topTen(client,args){
	/*
		shows top10 players from trueskill
		database implementation from get request
	*/
	return Plugin_Handled;
}