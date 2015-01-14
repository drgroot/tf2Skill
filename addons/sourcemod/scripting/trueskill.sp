/*

 TRUESKILL RANKING SYSTEM

 A TF2 adapted implementation of the ever popular
 trueskill ranking system.

 Author: Yusuf Ali

 YusufAli's TrueSkill Ranking System
 Copyright (C) 2014 YusufAli

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <trueskill>
#include <sourcemod>
#include <dbi>
#include <tf2_stocks>
#include <updater>
#include <steamtools>
#include <morecolors>

#define UPDATE_URL 	"http://dev.yusufali.ca/plugins/tf2Skill/master/"
#define PLUGIN_NAME	"TrueSkill Ranking System"
#define AUTHOR 		"Yusuf Ali"
#define VERSION 	"2.0"
#define URL 		"https://github.com/yusuf-a/tf2Skill"
#define STEAMID		32
#define QUERY_SIZE   512

/*
	VARIABLE DOCUMENTATION

	db 				Database handle for MySQL connection

	players_stats 	Player kill and death storage variable
		structure: 	<playerID>	[array 0..19]
		the array has 20 elements (2 for every type of class)
		the first 10 are to store kills (1 index for each class)
		the last 10 are to store deaths (1 index for each class)

	players_times 	Player time storage variable
		structure:	<playerID>	[array 0..3]
		the array has 4 elements to store how long a player has been on a team
		0:	time on team red (in seconds)
		1:	time on team blu (in seconds)
		2:	int of the current team the player is on
		3:	time (using GetTime() ) that player joined current team
		the logic is that to maintain the time, simply subtract GetTime() 
		with [3] and append it to the team specified in [2]

	players 		Player Id Storage variable
		structure: 	<playerID>	<steamID>
		this is to find the player id (FindStringInArray)
		given the players steamID

	g_playerElo		foward to allow other plugins to get Elo of player
	roundStart 		using getTime(), the start of the round
	track_game		1 to track elo statistics, 0 to ignore


	What this plugin does:

	This plugin does the low level tracking to send data to the trueskill.py
	python script to calculate player ranks under the TrueSkill system.

	In order to do so, trueskill.py needs 3 pieces of information from every 
	player who took part in the round:

	1. SteamID (uniquely desribe player)
	2. percent time on each time (eg: 40% on red, 60% on blue)
	3. which team won the round

	Additionally, this plugin tracks the kill and death statistics for each 
	player (not required, but a nice feature)

	How this plugin operates:

	1. At the start of the round
		- reset all variables
		- beginning of round time is stored into roundStart
		- players are assigned a unique number (playerID) to their steamid
		- players information such as team and kill stats are initialized

	2. Player teamchanges/reconnects/disconnencts
		- the amount of time spent on the previous team is updated
		- the players current team is updated
		- the time of the event is updated
		- all of this is stored in players_times

	3. Player kills/dies
		- player kill/death stats are updated into players_stats

	4. round ends
		- round is assigned a random number (called 'random')
		- all player times on teams are updated
		- throws information (kill/death stats, aswell as required trueskill data) into mysql database identified by the round number
		- when insertation has been complete, a curl request is sent to the php file with the random number, initiating the python script to calculate player ranks

*/
Handle db = null	
Handle players_stats
Handle players_times
Handle players
Handle g_playerElo = null
int roundStart
int track_game = 0
int track_elo = 1

/* define convars */
Handle sm_minClients = null
Handle sm_url = null
Handle sm_minGlobal = null


/* delcare plublic variable information */
public Plugin myinfo = {name = PLUGIN_NAME,author = AUTHOR,description = "",version = VERSION,url = URL};

public OnPluginStart(){
	/* connect to database */
	SQL_TConnect( gotDB, "default" )

	/* add to updater */
	if(	LibraryExists( "updater" )	){
		Updater_AddPlugin(UPDATE_URL)
	}

	/* define convars */
	CreateConVar("sm_trueskill_version",VERSION,"public CVar shows the plugin version",FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED)
	sm_minClients = CreateConVar("sm_trueskill_minClients","16","Minimum clients to track ranking", FCVAR_NOTIFY)
	sm_url = CreateConVar("sm_trueskill_url","http://server.com/trueskill.php","url to trueskill php file", FCVAR_PROTECTED)
	sm_minGlobal = CreateConVar("sm_trueskill_global","50","Minimum rank for global display, 0 for off", FCVAR_NOTIFY)

	/* bind methods to game events */
	HookEvent( "player_team", Event_pTeam )
	HookEvent( "teamplay_round_start", Event_rStart )
	HookEvent( "teamplay_round_win", Event_rEnd )
	HookEvent( "player_death", Event_pDeath )
	RegConsoleCmd( "sm_rank", playRank )
	g_playerElo = CreateForward( ET_Event, Param_Cell, Param_Float, Param_Cell )

	/* init arrays */
	players_stats = CreateArray( 20, 0 )
	players_times = CreateArray( 4, 0 )
	players = CreateArray( STEAMID, 0 )
}

/* stock functions used throughout the plugin */
#include "trueskill_stock.sp"

/* code for native bindings */
#include "trueskill_native.sp"

/* methods that are hooked to game events */
#include "trueskill_death.sp"
#include "trueskill_change_team.sp"
#include "trueskill_round_start.sp"
#include "trueskill_round_end.sp"

/* deals with when a player says !rank */
#include "trueskill_say_rank.sp"

/*
	
	HANDLES UPDATE TIME STUFF

*/
updateTimes( int player, int newTeam, int oldTeam, int curTime ){
	/* ensure tracking game */
	if(	!track_game )
		return

	if( curTime == 0 )
		curTime = GetTime()

	/* get the required data array information */
	int player_time[4]
	GetArrayArray( players_times, player, player_time, sizeof( player_time ) )
	int duration = curTime - player_time[3]

	if( oldTeam == 0 )
		oldTeam = player_time[2]

	/* determine which team counter to increment */
	switch ( oldTeam ){
		case ( _:TFTeam_Red ): {
			player_time[0] = player_time[0] + duration
		}

		case ( _:TFTeam_Blue ): {
			player_time[1] = player_time[1] + duration
		}
	}

	player_time[2] = newTeam
	player_time[3] = GetTime()

	/* store array back into adt */
	SetArrayArray(	players_times, player, player_time, sizeof( player_time )	)
}
