#ChangeLog

###[V3.0 - Alpha][3]

* includes native for other plugins to get players elo
* removed the use of timers, thus less need for resources
* auto reloads itself upon update
* interacts with python script via curl to php
* python script is non daemonized, easier to run on windows
* python script creates its own log file to log errors
* multiple bug fixes (see commit log)
* all interactions with mysql are threaded, including connection

###[V2.0 - September 19, 2014][2]

* all mysql transactions are threaded
* daemonized python script
* python script more stable, prepare for daemonization
* !rank command displays ranking with some formatting

###[V1.0 - September 9, 2014][1]

* inital release of project
* plugin yet to be polished

[3]: https://github.com/yusuf-a/tf2Skill/archive/master.zip
[2]: https://github.com/yusuf-a/tf2Skill/archive/v2.0.0.zip
[1]: https://github.com/yusuf-a/tf2Skill/archive/v1.0.zip