#Final For DSC450
#Ryan Hossa
import sqlite3
conn = sqlite3.connect('dsc450_Final_web.db')
c = conn.cursor()
                       
usertable = '''CREATE TABLE user_id(
    id         int,
    name       text,
    screen_name  text,
    description  text,
    friends_count  int,
    
    PRIMARY KEY (id)
);'''

geotable = '''CREATE TABLE geo(
    id int,
    type text,
    longitude text,
    latitude text,
    
    PRIMARY KEY (id)
);'''

tweettable = '''CREATE TABLE tweet(
    id_str  int,
    created_at text,
    text  text,
    source  text, 
    in_reply_to_user_id int,
    in_reply_to_screen_name  text,
    in_reply_to_status_id int,
    retweet_count int,
    contributors  text,
    geo_id text,
    user_id  int,
    
    CONSTRAINT Tweets_PK  PRIMARY KEY (id_str),

    CONSTRAINT Tweets_FK1 FOREIGN KEY (user_id)
    REFERENCES User(id),
    
    CONSTRAINT Tweets_FK2 FOREIGN KEY (geo_id)
    REFERENCES geo(id)
);'''

    
try:
    c.execute('drop table tweet')
    c.execute('drop table user_id')
    c.execute('drop table geo')
except:
    pass

import sys
import json
import urllib
import time

c.execute(usertable)
c.execute(geotable)
c.execute(tweettable)

startweb = time.time()
webFD=urllib.request.urlopen ("http://rasinsrv07.cstcis.cti.depaul.edu/CSC455/OneDayOfTweets.txt")
d = open('OneDayOfTweets1.txt','w')

user_list, tweet_list, geo_list = [], [], [] 
geoid = 0

for i in range(50000):
    alltweet=webFD.readline()
    d.write(alltweet.decode('utf8'))
    try:
        tweet = alltweet
        tdict = json.loads(tweet)
    except:
        pass
    else:
        newRowUser = [] # hold individual values of to-be-inserted row for user table
        userKeys = ['id', 'name', 'screen_name', 'description', 'friends_count']
        userDict = tdict['user']
        for key in userKeys: # For each dictionary key we want
            if userDict[key] == 'null' or userDict[key] == '':
                newRowUser.append(None)   # proper NULL
            else:
                newRowUser.append(userDict[key]) # use value as-is
        user_list.append((newRowUser))
            
    
        newRowTweet = [] # hold individual values of to-be-inserted row
        tweetKeys = ['id_str','created_at','text','source','in_reply_to_user_id', 'in_reply_to_screen_name', 'in_reply_to_status_id', 'retweet_count', 'contributors']
        geoid += 1
        for key in tweetKeys:
            if tdict[key] == 'null' or tdict[key] == '':
                newRowTweet.append(None)   # proper NULL
            else:
                newRowTweet.append(tdict[key]) # use value as-is
        userDict = tdict['user'] # This the the dictionary for user information
        if tdict['geo']:
            newRowTweet.append(geoid) # Take the point type
            geo_list.append((geoid,tdict['geo']['type'],tdict['geo']['coordinates'][0],tdict['geo']['coordinates'][1]))
        else:
            newRowTweet.append(None)
        newRowTweet.append(userDict['id']) # User id/ foreign key
        tweet_list.append((newRowTweet))
        
d.close()

stopweb = time.time()
print("diff "+str(stopweb-startweb))
startinsert = time.time()
c.executemany('INSERT OR IGNORE INTO tweet VALUES(?,?,?,?,?,?,?,?,?,?,?)',tweet_list) 
c.executemany('INSERT OR IGNORE INTO user_id VALUES(?,?,?,?,?)',user_list)
c.executemany('INSERT OR IGNORE INTO geo VALUES(?,?,?,?)',geo_list)
stopinsert = time.time()


#####Part1B####

start = time.time()
print(c.execute('select count(*) from user_id').fetchall())
print(c.execute('select count(*) from tweet').fetchall())
print(c.execute('select count(*) from geo').fetchall())
print(c.execute('select count(*) from tweet where geo_id != "None"').fetchall())
print(c.execute('select count(*) from tweet where geo_id is NULL').fetchall())
stop = time.time()
print("diff "+str(stop-start))


