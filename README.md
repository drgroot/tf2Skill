#TF2 Skill
###A TrueSkill implementation for Team Fortress 2

TF2 Skill is an adaptation of Microsoft's TrueSkill ranking system into source games. This plugin has only been tested and designed to work with Team Fortress 2. 

##Requirements
* Working Source-based Game Server with SourceMod installed
* [SourceSockets Extension][3]
* [Sourcemod Updater Plugin][4]
* MySQL database
* Python >= 2.7
   * [TrueSkill][1]  module
   * [PyMySQL][2] module

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

##Website Interface
There are no official website interfaces that I have designed for this ranking system (because it is a trivial task).

However, because I understand that most people are lazy and don't want to make their own website interface, the code from playtf2.com website should be used as a reference. See this [repository](https://github.com/yusuf-a/hlstatsx) for examples.

Feel free to use it as a reference or just rip the website and use it as your own


[1]: http://trueskill.org/
[2]: https://pypi.python.org/pypi/PyMySQL
[3]: https://forums.alliedmods.net/showthread.php?t=67640
[4]: https://forums.alliedmods.net/showthread.php?t=169095
