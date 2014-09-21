#!/usr/bin/python

import pymysql;
import ConfigParser;
import os
import urllib, json

current_dir = os.path.dirname(os.path.realpath(__file__))
config = ConfigParser.ConfigParser();

# read configuration file
config.read("%s/config.file" % current_dir)
host = config.get('database','host')
user = config.get('database','user')
passwd = config.get('database','passwd')
datb = config.get('database','db')
apiKey = config.get('database','key')

# define url for query
url = "http://backpack.tf/api/IGetPrices/v4/?key=%s&compress=1" % apiKey

# connect to mysql database
conn = pymysql.connect(host=host,port=3306,
	user=user,passwd=passwd,db=datb);

# define some variables to be used
currencies = { u'metal':5002, u'keys':5021, u'buds':143 ,
				5002:u'metal', 5021: u'keys', 143:u'buds'}
items_list = {}		# list of acceptable variables from database
items_value = {}	# temp storage for variable for item, cur, value

# reads item_defs from the database
# these are the items we are interested in
def getItems():
	cur = conn.cursor();
	cur.execute("SELECT item_def,price_inRef FROM tradebot_items")

	for row in cur:
		items_list[row[0]] = float(row[1])
	
	cur.close()

# clean up everything
def finish():
	conn.close();

# converts the prices to ref
def convertRef():
	items_temp = items_value.copy()

	for defIndex in items_value:
		priceObj = items_value[defIndex]

		# determine if converted to metal
		if ( 'metal' in priceObj):
			items_list[defIndex] = priceObj[1]
			del items_temp[defIndex]
			continue

		# convert to lower currency otherwise
		curr = priceObj[0]; price = priceObj[1]; 
		
		# get currency defIndex
		cur_di = currencies[curr]

		# ensure non zero currency
		if(items_list[cur_di] == 0):
			continue

		# update price and currency
		price = price * items_list[cur_di]
		curr = items_value[cur_di][0]
		items_value[defIndex] = [curr, price]
	if len(items_temp) > 0:
		convertRef()

#### MAIN ####
##############

# grab backpack.tf prices
jsonURL = urllib.urlopen(url)
response = json.loads(jsonURL.read())

# ensure resulted in a succcess
if (not response['response']['success']):
	print response['response']['message']
	finish()
	exit()
items = response['response']['items']

# read all items from database
getItems()

# loop through response item
for item_name in items:
	item = items[item_name]

	# get item's def index
	defIndex = item['defindex'];
	if(len(defIndex) < 1):
		continue
	defIndex = defIndex[0]

	# see if its 
	# in list of items we want
	if not (defIndex in items_list):
		continue

	# get item object that contains price
	priceObj = item['prices']['6']['Tradable']

	currency = 'jews'
	price = 0
	
	# use craft price
	if 'Craftable' in priceObj:
		currency = priceObj['Craftable'][0]['currency']
		price = priceObj['Craftable'][0]['value']

	# use non craft price
	else:
		currency = priceObj['Non-Craftable'][0]['currency']
		price = priceObj['Non-Craftable'][0]['value']

	# store into data structure
	items_value[defIndex] = [currency,price]


# convert all values into ref now
convertRef()

# update prices in mysql database
cur = conn.cursor()
for item in items_list:
	data = {'price': items_list[item], 'id' : item}
	cur.execute("UPDATE tradebot_items SET price_inRef = %(price)f \
 WHERE item_def = %(id)d " % data)
	conn.commit()

cur.close()
finish()






