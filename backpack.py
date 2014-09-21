#!/usr/bin/python

import pymysql;
import ConfigParser;

config = ConfigParser.ConfigParser();

# read configuration file
config.read("%s/config.file" % current_dir)
host = config.get('database','host')
user = config.get('database','user')
passwd = config.get('database','passwd')
datb = config.get('database','db')

# connect to mysql database
conn = pymysql.connect(host=host,port=3306,
	user=user,passwd=passwd,db=datb);