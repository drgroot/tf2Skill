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

functag OnGetEloFunc Action:public( userid, float:elo, champ )

/*
	Returns the Elo of a Player given userid

	@param userid		Userid of player
	@param callback		Callback function when it is complete
		
	@return 			void
*/
native trueskill_getElo( userid, OnGetEloFunc:callback )

stock bool IsNotClient( client ) {
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client) )
		return true;
	return false;
}