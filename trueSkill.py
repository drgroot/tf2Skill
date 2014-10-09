#!/usr/bin/python

import trueskill as skill
import pymysql
import ConfigParser
import socket
import os
from thread import *

current_dir = os.path.dirname(os.path.realpath(__file__))
config = ConfigParser.ConfigParser();

# read configuration file
config.read("%s/config.file" % current_dir)
host = config.get('database','host')
user = config.get('database','user')
passwd = config.get('database','passwd')
datb = config.get('database','db')
sock_port = config.get('database','socket_port')
min_clients = int(config.get('database','min_clients'))

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

# Function for handling connections 
# used to work for multiple server connections
def clientthread(con_client):
   while True:
      # recieve data from client
      gameNumber = con_client.recv(1024)

      if not gameNumber:
		break

      
      gameNumber = int(gameNumber)
      print "TrueSkill Calculate group: %d" % gameNumber

      # open mysql connection
      conn = pymysql.connect(host=host,port=3306,
		user=user,passwd=passwd,db=datb);
      
      # start true skill stuff
      team_blu = []; team_red = []; steam_blu = [];
      time_blu = []; time_red = []; steam_red = [];
      result = 0
      cur = conn.cursor();

      # load stuff from temp table
      cur.execute("SELECT * from temp WHERE random = %d" % gameNumber)

      for player in cur:
	 steamID = player[0]; player_blu = float(player[1]);
	 player_red = float(player[2]); result = int(player[3]);
	 
	 # load old player information
	 mew, sigma = getPlayerSkill(steamID)

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
		print "\t\tGroup %d was filtered" % gameNumber
		continue

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
      updatePlayerInfo(team_red, steam_red)
      updatePlayerInfo(team_blu, steam_blu)

      # drop data from temp table
      cur_del = conn.cursor()
      cur_del.execute("DELETE FROM temp WHERE random = %d" % gameNumber)
      cur_del.execute("update players a, (SELECT AVG( DISTINCT(  rank  )  )  agv from players) v set a.`averageRank` = v.agv;");
      conn.commit(); cur_del.close();
      
      cur.close();
      conn.close()

   con_client.close()

#### MAIN ####
##############

sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
sock.bind( ('',int(sock_port)) )
sock.listen(10)

print "TrueSkill Listening for Connections"

while 1:
   # wait to accept connection
   con,addr = sock.accept()

   # start new thread to deal with client
   start_new_thread(clientthread,(con,))

sock.close()

exit()
