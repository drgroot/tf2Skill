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
	
}

/* required events to listen 
	- player team
	- player death
	- round start
	- round end
*/



/* registered action commands */
public Action:playRank(client, args){
	return Plugin_Handled;
}
public Action:topTen(client,args){
	return Plugin_Handled;
}