#if defined _trueskill_included_
	#endinput
#endif
#define _trueskill_included_

/*
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

/* MySQL Query definitions */
#define NEWPLAYER "insert into players (steamID,name) values (%s,'%s') on duplicate key update lastConnect = now() AND name = '%s';"
#define INTOTEMP "INSERT INTO `temp` (steamid,time_blue,time_red,result,random) VALUES(%s,%f,%f,%d,%d)"
#define STATS "INSERT INTO `player_stats` (stat_id,steamID,roles,kills,deaths) VALUES (%s.%d,%s,%d,%d,%d) ON DUPLICATE KEY UPDATE kills = kills + %d, deaths = deaths + %d"
#define RANK "select count(*) rank, 30*my.rank + 1500 from players my left join players others on others.rank >= my.rank where my.SteamID = %s"

/*
	Returns the Elo of a Player given userid

	@param userid		Userid of player
	@param callback		Callback function when it is complete
	@return 			void
*/
native getPlayerElo( userid, &callback )

/*
	Returns a handle containing the Elo of all players on server

	@param callback 	Callback functoin when query is complete
	@return 			void
*/
native getAllElo( &callback )