####
conbatch = sqlite3.connect('dsc450_Final_batching.db')
cbatching= confile.cursor()
                       
usertable = '''CREATE TABLE user_id(
    id         int,
    name       text,
    screen_name  text,
    description  text,
    friends_count  int,
    
    PRIMARY KEY (id)
);'''

geotable = '''CREATE TABLE geo(
    id int,
    type text,
    longitude text,
    latitude text,
    
    PRIMARY KEY (id)
);'''

tweettable = '''CREATE TABLE tweet(
    id_str  int,
    created_at text,
    text  text,
    source  text, 
    in_reply_to_user_id int,
    in_reply_to_screen_name  text,
    in_reply_to_status_id int,
    retweet_count int,
    contributors  text,
    geo_id text,
    user_id  int,
    
    CONSTRAINT Tweets_PK  PRIMARY KEY (id_str),

    CONSTRAINT Tweets_FK1 FOREIGN KEY (user_id)
    REFERENCES User(id),
    
    CONSTRAINT Tweets_FK2 FOREIGN KEY (geo_id)
    REFERENCES geo(id)
);'''

try:
    cbatching.execute('drop table tweet')
    cbatching.execute('drop table user_id')
    cbatching.execute('drop table geo')
except:
    pass
import sys
import json
import urllib
import time

cbatching.execute(usertable)
cbatching.execute(geotable)
cbatching.execute(tweettable)

startweb = time.time()
webFD=urllib.request.urlopen ("http://rasinsrv07.cstcis.cti.depaul.edu/CSC455/OneDayOfTweets.txt")
user_list_b, tweet_list_b, geo_list_b = [], [], [] 
geoid_b = 0
loadCounter = 0

for i in range(50000):
    alltweet=webFD.readline()
    if i % 1000 == 0: # Print a message every 100th tweet read
        print ("Processed " + str(i) + " tweets")
        
    try:
        tweet = alltweet
        tdict = json.loads(tweet)
        loadCounter = loadCounter + 1
    except:
        pass
    else:
        newRowUser = [] # hold individual values of to-be-inserted row for user table
        userKeys = ['id', 'name', 'screen_name', 'description', 'friends_count']
        userDict = tdict['user']
        for key in userKeys: # For each dictionary key we want
            if userDict[key] == 'null' or userDict[key] == '':
                newRowUser.append(None)   # proper NULL
            else:
                newRowUser.append(userDict[key]) # use value as-is
        if loadCounter < 1000: # Batching 50 at a time
            user_list.append((newRowUser))
        else:
            cbatching.executemany('INSERT OR IGNORE INTO user_id VALUES(?,?,?,?,?)',user_list)
            user_list_b = [] # Reset the list of batched tweets
    
            
        newRowTweet = [] # hold individual values of to-be-inserted row
        tweetKeys = ['id_str','created_at','text','source','in_reply_to_user_id', 'in_reply_to_screen_name', 'in_reply_to_status_id', 'retweet_count', 'contributors']
        geoid_b += 1
        for key in tweetKeys:
            if tdict[key] == 'null' or tdict[key] == '':
                newRowTweet.append(None)   # proper NULL
            else:
                newRowTweet.append(tdict[key]) # use value as-is
        userDict = tdict['user'] # This the the dictionary for user information
        if tdict['geo']:
            newRowTweet.append(geoid) # Take the point type
            if loadCounter < 1000: # Batching 50 at a time
                geo_list_b.append((geoid,tdict['geo']['type'],tdict['geo']['coordinates'][0],tdict['geo']['coordinates'][1]))
        else:
            newRowTweet.append(None)
        newRowTweet.append(userDict['id']) # User id/ foreign key
        
        if loadCounter < 1000: # Batching 50 at a time
            tweet_list_b.append((newRowTweet))
        else:
            cbatching.executemany('INSERT OR IGNORE INTO tweet VALUES(?,?,?,?,?,?,?,?,?,?,?)',tweet_list_b)
            cbatching.executemany('INSERT OR IGNORE INTO geo VALUES(?,?,?,?)',geo_list_b)
            loadCounter = 0
            tweet_list_b = []
            geo_list_b = []# Reset the list of batched users
