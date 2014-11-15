#!/usr/bin/python

#YusufAli's TrueSkill Ranking System
#Copyright (C) 2014 YusufAli

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.


import trueskill as skill
import pymysql
import ConfigParser
import os
import logging
import argparse

# determine where the config file is stored 
# on the local hard disk
current_dir = os.path.dirname(os.path.realpath(__file__))
config = ConfigParser.ConfigParser();

# open a logging file 
logging.basicConfig(filename='trueskill.log',level=logging.DEBUG)

# read configuration file
try:
	config.read("%s/config.file" % current_dir)
	host = config.get('database','host')
	user = config.get('database','user')
	passwd = config.get('database','passwd')
	datb = config.get('database','db')
	min_clients = int(config.get('database','min_clients'))
except:
	logging.critical('Could not read configuration file')

env = skill.TrueSkill();

# argument parsing
parser = argparse.ArgumentParser()
parser.add_argument('--group',type=int,help="Group to Calculate")
args = parser.parse_args()

# loads old player information
# return mu, sigma
def getPlayerSkill(steamID,conn):
	try:
		cur_gP = conn.cursor(); 
		cur_gP.execute("SELECT mew,sigma FROM players WHERE steamID = '%s'" % steamID);
	
		for person in cur_gP:
			cur_gP.close();
			return float(person[0]), float(person[1])

		cur_gP.execute("INSERT INTO players (steamID) VALUES ('%s') " % steamID)
		conn.commit();cur_gP.close()
	except:
		logging.error('Could not retrieve %s skill from database ' % steamID)
	return getPlayerSkill(steamID,conn)

def updatePlayerInfo(team_ls,steam_ls,conn):
	cur_uP = conn.cursor();

	i = 0;
	try:
		for mem in team_ls:
			data = {"steam" : steam_ls[i], "mu" : mem.mu,
				"sigma" : mem.sigma, "rank": env.expose(mem)};
			cur_uP.execute("UPDATE players SET mew = %(mu)f, sigma=%(sigma)f, rank=%(rank)f WHERE steamID='%(steam)s'" % data)
			i = i+1
	except: 
		logging.error('Could not update calculated player info')
	conn.commit()
	cur_uP.close()

###
# MAIN METHOD
###
if args.group is None:
	exit()

gameNumber = int(args.group)
logging.info("TrueSkill Calculate group: %d" % gameNumber)

# open mysql connection
conn = pymysql.connect(host=host,port=3306, user=user,passwd=passwd,db=datb);
cur = conn.cursor();
		
# start true skill stuff
team_blu = []; team_red = []; steam_blu = [];
time_blu = []; time_red = []; steam_red = [];
result = 0
		
# load stuff from temp table
try:
	cur.execute("SELECT * from temp WHERE random = %d" % gameNumber)
except:
	logging.error('could not read data from database')

for player in cur:
	steamID = player[0]; player_blu = float(player[1]);
	player_red = float(player[2]); result = int(player[3]);
	 
	# load old player information
	mew, sigma = getPlayerSkill(steamID, conn)

	# append player to correct team
	# based on time
	if(player_red < player_blu):
		team_blu.append(env.create_rating(mu=mew,sigma=sigma))
		time_blu.append(player_blu)
		steam_blu.append(steamID)
	elif(player_red > player_blu):
		team_red.append(env.create_rating(mu=mew,sigma=sigma))
		time_red.append(player_red)
		steam_red.append(steamID)
		
# ensure minimum people are playing
if( len(team_red) + len(team_blu) ) < min_clients:
	logging.info('\t\tGroup %d was filtered' % gameNumber)
	
	try:
		cur_del = conn.cursor()
		cur_del.execute("DELETE FROM temp WHERE random = %d" % gameNumber)
		conn.commit(); cur_del.close();
	except:
		logging.error('could not prune group %d from database' % gameNumber)
	conn.close()
	exit()

# apply trueskill calculation
if result == 3:
	[team_blu, team_red] = env.rate([tuple(team_blu), tuple(team_red)],
		weights=[tuple(time_blu), tuple(time_red) ] )
elif result == 2:
	[team_red, team_blu] = env.rate([tuple(team_red), tuple(team_blu)],
		weights=[tuple(time_red),tuple(time_blu)])
else:
	[team_blu, team_red] = env.rate([tuple(team_blu), tuple(team_red)],
		weights=[tuple(time_blu), tuple(time_red)], ranks=[0,0])

# update information in the database
updatePlayerInfo(team_red, steam_red, conn)
updatePlayerInfo(team_blu, steam_blu, conn)

# drop data from temp table
try:
	cur_del = conn.cursor()
	cur_del.execute("DELETE FROM temp WHERE random = %d" % gameNumber)
	conn.commit(); cur_del.close();
except:
	logging.error('could not prune group %d from database' % gameNumber)
		
cur.close();
conn.close()

exit()
