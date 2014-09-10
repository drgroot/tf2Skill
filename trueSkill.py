#!/usr/bin/python

import trueskill as skill;
import pymysql;

conn = pymysql.connect(host='db4free.net',port=3306,
	user='trueskill',passwd='something',db='trueskill');
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



#### MAIN ####
##############

cur = conn.cursor(); cur2 = conn.cursor();
cur.execute("SELECT DISTINCT(random) FROM temp");

for randoms in cur:
	random = 374;#randoms[0]; 
	team_blu = []; team_red = []; steam_blu = [];
	time_blu = []; time_red = []; steam_red = [];
	
	cur2.execute("SELECT * FROM temp WHERE random = %d" % random);
	j = 0;
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
			team_blu.append(env.Rating(mu=mew,sigma=sigma))
			time_blu.append(player_blue)
			steam_blu.append(steamID)
		elif ( player_red > player_blue ):
			team_red.append(env.Rating(mu=mew,sigma=sigma))
			time_red.append(player_red)
			steam_red.append(steamID)
		j = j+1;
		if j >= 3:
			break
	# apply TrueSkill calculation
	if result == 3:
		[team_blu, team_red] = env.rate([tuple(team_blu), tuple(team_red)],
	 		weights=[tuple(time_blu), tuple(time_red)])
	else:
		[team_red, team_blu] = env.rate([tuple(team_red), tuple(team_blu)],
	 		weights=[tuple(time_red), tuple(time_blu)])
	print team_red
	print steam_red

	# update information in the database
	i = 0;
	for mem in team_red:
		steamID = steam_red[i]
		skill = env.expose(mem)

		


		i = i+1

	break

#print ""
#print steam_blu
#cur2.close();

	

# Steps

# 1. load temp table (by gameNumber) into variable (done)
	# delete from temp table
# 2. load old player information, create if not existant (done)
# 3. Formulate teams (done)
# 4. Apply TrueSkill calculation (done)
# 5. store data into database


cur.close();
conn.close();