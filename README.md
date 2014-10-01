#TF2 Skill
###A TrueSkill implementation for Team Fortress 2
---

TF2 Skill is an adaptation of Microsoft's TrueSkill ranking system into source games. This ideally should work with any source game, but has been optimized and designed for Team Fortress 2. 

##Requirements
* Working Source-based Game Server with SourceMod installed
* SourceSockets Extension
* Sourcemod Updater Plugin
* MySQL database
* Python >= 2.7
   * TrueSkill module
   * PyMySQL or MySQLDB module

##Features
* **Non-point based** - Functions as an ELO derived match making system.
* **Lightweight** - Little overhead and very compact and optimal coding.
* **Threaded** - Support for simultaneous servers all using the same listener.
* **Logging** - The plugin maintains full logs of all errors, warnings and information.
* **AutoUpdate** - The plugin will automatically update itself when updates are.available, thus you will always have the most up-to-date version of the plugin.

##Installation
Download the .smx file in the plugins directory into your sourcemod plugins folder. Edit the entry in `addons/sourcemod/configs/databases.cfg`:

```javascript
   "default"
   {
      "driver" "mysql"
      "host"	"<mysql host>"
      "database"   "<mysql database>"
      "user"   "<mysql username>"
      "pass"	 "<mysql password>"
   }
```

Change conVars to the desired values in `cfg/server.cfg`

```
sm_trueskill_minClients   16 //Minimum clients to track ranking
sm_trueskill_server "somehost"	 //Server ip with python script
sm_trueskill_port   5000  //Port to interact with python script
```

Where `"somehost"` will be the server running the python daemon.
Similarly, on the server to run the python daemon, edit `config.file.sample` and then rename it to `config.file`

##Running The Daemon
To begin applying TrueSkill calculations, simply run the python script in a screen session or using an init script. Below is a sample to start the daemon

```bash
screen
python trueSkill.py
```