d.close()

stopweb = time.time()
print("diff "+str(stopweb-startweb))
startinsert = time.time()
cbatching.executemany('INSERT OR IGNORE INTO tweet VALUES(?,?,?,?,?,?,?,?,?,?,?)',tweet_list_b) 
cbatching.executemany('INSERT OR IGNORE INTO user_id VALUES(?,?,?,?,?)',user_list_b)
cbatching.executemany('INSERT OR IGNORE INTO geo VALUES(?,?,?,?)',geo_list_b)
stopinsert = time.time()
print("diff "+str(stopinsert-startinsert))

start = time.time()
print(cbatching.execute('select count(*) from user_id').fetchall())
print(cbatching.execute('select count(*) from tweet').fetchall())
print(cbatching.execute('select count(*) from geo').fetchall())
print(cbatching.execute('select count(*) from tweet where geo_id != "None"').fetchall())
print(cbatching.execute('select count(*) from tweet where geo_id is NULL').fetchall())
stop = time.time()
print("diff "+str(stop-start))




#################PARTII###################3
start = time.time()
for avgtwe in cfile.execute('''select user_id.id, geo.longitude, geo.latitude from tweet, geo, user_id
where geo.longitude = (select avg(longitude) from geo)and geo.latitude = (select avg(latitude) from geo) and tweet.geo_id = geo.id''').fetchall():
    print(avgtwe)
stop = time.time()
print("diff "+str(stop-start))

start1 = time.time()
for i in range(10):
    for avgtwe in cfile.execute('''select user_id.id, geo.longitude, geo.latitude from tweet, geo, user_id
where geo.longitude = (select avg(longitude) from geo)and geo.latitude = (select avg(latitude) from geo) and tweet.geo_id = geo.id''').fetchall():
        print(avgtwe)
stop1 = time.time()
print("diff "+str(stop1-start1))

start2 = time.time()
for i in range(100):
    for avgtwe in cfile.execute('''select user_id.id, geo.longitude, geo.latitude from tweet, geo, user_id
where geo.longitude = (select avg(longitude) from geo)and geo.latitude = (select avg(latitude) from geo) and tweet.geo_id = geo.id''').fetchall():
        print(avgtwe)
stop2 = time.time()
print("diff "+str(stop2-start2))

print("times "+str((stop2-start2)/(stop1-start1)))


#########Part C&D#######
start = time.time()
openfile = open('OneDayOfTweets1.txt','r')
tweet_list = []
replylst=[]

for i in range(50000):
    alltweet=openfile.readline()
    try:
        tweet = alltweet
        tdict = json.loads(tweet)
    except:
        pass
    else:
        newRowTweet = [] # hold individual values of to-be-inserted row
        tweetKeys = ['id_str','created_at','text','source','in_reply_to_user_id', 'in_reply_to_screen_name', 'in_reply_to_status_id', 'retweet_count', 'contributors']
        geoid += 1
        for key in tweetKeys:
            if tdict[key] == 'null' or tdict[key] == '':
                newRowTweet.append(None)   # proper NULL
            else:
                newRowTweet.append(tdict[key]) # use value as-is
        userDict = tdict['user'] # This the the dictionary for user information
        if tdict['geo']:
            newRowTweet.append(geoid) # Take the point type
        else:
            newRowTweet.append(None)
        newRowTweet.append(userDict['id']) # User id/ foreign key
        tweet_list.append((newRowTweet))

for x in range(len(tweet_list)):
    if tweet_list[x][4] != None:
        if tweet_list[x][4] not in replylst:
            replylst.append(tweet_list[x][4])
withoutnone = len(replylst)
total= withoutnone +1  
print(total)

stop = time.time()
print("diff "+str(stop-start))
