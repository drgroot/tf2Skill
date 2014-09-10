#!/usr/bin/python

import trueskill as skill;
import pymysql;

conn = pymysql.connect(host='db4free.net',port=3306,
	user='trueskill',passwd='something',db='trueskill');

# loads old player information
# return mu, sigma
def getPlayerSkill(steamID):
	cur_gP = conn.cursor(); 
	cur_gP.execute("SELECT mew,sigma FROM players WHERE steamID = '%s'" % steamID);
	
	for person in cur_gP:
		cur_gP.close();
		return person[0], person[1]

	cur_gP.execute("INSERT INTO players (steamID) VALUES ('%s') " % steamID)
	conn.commit();cur_gP.close()
	return getPlayerSkill(steamID)



#### MAIN ####
##############

cur = conn.cursor(); cur2 = conn.cursor();
cur.execute("SELECT DISTINCT(random) FROM temp");

 

for randoms in cur:
	random = 374;#randoms[0]; 
	team_blu = []; team_red = [];
	time_blu = []; time_red = [];
	players_rating = [];
	players_steamd = [];
	
	cur2.execute("SELECT * FROM temp WHERE random = %d" % random);
	
	# load temp table
	for player in cur2:
		steamID = player[0]; time_blue = player[1];
		time_red = player[2]; result = player[3];
		
		# load old player information
		mew, sigma = getPlayerSkill(steamID);
		players_rating.append(skill.Rating(mu=mew,sigma=sigma)); 
		players_steamd.append(steamID)
		
		break
	break

#cur2.close();

print players_rating
print players_steamd
	

# Steps

# 1. load temp table (by gameNumber) into variable (done)
	# delete from temp table
# 2. load old player information, create if not existant (done)
# 3. Formulate teams
# 4. Apply TrueSkill calculation
# 5. store data into database


cur.close();
conn.close();