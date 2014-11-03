#TF2 Skill
###A TrueSkill implementation for Team Fortress 2

TF2 Skill is an adaptation of [Microsoft's TrueSkill][5] ranking system into source games. This plugin has only been tested and designed to work with Team Fortress 2.

A example population distribution as a result of using TrueSkill can be viewed [here](http://www.playtf2.com/plot/40)

##Dependencies/Requirements
* [SteamTools Extension][3]
* [Sourcemod Updater Plugin][4]
* MySQL database
* Python >= 2.7
   * [TrueSkill][1]  module
   * [PyMySQL][2] module

##Features
* **Non-point based** - Functions as an ELO derived match making system.
* **Threaded** - Support for simultaneous servers all using the same listener.
* **AutoUpdate** - The plugin will automatically update itself when updates are available. You will always have the most up-to-date version of the plugin.

##CVar/Command List

```javascript
sm_trueskill_version // public CVar shows the plugin version
sm_trueskill_minClients 16    //minimum number of clients required to track ranking
sm_trueskill_url "http://server.com/trueskill.php" //url to trueskill php file
sm_trueskill_global "50" //minimum rank to display globally to the server, 0 for off
```

##Installation
Download the .smx file and save to the plugins directory into your sourcemod plugins folder. Edit the **default** entry in `addons/sourcemod/configs/databases.cfg`:

```javascript
   "default"
   {
      "driver" "mysql"
      "host"   "<mysql host>"
      "database"   "<mysql database>"
      "user"   "<mysql username>"
      "pass"    "<mysql password>"
   }
```

**Daemon**: Similarly, on the server running the python daemon, edit `config.file.sample` and then rename it to `config.file`

##Database Setup

import `trueSkill.sql` into your MySQL database

##Scripts Setup
Place the files in the scripts folder as set in the `sm_trueskill_url` CVar. 
Edit `config.file.sample` and then rename it to `config.file`
To test that it works, browse to the url specified in the `sm_trueskill_url` CVar. If the page doesn't show and error, then it has been successfully installed.

##Website Interface
Example Website Interface: [PlayTF2][6]

There are no official website interfaces that I have designed for this ranking system. Later in the future I plan to design an official website interface for this plugin.

However, because I understand that most people want their own website interface, the code from [PlayTF2][6] website should be used as a reference. See this [repository](https://github.com/yusuf-a/hlstatsx) for examples.

Feel free to use it as a reference or just rip the website and use it as your own

##Additional Information

* [ChangeLog][7]
* [Previous Releases][8]
* SourceCode: [GitHub][9] 
* [Development Progress][10]

##Issues / Bugs

All issues/bugs please [report here](https://github.com/yusuf-a/tf2Skill/issues)


[1]: http://trueskill.org/
[2]: https://pypi.python.org/pypi/PyMySQL
[3]: https://forums.alliedmods.net/showthread.php?t=129763
[4]: https://forums.alliedmods.net/showthread.php?t=169095
[5]: http://research.microsoft.com/en-us/projects/trueskill/
[6]: http://playtf2.com/stats/
[7]: https://github.com/yusuf-a/tf2Skill/commits/master
[8]: https://github.com/yusuf-a/tf2Skill/releases
[9]: https://github.com/yusuf-a/tf2Skill
[10]: https://github.com/yusuf-a/tf2Skill/network
