#!/usr/bin/python

import trueskill as skill;
import pymysql;
import ConfigParser; 
config = ConfigParser.ConfigParser();

# read configuration file
config.read("config.file")
host = config.get('database','host')
user = config.get('database','user')
passwd = config.get('database','passwd')
datb = config.get('database','db')

# connect to mysql database
conn = pymysql.connect(host=host,port=3306,
	user=user,passwd=passwd,db=datb);
env = skill.TrueSkill();

# loads old player information
# return mu, sigma
def getPlayerSkill(steamID):
	cur_gP = conn.cursor(); 
	cur_gP.execute("SELECT mew,sigma FROM players WHERE steamID = '%s'" % steamID);
	
	for person in cur_gP:
		cur_gP.close();
		return float(person[0]), float(person[1])

	cur_gP.execute("INSERT INTO players (steamID) VALUES ('%s') " % steamID)
	conn.commit();cur_gP.close()
	return getPlayerSkill(steamID)

def updatePlayerInfo(team_ls,steam_ls):
	cur_uP = conn.cursor();

	i = 0;
	for mem in team_ls:
		data = {"steam" : steam_ls[i], "mu" : mem.mu,
				"sigma" : mem.sigma, "rank": env.expose(mem)};
		cur_uP.execute("UPDATE players SET mew = %(mu)f, sigma=%(sigma)f, \
rank=%(rank)f WHERE steamID='%(steam)s'" % data)
		i = i+1
	conn.commit()
	cur_uP.close()


#### MAIN ####
##############

print "-----Running TrueSkill Calculation-----"

cur = conn.cursor(); cur2 = conn.cursor();
cur.execute("SELECT DISTINCT(random) FROM temp");

for randoms in cur:
	random = randoms[0]; 
	team_blu = []; team_red = []; steam_blu = [];
	time_blu = []; time_red = []; steam_red = [];
	
	print "\tCalculating group: %d" % random

	cur2.execute("SELECT * FROM temp WHERE random = %d" % random);
	
	# load temp table
	for player in cur2:
		steamID = player[0]; player_blue = float(player[1]);
		player_red = float(player[2]); result = int(player[3]);
		
		# load old player information
		mew, sigma = getPlayerSkill(steamID);
		 
		# append player to correct time
		if ( int(player_red*100) == 0 and int(player_blue*100)==0 ):
			continue
		elif ( player_red < player_blue ):
			team_blu.append(env.create_rating(mu=mew,sigma=sigma))
			time_blu.append(player_blue)
			steam_blu.append(steamID)
		elif ( player_red > player_blue ):
			team_red.append(env.create_rating(mu=mew,sigma=sigma))
			time_red.append(player_red)
			steam_red.append(steamID)
	
	# ensure people are playing
	if (len(team_red) + len(team_blu)) < 16:
		print "\t\t Group was filtered"
		continue

	# apply TrueSkill calculation
	if result == 3:
		[team_blu, team_red] = env.rate([tuple(team_blu), tuple(team_red)],
	 		weights=[tuple(time_blu), tuple(time_red)])
	else:
		[team_red, team_blu] = env.rate([tuple(team_red), tuple(team_blu)],
	 		weights=[tuple(time_red), tuple(time_blu)])

	# update information in the database
	updatePlayerInfo(team_red,steam_red)
	updatePlayerInfo(team_blu,steam_blu)

	# drop data from temp table
	cur_del = conn.cursor();
	cur_del.execute("DELETE FROM temp WHERE random = %d" % random);
	conn.commit(); cur_del.close();

cur2.close();
cur.close();
conn.close();

print "-----Ending TrueSkill Calculation-----"