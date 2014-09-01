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

}
public Event_pDeath(Handle:event, const String:namep[], bool:dontBroadcast){

}
public Event_rStart(Handle:event, const String:namep[], bool:dontBroadcast){

}
public Event_rEnd(Handle:event, const String:namep[], bool:dontBroadcast){

}


/* registered action commands */
public Action:playRank(client, args){
	return Plugin_Handled;
}
public Action:topTen(client,args){
	return Plugin_Handled;
}